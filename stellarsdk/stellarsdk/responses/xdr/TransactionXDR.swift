//
//  TransactionXDR.swift
//  stellarsdk
//
//  Created by SONESO
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct TransactionXDR: XDRCodable, Sendable {
    public let sourceAccount: MuxedAccountXDR
    public var fee: UInt32
    public let seqNum: Int64
    public var cond: PreconditionsXDR
    public var memo: MemoXDR
    public var operations: [OperationXDR]
    public var ext: TransactionExtXDR
    
    public var signatures = [DecoratedSignatureXDR]()
    
    public init(sourceAccount: MuxedAccountXDR, seqNum: Int64, cond: PreconditionsXDR, memo: MemoXDR, operations: [OperationXDR], maxOperationFee:UInt32 = 100, ext:TransactionExtXDR = TransactionExtXDR.void) {
        self.sourceAccount = sourceAccount
        self.seqNum = seqNum
        self.cond = cond
        self.memo = memo
        self.operations = operations
        
        self.fee = maxOperationFee * UInt32(operations.count)
        
        self.ext = ext
    }
    
    public init(sourceAccount: PublicKey, seqNum: Int64, cond: PreconditionsXDR, memo: MemoXDR, operations: [OperationXDR], maxOperationFee:UInt32 = 100, ext:TransactionExtXDR = TransactionExtXDR.void) {
        let mux = MuxedAccountXDR.ed25519(sourceAccount.bytes)
        self.init(sourceAccount: mux, seqNum: seqNum, cond: cond, memo: memo, operations: operations, maxOperationFee: maxOperationFee, ext:ext)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(MuxedAccountXDR.self)
        fee = try container.decode(UInt32.self)
        seqNum = try container.decode(Int64.self)
        cond = try container.decode(PreconditionsXDR.self)
        memo = try container.decode(MemoXDR.self)
        operations = try decodeArray(type: OperationXDR.self, dec: decoder)
        ext = try container.decode(TransactionExtXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sourceAccount)
        try container.encode(fee)
        try container.encode(seqNum)
        try container.encode(cond)
        try container.encode(memo)
        try container.encode(operations)
        try container.encode(ext)
    }
    
    public mutating func sign(keyPair:KeyPair, network:Network) throws {
        let transactionHash = try [UInt8](hash(network: network))
        let signature = keyPair.signDecorated(transactionHash)
        signatures.append(signature)
    }
    
    public mutating func addSignature(signature: DecoratedSignatureXDR) {
        signatures.append(signature)
    }
    
    private func signatureBase(network:Network) throws -> Data {
        let payload = TransactionSignaturePayload(networkId: WrappedData32(network.networkId), taggedTransaction: .typeTX(self))
        return try Data(XDREncoder.encode(payload))
    }
    
    public func hash(network:Network) throws -> Data {
        return try signatureBase(network: network).sha256Hash
    }
    
    public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR {
        let envelopeV1 = TransactionV1EnvelopeXDR(tx: self, signatures: signatures)
        return TransactionEnvelopeXDR.v1(envelopeV1)
    }
    
    public func encodedEnvelope() throws -> String {
        let envelope = try toEnvelopeXDR()
        var encodedEnvelope = try XDREncoder.encode(envelope)
        
        return Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    }
    
    public func toEnvelopeV1XDR() throws -> TransactionV1EnvelopeXDR {        
        return TransactionV1EnvelopeXDR(tx: self, signatures: signatures)
    }
    
    public func encodedV1Envelope() throws -> String {
        let envelope = try toEnvelopeV1XDR()
        var encodedEnvelope = try XDREncoder.encode(envelope)
        
        return Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    }
    
    public func encodedV1Transaction() throws -> String {
        var encodedT = try XDREncoder.encode(self)
        
        return Data(bytes: &encodedT, count: encodedT.count).base64EncodedString()
    }
}

public enum ContractIDPreimageType: Int32, Sendable {
    case fromAddress = 0
    case fromAsset = 1
}

public struct ContractIDPreimageFromAddressXDR: XDRCodable, Sendable {
    public var address: SCAddressXDR
    public let salt: WrappedData32
    
    public init(address: SCAddressXDR, salt: WrappedData32) {
        self.address = address
        self.salt = salt
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        address = try container.decode(SCAddressXDR.self)
        salt = try container.decode(WrappedData32.self)
        /*let data = wData.wrapped
        salt = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &salt, count: data.count)*/
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(salt)
        /*var bytesArray = salt
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)*/
    }
}

