//
//  InvokeHostFunctionOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

// Invokes soroban host function. Used to install (deploy), create and invoke smart contracts.
public class InvokeHostFunctionOperation:Operation {
    
    public let hostFunction:HostFunctionXDR
    public var auth:[SorobanAuthorizationEntryXDR] = []
    
    public init(hostFunction:HostFunctionXDR, auth:[SorobanAuthorizationEntryXDR] = [], sourceAccountId:String? = nil) {
        self.hostFunction = hostFunction;
        self.auth = auth;
        super.init(sourceAccountId: sourceAccountId)
    }
    
    public static func forInvokingContract(contractId:String, functionName:String, functionArguments:[SCValXDR]? = nil, sourceAccountId:String? = nil, auth: [SorobanAuthorizationEntryXDR]? = nil) throws -> InvokeHostFunctionOperation {
        var args = [SCValXDR.address(try SCAddressXDR(contractId:contractId)),
                    SCValXDR.symbol(functionName)]
        if let fArgs = functionArguments {
            args.append(contentsOf: fArgs)
        }
        let hostFunction = HostFunctionXDR.invokeContract(args)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }
    
    public static func forUploadingContractWasm(contractCode:Data, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let hostFunction = HostFunctionXDR.uploadContractWasm(contractCode)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }
    
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
