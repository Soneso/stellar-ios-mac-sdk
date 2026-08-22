//
//  InvokeHostFunctionOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Invokes Soroban host functions for smart contract deployment, creation, and invocation operations.
public class InvokeHostFunctionOperation:Operation, @unchecked Sendable {

    /// The host function to invoke.
    public let hostFunction:HostFunctionXDR
    /// The authorizations required to execute the host function.
    public var auth:[SorobanAuthorizationEntryXDR] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _auth
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _auth = newValue
        }
    }
    private var _auth:[SorobanAuthorizationEntryXDR] = []
    private let lock = NSLock()

    /// Creates a new invoke host function operation with specified parameters.
    public init(hostFunction:HostFunctionXDR, auth:[SorobanAuthorizationEntryXDR] = [], sourceAccountId:String? = nil) {
        self.hostFunction = hostFunction;
        self._auth = auth;
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
    ///
    /// - Parameter wasmId: the 64 character hex of the 32 byte wasm hash
    /// - Throws: StellarSDKError.invalidArgument if the wasm id is not exactly 64 hexadecimal characters
    public static func forCreatingContract(wasmId:String, address: SCAddressXDR, salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let saltToSet = try salt ?? randomSalt()
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt: saltToSet)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.wasm(try wasmId.wrappedData32FromHex(idKind: "wasm id"))
        let createContractArgs = CreateContractArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable)
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }
    
    /// Creates an operation to instantiate a contract with constructor arguments (protocol >= 22).
    ///
    /// - Parameter wasmId: the 64 character hex of the 32 byte wasm hash
    /// - Throws: StellarSDKError.invalidArgument if the wasm id is not exactly 64 hexadecimal characters
    public static func forCreatingContractWithConstructor(wasmId:String, address: SCAddressXDR, constructorArguments:[SCValXDR] = [], salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let saltToSet = try salt ?? randomSalt()
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt: saltToSet)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.wasm(try wasmId.wrappedData32FromHex(idKind: "wasm id"))
        let createContractV2Args = CreateContractV2ArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable, constructorArgs: constructorArguments)
        let hostFunction = HostFunctionXDR.createContractV2(createContractV2Args)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to instantiate a contract from a CAP-85 external reference (protocol >= 28).
    ///
    /// The executable names an owner contract and a tag; the owner holds a persistent
    /// contract data entry under that tag whose value is the 32-byte hash of an already
    /// uploaded wasm, and the created instance runs that code. An executable tag is an
    /// XDR string and may carry arbitrary bytes; the operation carries the given bytes
    /// unchanged.
    ///
    /// - Parameter executableOwner: the contract holding the executable tag entry; must be a contract address
    /// - Parameter tag: the tag of the executable entry on the owner; matched byte for byte
    /// - Parameter address: the deployer address (account or contract)
    /// - Parameter salt: optional 32 byte salt for contract id generation; random if not provided
    /// - Throws: `StellarSDKError.invalidArgument` if the executable owner is not a contract address
    public static func forCreatingContractFromExternalRef(executableOwner: SCAddressXDR, tag: Data, address: SCAddressXDR, salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        try requireContractExecutableOwner(executableOwner)
        let saltToSet = try salt ?? randomSalt()
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt: saltToSet)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.externalRef(ContractExecutableExternalRefXDR(executableOwner: executableOwner, tag: tag))
        let createContractArgs = CreateContractArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable)
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to instantiate a contract from a CAP-85 external reference
    /// (protocol >= 28) with a text tag. The operation carries the tag as the UTF-8
    /// bytes of the given text; the entry is matched byte for byte against those bytes.
    ///
    /// - Parameter executableOwner: the contract holding the executable tag entry; must be a contract address
    /// - Parameter tag: the tag of the executable entry on the owner, carried as its UTF-8 bytes
    /// - Parameter address: the deployer address (account or contract)
    /// - Parameter salt: optional 32 byte salt for contract id generation; random if not provided
    /// - Throws: `StellarSDKError.invalidArgument` if the executable owner is not a contract address
    public static func forCreatingContractFromExternalRef(executableOwner: SCAddressXDR, tag: String, address: SCAddressXDR, salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        return try forCreatingContractFromExternalRef(executableOwner: executableOwner,
                                                      tag: Data(tag.utf8),
                                                      address: address,
                                                      salt: salt,
                                                      sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to instantiate a contract from a CAP-85 external reference
    /// with constructor arguments (protocol >= 28). An executable tag is an XDR string
    /// and may carry arbitrary bytes; the operation carries the given bytes unchanged.
    ///
    /// - Parameter executableOwner: the contract holding the executable tag entry; must be a contract address
    /// - Parameter tag: the tag of the executable entry on the owner; matched byte for byte
    /// - Parameter address: the deployer address (account or contract)
    /// - Parameter constructorArguments: arguments passed to the contract constructor
    /// - Parameter salt: optional 32 byte salt for contract id generation; random if not provided
    /// - Throws: `StellarSDKError.invalidArgument` if the executable owner is not a contract address
    public static func forCreatingContractFromExternalRefWithConstructor(executableOwner: SCAddressXDR, tag: Data, address: SCAddressXDR, constructorArguments:[SCValXDR] = [], salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        try requireContractExecutableOwner(executableOwner)
        let saltToSet = try salt ?? randomSalt()
        let contractIdPreimageFormAddress = ContractIDPreimageFromAddressXDR(address: address, salt: saltToSet)
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(contractIdPreimageFormAddress)
        let executable = ContractExecutableXDR.externalRef(ContractExecutableExternalRefXDR(executableOwner: executableOwner, tag: tag))
        let createContractV2Args = CreateContractV2ArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable, constructorArgs: constructorArguments)
        let hostFunction = HostFunctionXDR.createContractV2(createContractV2Args)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to instantiate a contract from a CAP-85 external reference
    /// with constructor arguments (protocol >= 28) and a text tag. The operation carries
    /// the tag as the UTF-8 bytes of the given text; the entry is matched byte for byte
    /// against those bytes.
    ///
    /// - Parameter executableOwner: the contract holding the executable tag entry; must be a contract address
    /// - Parameter tag: the tag of the executable entry on the owner, carried as its UTF-8 bytes
    /// - Parameter address: the deployer address (account or contract)
    /// - Parameter constructorArguments: arguments passed to the contract constructor
    /// - Parameter salt: optional 32 byte salt for contract id generation; random if not provided
    /// - Throws: `StellarSDKError.invalidArgument` if the executable owner is not a contract address
    public static func forCreatingContractFromExternalRefWithConstructor(executableOwner: SCAddressXDR, tag: String, address: SCAddressXDR, constructorArguments:[SCValXDR] = [], salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        return try forCreatingContractFromExternalRefWithConstructor(executableOwner: executableOwner,
                                                                     tag: Data(tag.utf8),
                                                                     address: address,
                                                                     constructorArguments: constructorArguments,
                                                                     salt: salt,
                                                                     sourceAccountId: sourceAccountId)
    }

    /// Creates an operation to deploy a Stellar Asset Contract for a specific asset.
    public static func forDeploySACWithAsset(asset:Asset, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let contractIDPreimage = ContractIDPreimageXDR.fromAsset(try asset.toXDR())
        let executable = ContractExecutableXDR.token
        let createContractArgs = CreateContractArgsXDR(contractIDPreimage: contractIDPreimage, executable: executable)
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)
        return InvokeHostFunctionOperation(hostFunction: hostFunction, sourceAccountId: sourceAccountId)
    }
    
    private static func requireContractExecutableOwner(_ executableOwner: SCAddressXDR) throws {
        guard case .contract = executableOwner else {
            throw StellarSDKError.invalidArgument(message: "External reference owner is not a contract address; only a contract can hold the executable tag entry")
        }
    }

    private static func randomSalt() throws -> WrappedData32 {
        var saltData = Data(count: 32)
        let result = saltData.withUnsafeMutableBytes { bufferPointer -> OSStatus in
            guard let baseAddress = bufferPointer.baseAddress else {
                return errSecAllocate
            }
            return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
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
        self._auth = fromXDR.auth
        super.init(sourceAccountId: sourceAccountId)
    }

    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        lock.lock()
        let currentAuth = _auth
        lock.unlock()
        let xdrOp = InvokeHostFunctionOpXDR(hostFunction: hostFunction, auth: currentAuth)
        return OperationBodyXDR.invokeHostFunctionOp(xdrOp)
    }
}