public enum ContractIDPreimageXDR: XDRCodable, Sendable {
    case fromAddress(ContractIDPreimageFromAddressXDR)
    case fromAsset(AssetXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = ContractIDPreimageType(rawValue: discriminant)
        
        switch type {
        case .fromAddress:
            let address = try container.decode(ContractIDPreimageFromAddressXDR.self)
            self = .fromAddress(address)
        case .fromAsset:
            let asset = try container.decode(AssetXDR.self)
            self = .fromAsset(asset)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid ContractIDPreimageXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .fromAddress: return ContractIDPreimageType.fromAddress.rawValue
        case .fromAsset: return ContractIDPreimageType.fromAsset.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .fromAddress(let fromAddress):
            try container.encode(fromAddress)
            break
        case .fromAsset (let asset):
            try container.encode(asset)
            break
        }
    }
    
    public var fromAddress:ContractIDPreimageFromAddressXDR? {
        switch self {
        case .fromAddress(let addr):
            return addr
        default:
            return nil
        }
    }
    
    public var fromAsset:AssetXDR? {
        switch self {
        case .fromAsset(let asset):
            return asset
        default:
            return nil
        }
    }
}

public struct InvokeContractArgsXDR: XDRCodable, Sendable {
    public let contractAddress: SCAddressXDR
    public let functionName: String
    public let args: [SCValXDR]
    
    public init(contractAddress:SCAddressXDR, functionName:String, args: [SCValXDR]) {
        self.contractAddress = contractAddress
        self.functionName = functionName
        self.args = args
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractAddress = try container.decode(SCAddressXDR.self)
        functionName = try container.decode(String.self)
        args = try decodeArray(type: SCValXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contractAddress)
        try container.encode(functionName)
        try container.encode(args)
    }
}


public struct CreateContractArgsXDR: XDRCodable, Sendable {
    public let contractIDPreimage: ContractIDPreimageXDR
    public let executable: ContractExecutableXDR
    
    public init(contractIDPreimage:ContractIDPreimageXDR, executable:ContractExecutableXDR) {
        self.contractIDPreimage = contractIDPreimage
        self.executable = executable
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractIDPreimage = try container.decode(ContractIDPreimageXDR.self)
        executable = try container.decode(ContractExecutableXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contractIDPreimage)
        try container.encode(executable)
    }
}

public struct CreateContractV2ArgsXDR: XDRCodable, Sendable {
    public let contractIDPreimage: ContractIDPreimageXDR
    public let executable: ContractExecutableXDR
    public let constructorArgs: [SCValXDR]
    
    public init(contractIDPreimage:ContractIDPreimageXDR, executable:ContractExecutableXDR, constructorArgs:[SCValXDR]) {
        self.contractIDPreimage = contractIDPreimage
        self.executable = executable
        self.constructorArgs = constructorArgs
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractIDPreimage = try container.decode(ContractIDPreimageXDR.self)
        executable = try container.decode(ContractExecutableXDR.self)
        constructorArgs = try decodeArray(type: SCValXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contractIDPreimage)
        try container.encode(executable)
        try container.encode(constructorArgs)
    }
}

public enum HostFunctionType: Int32, Sendable {
    case invokeContract = 0
    case createContract = 1
    case uploadContractWasm = 2
    case createContractV2 = 3
}

public enum HostFunctionXDR: XDRCodable, Sendable {
    case invokeContract(InvokeContractArgsXDR)
    case createContract(CreateContractArgsXDR)
    case createContractV2(CreateContractV2ArgsXDR)
    case uploadContractWasm(Data)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = HostFunctionType(rawValue: discriminant)
        
