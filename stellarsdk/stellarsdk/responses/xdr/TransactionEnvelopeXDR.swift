//
//  TransactionEnvelopeXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct EnvelopeType {
    static let ENVELOPE_TYPE_TX_V0: Int32 = 0
    static let ENVELOPE_TYPE_SCP: Int32 = 1
    static let ENVELOPE_TYPE_TX: Int32 = 2
    static let ENVELOPE_TYPE_AUTH: Int32 = 3
    static let ENVELOPE_TYPE_SCPVALUE: Int32 = 4
    static let ENVELOPE_TYPE_TX_FEE_BUMP: Int32 = 5
}

public enum TransactionEnvelopeXDR: XDRCodable {
    case v0 (TransactionV0EnvelopeXDR)
    case v1 (TransactionV1EnvelopeXDR)
    case feeBump (FeeBumpTransactionEnvelopeXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case EnvelopeType.ENVELOPE_TYPE_TX:
            let tev1 = try container.decode(TransactionV1EnvelopeXDR.self)
            self = .v1(tev1)
        case EnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
            let tevf = try container.decode(FeeBumpTransactionEnvelopeXDR.self)
            self = .feeBump(tevf)
        default:
            let tev0 = try container.decode(TransactionV0EnvelopeXDR.self)
            self = .v0(tev0)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .v0: return EnvelopeType.ENVELOPE_TYPE_TX_V0
        case .v1: return EnvelopeType.ENVELOPE_TYPE_TX
        case .feeBump: return EnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .v0(let tev0): try container.encode(tev0)
        case .v1(let tev1): try container.encode(tev1)
        case .feeBump(let tevf): try container.encode(tevf)
        }
    }
    
    public var txSourceAccountId: String {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.txSourceAccountId
            case .v1(let tev1):
                return tev1.txSourceAccountId
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                   return tev1.txSourceAccountId
                }
            }
        }
    }
    
    public var txSeqNum: Int64 {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.tx.seqNum
            case .v1(let tev1):
                return tev1.tx.seqNum
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.seqNum
                }
            }
        }
    }
    
    public var txTimeBounds: TimeBoundsXDR? {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.tx.timeBounds
            case .v1(let tev1):
                return tev1.tx.timeBounds
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.timeBounds
                }
            }
        }
    }
    
    public var txFee: UInt32 {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.tx.fee
            case .v1(let tev1):
                return tev1.tx.fee
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.fee
                }
            }
        }
    }
    
    public var txMemo: MemoXDR {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.tx.memo
            case .v1(let tev1):
                return tev1.tx.memo
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.memo
                }
            }
        }
    }
    
    public var txOperations: [OperationXDR] {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.tx.operations
            case .v1(let tev1):
                return tev1.tx.operations
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.operations
                }
            }
        }
    }
    
    public var txSignatures: [DecoratedSignatureXDR] {
        get {
            switch self {
            case .v0(let tev0):
                return tev0.signatures
            case .v1(let tev1):
                return tev1.signatures
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.signatures
                }
            }
        }
    }
    
    public func txHash(network:Network) throws -> Data {
        switch self {
        case .v0(let tev0):
            return try tev0.tx.hash(network: network)
        case .v1(let tev1):
            return try tev1.tx.hash(network: network)
        case .feeBump(let tevf):
            switch tevf.tx.innerTx {
            case .v1(let tev1):
                return try tev1.tx.hash(network: network)
            }
        }
    }
    
    public func appendSignature(signature:DecoratedSignatureXDR) {
        switch self {
        case .v0(let tev0):
            tev0.signatures.append(signature)
        case .v1(let tev1):
            tev1.signatures.append(signature)
        case .feeBump(let tevf):
            switch tevf.tx.innerTx {
            case .v1(let tev1):
                tev1.signatures.append(signature)
            }
        }
    }
}

/*public enum EnvelopeType: Int32 {
    case typeSCP = 1
    case typeTX = 2
    case typeAUTH = 3
}

public class TransactionEnvelopeXDR: NSObject, XDRCodable {
    public let tx: TransactionXDR
    public var signatures: [DecoratedSignatureXDR]
    
    public init(tx: TransactionXDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(TransactionXDR.self)
        signatures = try decodeArray(type: DecoratedSignatureXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(tx)
        try container.encode(signatures)
    }
    
}*/

