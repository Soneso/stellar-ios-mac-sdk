//
//  SorobanClient.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Represents a Soroban contract and helps you to interact with the contract, such as by invoking a contract method.
public class SorobanClient {

    private static let constructorFunc = "__constructor"
    
    /// spec entries of the contract represented by this client.
    public let specEntries:[SCSpecEntryXDR]
    
    /// client options for interacting with soroban.
    private let clientOptions:ClientOptions
    
    /// method names of the represented contract.
    public private(set) var methodNames:[String] = []
    
    /// Internal constructor. Use `SorobanClient.forClientOptions` or `SorobanClient.deploy` to construct a SorobanClient.
    internal init(specEntries: [SCSpecEntryXDR] = [], clientOptions: ClientOptions) {
        self.specEntries = specEntries
        self.clientOptions = clientOptions
        
        for entry in specEntries {
            switch entry {
            case .functionV0(let function):
                if function.name != SorobanClient.constructorFunc {
                    self.methodNames.append(function.name)
                }
            default:
                break
            }
        }
    }
    
    /// Loads the contract info for the contractId provided by the options, and the constructs a SorobanClient by using the loaded contract info.
    ///
    /// - Parameters:
    ///   - options: Client options.
    ///
    public static func forClientOptions(options:ClientOptions) async throws -> SorobanClient {
        let server = SorobanServer(endpoint: options.rpcUrl)
        let infoEnum = await server.getContractInfoForContractId(contractId:options.contractId)
        switch infoEnum {
        case .success(let info):
            return SorobanClient(specEntries: info.specEntries, clientOptions: options)
        case .parsingFailure(let error):
            throw error
        case .rpcFailure(let error):
            throw error
        }
    }
    
    /// After deploying the contract it creates and returns a new SorobanClient for the deployed contract.
    /// The contract must be installed before calling this method. You can use `SorobanClient.install`
    /// to install the contract.
    ///
    /// - Parameters:
    ///   - deployRequest: Deploy request data.
    ///
    public static func deploy(deployRequest:DeployRequest) async throws -> SorobanClient {
        let sourceAddress = try SCAddressXDR(accountId: deployRequest.sourceAccountKeyPair.accountId)
        let createContractOp = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(wasmId: deployRequest.wasmHash, address: sourceAddress, constructorArguments: deployRequest.constructorArgs ?? [], salt: deployRequest.salt)
        let clientOptions = ClientOptions(sourceAccountKeyPair: deployRequest.sourceAccountKeyPair,
                                          contractId: "ignored",
                                          network: deployRequest.network,
                                          rpcUrl: deployRequest.rpcUrl,
                                          enableServerLogging: deployRequest.enableServerLogging)
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: deployRequest.methodOptions,
                                                  method: self.constructorFunc,
                                                  enableServerLogging: deployRequest.enableServerLogging)
        let tx = try await AssembledTransaction.buildWithOp(operation: createContractOp, options: options)
        let response = try await tx.signAndSend()
        guard let contractId = response.createdContractId else {
            throw SorobanClientError.deployFailed(message: "Could not get contract id for deployed contract.")
        }
        clientOptions.contractId = try contractId.encodeContractIdHex()
        return try await SorobanClient.forClientOptions(options: clientOptions)
        
    }
    
    /// Installs (uploads) the given contract code to soroban.
    /// If successfull, it returns the wasm hash of the installed contract as a hex string.
    ///
    /// - Parameters:
    ///   - installRequest: Intalls request parameters.
    ///   - force: force singing and sending the transaction even if it is a read call. Default false.
    ///
    public static func install(installRequest:InstallRequest, force:Bool = false) async throws -> String {
        let uploadContractOp = try InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: installRequest.wasmBytes)
        let clientOptions = ClientOptions(sourceAccountKeyPair: installRequest.sourceAccountKeyPair,
                                          contractId: "ignored",
                                          network: installRequest.network,
                                          rpcUrl: installRequest.rpcUrl,
                                          enableServerLogging: installRequest.enableServerLogging)
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(),
                                                  method: "ignored",
                                                  enableServerLogging: installRequest.enableServerLogging)
        let tx = try await AssembledTransaction.buildWithOp(operation: uploadContractOp, options: options)
        
        let isReadCall = try tx.isReadCall()
        if !force && isReadCall {
            let simulationData = try tx.getSimulationData()
            let returnedValue = simulationData.returnedValue
            if returnedValue.bytes == nil {
                throw SorobanClientError.installFailed(message: "Could not extract wasm hash from simulation result.")
            } else {
                return returnedValue.bytes!.hexEncodedString()
            }
        }
        let response = try await tx.signAndSend(force: force)
        if let wasmHash = response.wasmId {
            return wasmHash
        }
        throw SorobanClientError.installFailed(message: "Could not get wasm hash for installed contract.")
        
    }
    
    /// contract id of the contract represented by this client.
    public var contractId:String {
        return clientOptions.contractId
    }

    /// Invokes a contract method. It can be used for read only calls and for read/write calls. Returns the result of the invocation.
    /// If it is read only call it will return the result from the simulation.
    /// If you want to force signing and submission even if it is a read only call set `force`to true.
    ///
    /// - Parameters:
    ///   - name: the name of the method to invoke. Will throw an exception if the method does not exist.
    ///   - args: the arguments to pass to the method call.
    ///   - force: force singing and sending the transaction even if it is a read call. Default false.
    ///   - methodOptions: method options for fine-tuning the call.
    ///
    public func invokeMethod(name:String, args:[SCValXDR]? = nil, force:Bool = false, methodOptions:MethodOptions? = nil) async throws -> SCValXDR {
        let tx = try await buildInvokeMethodTx(name: name, args: args, methodOptions: methodOptions)
        let isReadCall = try tx.isReadCall()
        if !force && isReadCall {
            return try tx.getSimulationData().returnedValue
        }
        let response = try await tx.signAndSend(force:force)
        if let err = response.error {
            throw SorobanClientError.invokeFailed(message: "Invoke \(name) failed with message: \(err.message) and code: \(err.code).")
        }
        
        if response.status != GetTransactionResponse.STATUS_SUCCESS {
            throw SorobanClientError.invokeFailed(message:"Invoke \(name) failed with result: \(response.resultXdr ?? "unknown").")
        }
        guard let result = response.resultValue else {
            throw SorobanClientError.invokeFailed(message:"Could not extract return value from \(name) invocation.")
        }
        return result
    }
    
    /// Creates an AssembledTransaction for invoking the given method.
    /// This is usefully if you need to manipulate the transaction before signing and sending.
    ///
    /// - Parameters:
    ///   - name: the name of the method to invoke. Will throw an exception if the method does not exist.
    ///   - args: the arguments to pass to the method call.
    ///   - methodOptions: method options for fine-tuning the call.
    ///
    public func buildInvokeMethodTx(name:String, args:[SCValXDR]? = nil, methodOptions:MethodOptions? = nil, enableServerLogging:Bool? = nil) async throws -> AssembledTransaction {
        if !methodNames.contains(name) {
            throw SorobanClientError.methodNotFound(message: "Method '\(name)' does not exist.")
        }

        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: methodOptions ?? MethodOptions(),
                                                  method: name,
                                                  arguments: args,
                                                  enableServerLogging: enableServerLogging ?? clientOptions.enableServerLogging)
        return try await AssembledTransaction.build(options: options)
    }
    
}