        switch type {
        case .invokeContract:
            let invokeContract = try container.decode(InvokeContractArgsXDR.self)
            self = .invokeContract(invokeContract)
        case .createContract:
            let createContract = try container.decode(CreateContractArgsXDR.self)
            self = .createContract(createContract)
        case .uploadContractWasm:
            let wasm = try container.decode(Data.self)
            self = .uploadContractWasm(wasm)
        case .createContractV2:
            let createContract = try container.decode(CreateContractV2ArgsXDR.self)
            self = .createContractV2(createContract)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid HostFunctionXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .invokeContract: return HostFunctionType.invokeContract.rawValue
        case .createContract: return HostFunctionType.createContract.rawValue
        case .uploadContractWasm: return HostFunctionType.uploadContractWasm.rawValue
        case .createContractV2: return HostFunctionType.createContractV2.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .invokeContract(let val):
            try container.encode(val)
            break
        case .createContract(let val):
            try container.encode(val)
            break
        case .uploadContractWasm (let val):
            try container.encode(val)
            break
        case .createContractV2(let val):
            try container.encode(val)
            break
        }
    }
    
    public var invokeContract:InvokeContractArgsXDR? {
        switch self {
        case .invokeContract(let val):
            return val
        default:
            return nil
        }
    }
    
    public var createContract:CreateContractArgsXDR? {
        switch self {
        case .createContract(let val):
            return val
        default:
            return nil
        }
    }
    
    public var uploadContractWasm:Data? {
        switch self {
        case .uploadContractWasm(let val):
            return val
        default:
            return nil
        }
    }
    
    public var createContractV2:CreateContractV2ArgsXDR? {
        switch self {
        case .createContractV2(let val):
            return val
        default:
            return nil
        }
    }
}

public enum SorobanAuthorizedFunctionType: Int32, Sendable {
    case contractFn = 0
    case createContractHostFn = 1
    case createContractV2HostFn = 2
}

public enum SorobanAuthorizedFunctionXDR: XDRCodable, Sendable {
    case contractFn(InvokeContractArgsXDR)
    case createContractHostFn(CreateContractArgsXDR)
    case createContractV2HostFn(CreateContractV2ArgsXDR)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SorobanAuthorizedFunctionType(rawValue: discriminant)
        
        switch type {
        case .contractFn:
            let contractFn = try container.decode(InvokeContractArgsXDR.self)
            self = .contractFn(contractFn)
        case .createContractHostFn:
            let contractHostFn = try container.decode(CreateContractArgsXDR.self)
            self = .createContractHostFn(contractHostFn)
        case .createContractV2HostFn:
            let contractV2HostFn = try container.decode(CreateContractV2ArgsXDR.self)
            self = .createContractV2HostFn(contractV2HostFn)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SorobanAuthorizedFunctionXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .contractFn: return SorobanAuthorizedFunctionType.contractFn.rawValue
        case .createContractHostFn: return SorobanAuthorizedFunctionType.createContractHostFn.rawValue
        case .createContractV2HostFn: return SorobanAuthorizedFunctionType.createContractV2HostFn.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .contractFn(let val):
            try container.encode(val)
            break
        case .createContractHostFn(let val):
            try container.encode(val)
            break
        case .createContractV2HostFn(let val):
            try container.encode(val)
            break
        }
    }
    
    public var contractFn:InvokeContractArgsXDR? {
        switch self {
        case .contractFn(let val):
            return val
        default:
            return nil
        }
    }
    
    public var contractHostFn:CreateContractArgsXDR? {
        switch self {
        case .createContractHostFn(let val):
            return val
        default:
            return nil
        }
    }
    
    public var contractV2HostFn:CreateContractV2ArgsXDR? {
        switch self {
        case .createContractV2HostFn(let val):
            return val
        default:
            return nil
        }
    }
}

public struct SorobanAuthorizedInvocationXDR: XDRCodable, Sendable {
    public var function: SorobanAuthorizedFunctionXDR
    public var subInvocations: [SorobanAuthorizedInvocationXDR]
    
    public init(function: SorobanAuthorizedFunctionXDR, subInvocations: [SorobanAuthorizedInvocationXDR]) {
        self.function = function
        self.subInvocations = subInvocations
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        function = try container.decode(SorobanAuthorizedFunctionXDR.self)
        subInvocations =  try decodeArray(type: SorobanAuthorizedInvocationXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(function)
        try container.encode(subInvocations)
    }
}

public struct SorobanAddressCredentialsXDR: XDRCodable, Sendable {
    public var address: SCAddressXDR
    public var nonce: Int64
    public var signatureExpirationLedger: UInt32
    public var signature: SCValXDR
    
