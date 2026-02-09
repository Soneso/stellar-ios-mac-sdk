//
//  SorobanClient.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// High-level client for interacting with deployed Soroban smart contracts.
///
/// SorobanClient provides a simplified interface for common contract operations:
/// - Installing contract WebAssembly code
/// - Deploying contracts with constructor arguments
/// - Invoking contract methods (both read-only and write operations)
/// - Automatic transaction construction, simulation, and submission
///
/// The client automatically handles:
/// - Transaction building with correct parameters
/// - Simulation to get resource requirements
/// - Distinguishing between read and write calls
/// - Return value extraction from transaction results
///
/// Use this class when you want a streamlined experience for contract interaction.
/// For more control over transaction construction, use AssembledTransaction directly.
///
/// Example usage:
/// ```swift
/// // Connect to an existing contract
/// let clientOptions = ClientOptions(
///     sourceAccountKeyPair: sourceKeyPair,
///     contractId: "CCONTRACT123...",
///     network: Network.testnet,
///     rpcUrl: "https://soroban-testnet.stellar.org"
/// )
/// let client = try await SorobanClient.forClientOptions(options: clientOptions)
///
/// // Invoke a read-only method
/// let balance = try await client.invokeMethod(
///     name: "balance",
///     args: [try SCValXDR.address(userAddress)]
/// )
///
/// // Invoke a write method
/// let result = try await client.invokeMethod(
///     name: "transfer",
///     args: [fromAddr, toAddr, amount]
/// )
/// print("Transfer result: \(result)")
/// ```
///
/// See also:
/// - [AssembledTransaction] for lower-level transaction control
/// - [ContractSpec] for contract interface parsing
/// - [Stellar developer docs](https://developers.stellar.org)
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
    
    /// Deploys a smart contract to the Stellar network.
    ///
    /// Contract deployment involves:
    /// 1. Installing the contract WASM code (use install method first)
    /// 2. Creating a contract instance with a unique contract ID
    /// 3. Optionally invoking the contract's constructor function
    ///
    /// The contract must be installed before deployment. Use SorobanClient.install to
    /// upload the contract code and obtain a wasm hash, then use that hash in the deploy request.
    ///
    /// - Parameter deployRequest: Deployment parameters including wasm hash, constructor arguments, and network settings
    /// - Returns: SorobanClient instance connected to the newly deployed contract
    /// - Throws: SorobanClientError if deployment fails
    ///
    /// Example:
    /// ```swift
    /// // First install the contract
    /// let installRequest = InstallRequest(
    ///     sourceAccountKeyPair: keyPair,
    ///     wasmBytes: contractWasmBytes,
    ///     network: Network.testnet,
    ///     rpcUrl: "https://soroban-testnet.stellar.org"
    /// )
    /// let wasmHash = try await SorobanClient.install(installRequest: installRequest)
    ///
    /// // Then deploy it
    /// let deployRequest = DeployRequest(
    ///     sourceAccountKeyPair: keyPair,
    ///     wasmHash: wasmHash,
    ///     network: Network.testnet,
    ///     rpcUrl: "https://soroban-testnet.stellar.org",
    ///     constructorArgs: [arg1, arg2]  // Constructor arguments if needed
    /// )
    /// let client = try await SorobanClient.deploy(deployRequest: deployRequest)
    /// print("Contract deployed at: \(client.contractId)")
    /// ```
    ///
    /// See also:
    /// - install(installRequest:force:) for uploading contract code
    /// - [Stellar developer docs](https://developers.stellar.org)
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
    
    /// Installs (uploads) contract WebAssembly code to the Stellar network.
    ///
    /// Installing a contract is the first step in contract deployment. This operation uploads
    /// the compiled WebAssembly bytecode to the network and returns a unique hash identifier.
    /// The same WASM code can be used to deploy multiple contract instances.
    ///
    /// The installation process:
    /// 1. Uploads the WASM bytecode to the network
    /// 2. Returns a hash that uniquely identifies this code
    /// 3. This hash is then used when deploying contract instances
    ///
    /// Note: If the code is already installed, this operation will detect it during simulation
    /// and can return the existing hash without submitting a transaction (unless force is true).
    ///
    /// - Parameter installRequest: Installation parameters including WASM bytes, source account, and network settings
    /// - Parameter force: If true, always submit transaction even if code is already installed. Default is false.
    /// - Returns: Hex-encoded hash of the installed WASM code
    /// - Throws: SorobanClientError if installation fails
    ///
    /// Example:
    /// ```swift
    /// // Load contract WASM file
    /// let wasmBytes = try Data(contentsOf: contractWasmUrl)
    ///
    /// // Install the contract
    /// let installRequest = InstallRequest(
    ///     sourceAccountKeyPair: keyPair,
    ///     wasmBytes: wasmBytes,
    ///     network: Network.testnet,
    ///     rpcUrl: "https://soroban-testnet.stellar.org"
    /// )
    /// let wasmHash = try await SorobanClient.install(installRequest: installRequest)
    /// print("Contract code installed with hash: \(wasmHash)")
    ///
    /// // Use this hash to deploy contract instances
    /// ```
    ///
    /// See also:
    /// - deploy(deployRequest:) for creating contract instances
    /// - [Stellar developer docs](https://developers.stellar.org)
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
            guard let bytes = returnedValue.bytes else {
                throw SorobanClientError.installFailed(message: "Could not extract wasm hash from simulation result.")
            }
            return bytes.base16EncodedString()
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
    
    /// Gets the spec entries of the contract represented by this client.
    /// - Returns: Array of SCSpecEntryXDR objects
    public func getSpecEntries() -> [SCSpecEntryXDR] {
        return specEntries
    }
    
    /// Creates a ContractSpec instance for this contract.
    /// - Returns: ContractSpec instance that can be used for type conversions
    public func getContractSpec() -> ContractSpec {
        return ContractSpec(entries: specEntries)
    }
    
}
