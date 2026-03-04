import Foundation

extension TransactionEnvelopeXDR {

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try TransactionEnvelopeXDR(from: xdrDecoder)
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

    public func txHash(network: Network) throws -> Data {
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

    public func appendSignature(signature: DecoratedSignatureXDR) {
        switch self {
        case .v0(let tev0):
            tev0.appendSignature(signature)
        case .v1(let tev1):
            tev1.appendSignature(signature)
        case .feeBump(let tevf):
            switch tevf.tx.innerTx {
            case .v1(let tev1):
                tev1.appendSignature(signature)
            }
        }
    }
}
