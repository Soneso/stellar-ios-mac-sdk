//
//  TransactionXDR.swift
//  stellarsdk
//
//  Created by SONESO
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct TransactionXDR: XDRCodable {
    public let sourceAccount: MuxedAccountXDR
    public var fee: UInt32
    public let seqNum: Int64
    public let cond: PreconditionsXDR
    public let memo: MemoXDR
    public var operations: [OperationXDR]
    public var ext: TransactionExtXDR
    
    private var signatures = [DecoratedSignatureXDR]()
    
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
        return try signatureBase(network: network).sha256()
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

public enum ContractIDPreimageType: Int32 {
    case fromAddress = 0
    case fromAsset = 1
}

public struct ContractIDPreimageFromAddressXDR: XDRCodable {
    public var address: SCAddressXDR
    public var salt: WrappedData32
    
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

public enum ContractIDPreimageXDR: XDRCodable {
    case fromAddress(ContractIDPreimageFromAddressXDR)
    case fromAsset(AssetXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = ContractIDPreimageType(rawValue: discriminant)!
        
        switch type {
        case .fromAddress:
            let address = try container.decode(ContractIDPreimageFromAddressXDR.self)
            self = .fromAddress(address)
        case .fromAsset:
            let asset = try container.decode(AssetXDR.self)
            self = .fromAsset(asset)
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

public struct CreateContractArgsXDR: XDRCodable {
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

public enum HostFunctionType: Int32 {
    case invokeContract = 0
    case createContract = 1
    case uploadContractWasm = 2
}

public enum HostFunctionXDR: XDRCodable {
    case invokeContract([SCValXDR])
    case createContract(CreateContractArgsXDR)
    case uploadContractWasm(Data)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = HostFunctionType(rawValue: discriminant)!
        
        switch type {
        case .invokeContract:
            let invokeContract = try decodeArray(type: SCValXDR.self, dec: decoder)
            self = .invokeContract(invokeContract)
        case .createContract:
            let createContract = try container.decode(CreateContractArgsXDR.self)
            self = .createContract(createContract)
        case .uploadContractWasm:
            let wasm = try container.decode(Data.self)
            self = .uploadContractWasm(wasm)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .invokeContract: return HostFunctionType.invokeContract.rawValue
        case .createContract: return HostFunctionType.createContract.rawValue
        case .uploadContractWasm: return HostFunctionType.uploadContractWasm.rawValue
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
        }
    }
    
    public var invokeContract:[SCValXDR]? {
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
}

public enum SorobanAuthorizedFunctionType: Int32 {
    case contractFn = 0
    case contractHostFn = 1
}

public struct SorobanAuthorizedContractFunctionXDR: XDRCodable {
    public var contractAddress: SCAddressXDR
    public var functionName: String
    public var args: [SCValXDR]
    
    public init(contractAddress: SCAddressXDR, functionName: String, args: [SCValXDR]) {
        self.contractAddress = contractAddress
        self.functionName = functionName
        self.args = args
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractAddress = try container.decode(SCAddressXDR.self)
        functionName = try container.decode(String.self)
        args =  try decodeArray(type: SCValXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(contractAddress)
        try container.encode(functionName)
        try container.encode(args)
    }
}

public enum SorobanAuthorizedFunctionXDR: XDRCodable {
    case contractFn(SorobanAuthorizedContractFunctionXDR)
    case contractHostFn(CreateContractArgsXDR)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SorobanAuthorizedFunctionType(rawValue: discriminant)!
        
        switch type {
        case .contractFn:
            let contractFn = try container.decode(SorobanAuthorizedContractFunctionXDR.self)
            self = .contractFn(contractFn)
        case .contractHostFn:
            let contractHostFn = try container.decode(CreateContractArgsXDR.self)
            self = .contractHostFn(contractHostFn)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .contractFn: return SorobanAuthorizedFunctionType.contractFn.rawValue
        case .contractHostFn: return SorobanAuthorizedFunctionType.contractHostFn.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .contractFn(let val):
            try container.encode(val)
            break
        case .contractHostFn(let val):
            try container.encode(val)
            break
        }
    }
    
    public var contractFn:SorobanAuthorizedContractFunctionXDR? {
        switch self {
        case .contractFn(let val):
            return val
        default:
            return nil
        }
    }
    
    public var contractHostFn:CreateContractArgsXDR? {
        switch self {
        case .contractHostFn(let val):
            return val
        default:
            return nil
        }
    }
}

public struct SorobanAuthorizedInvocationXDR: XDRCodable {
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

public struct SorobanAddressCredentialsXDR: XDRCodable {
    public var address: SCAddressXDR
    public var nonce: Int64
    public var signatureExpirationLedger: UInt32
    public var signatureArgs: [SCValXDR]
    
    public init(address: SCAddressXDR, nonce: Int64, signatureExpirationLedger: UInt32, signatureArgs: [SCValXDR]) {
        self.address = address
        self.nonce = nonce
        self.signatureExpirationLedger = signatureExpirationLedger
        self.signatureArgs = signatureArgs
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        address = try container.decode(SCAddressXDR.self)
        nonce = try container.decode(Int64.self)
        signatureExpirationLedger = try container.decode(UInt32.self)
        signatureArgs =  try decodeArray(type: SCValXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(nonce)
        try container.encode(signatureExpirationLedger)
        try container.encode(signatureArgs)
    }
    
    public mutating func appendSignature(signature: SCValXDR) {
        signatureArgs.append(signature)
    }
}

public enum SorobanCredentialsType: Int32 {
    case sourceAccount = 0
    case address = 1
}

public enum SorobanCredentialsXDR: XDRCodable {
    case sourceAccount
    case address(SorobanAddressCredentialsXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SorobanCredentialsType(rawValue: discriminant)!
        
        switch type {
        case .sourceAccount:
            self = .sourceAccount
        case .address:
            let address = try container.decode(SorobanAddressCredentialsXDR.self)
            self = .address(address)
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

public struct SorobanAuthorizationEntryXDR: XDRCodable {
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
        let payload = Data(bytes: encoded, count: encoded.count).sha256()
        let signature = signer.sign([UInt8](payload))
        let accountEd25519Signature = AccountEd25519Signature(publicKey: signer.publicKey, signature: signature)
        let sigVal = SCValXDR(accountEd25519Signature: accountEd25519Signature)
        var address = credentials.address!
        address.appendSignature(signature: sigVal)
        self.credentials = SorobanCredentialsXDR.address(address)
    }
}

public class AccountEd25519Signature {
    
    public let publicKey:PublicKey
    public let signature:[UInt8]
    
    public init(publicKey:PublicKey, signature:[UInt8]) {
        self.publicKey = publicKey
        self.signature = signature
    }
}


public struct LedgerFootprintXDR: XDRCodable {
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

public struct InvokeHostFunctionSuccessPreImageXDR: XDRCodable {
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

public struct SorobanResourcesXDR: XDRCodable {
    public var footprint: LedgerFootprintXDR;
    public var instructions: UInt32
    public var readBytes: UInt32
    public var writeBytes: UInt32
    public var extendedMetaDataSizeBytes: UInt32
    
    public init(footprint: LedgerFootprintXDR, instructions: UInt32 = 0, readBytes: UInt32 = 0, writeBytes: UInt32 = 0, extendedMetaDataSizeBytes: UInt32 = 0) {
        self.footprint = footprint
        self.instructions = instructions
        self.readBytes = readBytes
        self.writeBytes = writeBytes
        self.extendedMetaDataSizeBytes = extendedMetaDataSizeBytes
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        footprint = try container.decode(LedgerFootprintXDR.self)
        instructions = try container.decode(UInt32.self)
        readBytes = try container.decode(UInt32.self)
        writeBytes = try container.decode(UInt32.self)
        extendedMetaDataSizeBytes = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(footprint)
        try container.encode(instructions)
        try container.encode(readBytes)
        try container.encode(writeBytes)
        try container.encode(extendedMetaDataSizeBytes)
    }
}

public struct SorobanTransactionDataXDR: XDRCodable {
    public var ext: ExtensionPoint
    public var resources: SorobanResourcesXDR;
    public var refundableFee: Int64

    public init(ext: ExtensionPoint = ExtensionPoint.void, resources: SorobanResourcesXDR, refundableFee: Int64 = 0) {
        self.ext = ext
        self.resources = resources
        self.refundableFee = refundableFee
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        resources = try container.decode(SorobanResourcesXDR.self)
        refundableFee = try container.decode(Int64.self)
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanTransactionDataXDR(from: xdrDecoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(resources)
        try container.encode(refundableFee)
    }
}

public enum TransactionExtXDR : XDRCodable {
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
    
    private func type() -> Int32 {
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