    public init(address: SCAddressXDR, nonce: Int64, signatureExpirationLedger: UInt32, signature: SCValXDR) {
        self.address = address
        self.nonce = nonce
        self.signatureExpirationLedger = signatureExpirationLedger
        self.signature = signature
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        address = try container.decode(SCAddressXDR.self)
        nonce = try container.decode(Int64.self)
        signatureExpirationLedger = try container.decode(UInt32.self)
        signature =  try container.decode(SCValXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(nonce)
        try container.encode(signatureExpirationLedger)
        try container.encode(signature)
    }
    
    public mutating func appendSignature(signature: SCValXDR) {
        var sigs = [SCValXDR]()
        if let oldSigs = signature.vec {
            sigs = oldSigs
        }
        sigs.append(signature)
        self.signature = SCValXDR.vec(sigs)
    }
}

public enum SorobanCredentialsType: Int32, Sendable {
    case sourceAccount = 0
    case address = 1
}

public enum SorobanCredentialsXDR: XDRCodable, Sendable {
    case sourceAccount
    case address(SorobanAddressCredentialsXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SorobanCredentialsType(rawValue: discriminant)
        
        switch type {
        case .sourceAccount:
            self = .sourceAccount
        case .address:
            let address = try container.decode(SorobanAddressCredentialsXDR.self)
            self = .address(address)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SorobanCredentialsXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .sourceAccount: return SorobanCredentialsType.sourceAccount.rawValue
        case .address: return SorobanCredentialsType.address.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .sourceAccount:
            break
        case .address (let address):
            try container.encode(address)
            break
        }
    }
    
    public var address:SorobanAddressCredentialsXDR? {
        switch self {
        case .address(let addr):
            return addr
        default:
            return nil
        }
    }
}

public struct SorobanAuthorizationEntryXDR: XDRCodable, Sendable {
    public var credentials: SorobanCredentialsXDR
    public var rootInvocation: SorobanAuthorizedInvocationXDR
    
    public init(credentials: SorobanCredentialsXDR, rootInvocation: SorobanAuthorizedInvocationXDR) {
        self.credentials = credentials
        self.rootInvocation = rootInvocation
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        credentials = try container.decode(SorobanCredentialsXDR.self)
        rootInvocation = try container.decode(SorobanAuthorizedInvocationXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(credentials)
        try container.encode(rootInvocation)
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanAuthorizationEntryXDR(from: xdrDecoder)
    }
    
    public mutating func sign(signer:KeyPair, network:Network, signatureExpirationLedger:UInt32? = nil) throws {
        if (credentials.address == nil) {
            throw StellarSDKError.invalidArgument(message: "credentials must be of type address")
        }
        if (signer.privateKey == nil) {
            throw StellarSDKError.invalidArgument(message: "signer KeyPair must contain the private key to be able to sign")
        }
        
        if let sigExpLedger = signatureExpirationLedger, var address = credentials.address {
            address.signatureExpirationLedger = sigExpLedger
            self.credentials = SorobanCredentialsXDR.address(address)
        }
        
        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(networkID: WrappedData32(network.networkId), nonce: credentials.address!.nonce, signatureExpirationLedger: credentials.address!.signatureExpirationLedger, invocation: rootInvocation)
        
        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)
        
        let encoded = try XDREncoder.encode(preimage)
        let payload = Data(bytes: encoded, count: encoded.count).sha256Hash
        let signature = signer.sign([UInt8](payload))
        let accountEd25519Signature = AccountEd25519Signature(publicKey: signer.publicKey, signature: signature)
        let sigVal = SCValXDR(accountEd25519Signature: accountEd25519Signature)
        var address = credentials.address!
        address.appendSignature(signature: sigVal)
        self.credentials = SorobanCredentialsXDR.address(address)
    }
}

public final class AccountEd25519Signature: Sendable {
    
    public let publicKey:PublicKey
    public let signature:[UInt8]
    
    public init(publicKey:PublicKey, signature:[UInt8]) {
        self.publicKey = publicKey
        self.signature = signature
    }
}


public struct LedgerFootprintXDR: XDRCodable, Sendable {
    public var readOnly: [LedgerKeyXDR]
    public var readWrite: [LedgerKeyXDR]
    
    public init(readOnly:[LedgerKeyXDR], readWrite:[LedgerKeyXDR]) {
        self.readOnly = readOnly
        self.readWrite = readWrite
    }

    public init(from decoder: Decoder) throws {
        //var container = try decoder.unkeyedContainer()
        readOnly = try decodeArray(type: LedgerKeyXDR.self, dec: decoder)
        readWrite = try decodeArray(type: LedgerKeyXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(readOnly)
        try container.encode(readWrite)
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try LedgerFootprintXDR(from: xdrDecoder)
    }
}

public struct InvokeHostFunctionSuccessPreImageXDR: XDRCodable, Sendable {
    public var returnValue: SCValXDR
    public var events: [ContractEventXDR]
    
