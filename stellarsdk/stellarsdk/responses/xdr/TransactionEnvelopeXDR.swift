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
    static let ENVELOPE_TYPE_OP_ID: Int32 = 6
    static let ENVELOPE_TYPE_POOL_REVOKE_OP_ID: Int32 = 7
    static let ENVELOPE_TYPE_CONTRACT_ID: Int32 = 8
    static let ENVELOPE_TYPE_SOROBAN_AUTHORIZATION: Int32 = 9
}

public enum TransactionEnvelopeXDR: XDRCodable, Sendable {
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
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try TransactionEnvelopeXDR(from: xdrDecoder)
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
    
    public var txMuxedSourceId: UInt64? {
        get {
            switch self {
            case .v0(_):
                return nil
            case .v1(let tev1):
                return tev1.tx.sourceAccount.id
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.sourceAccount.id
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
                let cond = tev1.tx.cond
                switch cond {
                case .time(let timeBoundsXDR):
                    return timeBoundsXDR
                default:
                    return nil
                }
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    let cond = tev1.tx.cond
                    switch cond {
                    case .time(let timeBoundsXDR):
                        return timeBoundsXDR
                    default:
                        return nil
                    }
                }
            }
        }
    }
    
    public var cond: PreconditionsXDR {
        get {
            switch self {
            case .v0(let tev0):
                var cond = PreconditionsXDR.none
                if let tb = tev0.tx.timeBounds {
                    cond = PreconditionsXDR.time(tb)
                }
                return cond
            case .v1(let tev1):
                return tev1.tx.cond
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.cond
                }
            }
        }
    }
    
    public var sorobanTransactionData: SorobanTransactionDataXDR? {
        get {
            switch self {
            case .v1(let tev1):
                switch tev1.tx.ext {
                case.sorobanTransactionData(let data):
                    return data
                default:
                    return nil
                }
            default:
                return nil
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
    
    public var txExt: TransactionExtXDR? {
        get {
            switch self {
            case .v0(_):
                return nil
            case .v1(let tev1):
                return tev1.tx.ext
            case .feeBump(let tevf):
                switch tevf.tx.innerTx {
                case .v1(let tev1):
                    return tev1.tx.ext
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

