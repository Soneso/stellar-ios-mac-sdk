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

public struct SorobanResourcesXDR: XDRCodable {
    public var footprint: LedgerFootprintXDR;
    public var instructions: UInt32
    public var readBytes: UInt32
    public var writeBytes: UInt32
    public var extendedMetaDataSizeBytes: UInt32
    
    public init(footprint: LedgerFootprintXDR, instructions: UInt32, readBytes: UInt32, writeBytes: UInt32, extendedMetaDataSizeBytes: UInt32) {
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
    public var resources: SorobanResourcesXDR;
    public var refundableFee: Int64
    public let ext: ExtensionPoint
    
    internal init(resources: SorobanResourcesXDR, refundableFee: Int64, ext: ExtensionPoint) {
        self.resources = resources
        self.refundableFee = refundableFee
        self.ext = ext
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        resources = try container.decode(SorobanResourcesXDR.self)
        refundableFee = try container.decode(Int64.self)
        ext = try container.decode(ExtensionPoint.self)
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanTransactionDataXDR(from: xdrDecoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(resources)
        try container.encode(refundableFee)
        try container.encode(ext)
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