    internal init(returnValue: SCValXDR, events: [ContractEventXDR]) {
        self.returnValue = returnValue
        self.events = events
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        returnValue = try container.decode(SCValXDR.self)
        events = try decodeArray(type: ContractEventXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(returnValue)
        try container.encode(events)
    }
}

// Resource limits for a Soroban transaction.
// The transaction will fail if it exceeds any of these limits.
public struct SorobanResourcesXDR: XDRCodable, Sendable {
    
    // The ledger footprint of the transaction.
    public var footprint: LedgerFootprintXDR;
    
    // The maximum number of instructions this transaction can use
    public var instructions: UInt32
    
    // The maximum number of bytes this transaction can read from disk backed entries
    public var diskReadBytes: UInt32
    
    // The maximum number of bytes this transaction can write to ledger
    public var writeBytes: UInt32
    
    public init(footprint: LedgerFootprintXDR, instructions: UInt32 = 0, diskReadBytes: UInt32 = 0, writeBytes: UInt32 = 0) {
        self.footprint = footprint
        self.instructions = instructions
        self.diskReadBytes = diskReadBytes
        self.writeBytes = writeBytes
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        footprint = try container.decode(LedgerFootprintXDR.self)
        instructions = try container.decode(UInt32.self)
        diskReadBytes = try container.decode(UInt32.self)
        writeBytes = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(footprint)
        try container.encode(instructions)
        try container.encode(diskReadBytes)
        try container.encode(writeBytes)
    }
}

public struct SorobanResourcesExtV0: XDRCodable, Sendable {
    
    // Vector of indices representing what Soroban
    // entries in the footprint are archived, based on the
    // order of keys provided in the readWrite footprint.
    public var archivedSorobanEntries: [UInt32]
    
    public init(archivedSorobanEntries: [UInt32]) {
        self.archivedSorobanEntries = archivedSorobanEntries
    }
    
    public init(from decoder: Decoder) throws {
        archivedSorobanEntries = try decodeArray(type: UInt32.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(archivedSorobanEntries)
    }
}

public enum SorobanResourcesExt : XDRCodable, Sendable {
    case void
    case resourceExt(SorobanResourcesExtV0)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .resourceExt(try container.decode(SorobanResourcesExtV0.self))
        default:
            self = .void
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .void: return 0
        case .resourceExt:return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .resourceExt(let data):
            try container.encode(data)
            return
        }
    }
}

public struct SorobanTransactionDataXDR: XDRCodable, Sendable {
    public var ext: SorobanResourcesExt
    public var resources: SorobanResourcesXDR
    
    // Amount of the transaction `fee` allocated to the Soroban resource fees.
    // The fraction of `resourceFee` corresponding to `resources` specified
    // above is *not* refundable (i.e. fees for instructions, ledger I/O), as
    // well as fees for the transaction size.
    // The remaining part of the fee is refundable and the charged value is
    // based on the actual consumption of refundable resources (events, ledger
    // rent bumps).
    // The `inclusionFee` used for prioritization of the transaction is defined
    // as `tx.fee - resourceFee`.
    public var resourceFee: Int64

    public init(ext: SorobanResourcesExt = SorobanResourcesExt.void, resources: SorobanResourcesXDR, resourceFee: Int64 = 0) {
        self.ext = ext
        self.resources = resources
        self.resourceFee = resourceFee
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(SorobanResourcesExt.self)
        resources = try container.decode(SorobanResourcesXDR.self)
        resourceFee = try container.decode(Int64.self)
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanTransactionDataXDR(from: xdrDecoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(resources)
        try container.encode(resourceFee)
    }
    
    public var archivedSorobanEntries:[UInt32]? {
        switch ext {
        case .void:
            return nil
        case .resourceExt(let sorobanResourcesExtV0):
            return sorobanResourcesExtV0.archivedSorobanEntries
        }
    }

    
    
}

public enum TransactionExtXDR : XDRCodable, Sendable {
    case void
    case sorobanTransactionData(SorobanTransactionDataXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .sorobanTransactionData(try container.decode(SorobanTransactionDataXDR.self))
        default:
            self = .void
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .void: return 0
        case .sorobanTransactionData:return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .sorobanTransactionData(let data):
            try container.encode(data)
            return
        }
    }
}
