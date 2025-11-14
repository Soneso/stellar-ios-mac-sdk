//
//  InvokeHostFunctionOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Invokes Soroban host functions for smart contract deployment, creation, and invocation operations.
public class InvokeHostFunctionOperation:Operation {

    /// The host function to invoke.
    public let hostFunction:HostFunctionXDR
    /// The authorizations required to execute the host function.
    public var auth:[SorobanAuthorizationEntryXDR] = []

    /// Creates a new invoke host function operation with specified parameters.
    public init(hostFunction:HostFunctionXDR, auth:[SorobanAuthorizationEntryXDR] = [], sourceAccountId:String? = nil) {
        self.hostFunction = hostFunction;
        self.auth = auth;
        super.init(sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to invoke a function on a deployed smart contract.
    public static func forInvokingContract(contractId:String, functionName:String, functionArguments:[SCValXDR] = [], sourceAccountId:String? = nil, auth: [SorobanAuthorizationEntryXDR]? = nil) throws -> InvokeHostFunctionOperation {
        let invoekArgs = InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId:contractId),
                                               functionName: functionName, args: functionArguments)
        let hostFunction = HostFunctionXDR.invokeContract(invoekArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to upload Wasm bytecode for contract deployment.
    public static func forUploadingContractWasm(contractCode:Data, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let hostFunction = HostFunctionXDR.uploadContractWasm(contractCode)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to instantiate a contract from uploaded Wasm using contract ID preimage.
    public static func forCreatingContract(wasmId:String, address: SCAddressXDR, salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        var saltToSet = salt
        if saltToSet == nil {
            saltToSet = try randomSalt()
        }
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt:saltToSet!)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.wasm(wasmId.wrappedData32FromHex())
        let createContractArgs = CreateContractArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable)
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }
    
    /// Creates an operation to instantiate a contract with constructor arguments (protocol >= 22).
    public static func forCreatingContractWithConstructor(wasmId:String, address: SCAddressXDR, constructorArguments:[SCValXDR] = [], salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        var saltToSet = salt
        if saltToSet == nil {
            saltToSet = try randomSalt()
        }
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt:saltToSet!)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.wasm(wasmId.wrappedData32FromHex())
        let createContractV2Args = CreateContractV2ArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable, constructorArgs: constructorArguments)
        let hostFunction = HostFunctionXDR.createContractV2(createContractV2Args)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to deploy a Stellar Asset Contract using a source account address.
    public static func forDeploySACWithSourceAccount(address: SCAddressXDR, salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        var saltToSet = salt
        if saltToSet == nil {
            saltToSet = try randomSalt()
        }
        
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt:saltToSet!)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.token
        let createContractArgs = CreateContractArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable)
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to deploy a Stellar Asset Contract for a specific asset.
    public static func forDeploySACWithAsset(asset:Asset, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let contractIDPreimage = ContractIDPreimageXDR.fromAsset(try asset.toXDR())
        let executable = ContractExecutableXDR.token
        let createContractArgs = CreateContractArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable)
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }
    
    private static func randomSalt() throws -> WrappedData32 {
        var saltData = Data(count: 32)
        let result = saltData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        if result != errSecSuccess {
            throw StellarSDKError.encodingError(message: "unable to generate random salt")
        }
        return WrappedData32(saltData)
    }
    
    /// Creates a new InvokeHostFunctionOperation object from the given InvokeHostFunctionOpXDR object.
    ///
    /// - Parameter fromXDR: the InvokeHostFunctionOpXDR object to be used to create a new InvokeHostFunctionOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:InvokeHostFunctionOpXDR, sourceAccountId:String?) throws {
        self.hostFunction = fromXDR.hostFunction
        self.auth = fromXDR.auth
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let xdrOp = InvokeHostFunctionOpXDR(hostFunction: hostFunction, auth: auth)
        return OperationBodyXDR.invokeHostFunction(xdrOp)
    }
}
