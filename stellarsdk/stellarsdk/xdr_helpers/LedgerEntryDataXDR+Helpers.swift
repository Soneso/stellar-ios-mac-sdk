import Foundation

extension LedgerEntryDataXDR {
    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try LedgerEntryDataXDR(from: xdrDecoder)
    }

    public var isBool: Bool {
        return type() == SCValType.bool.rawValue
    }

    public var account: AccountEntryXDR? {
        switch self {
        case .account(let val):
            return val
        default:
            return nil
        }
    }

    public var trustline: TrustlineEntryXDR? {
        switch self {
        case .trustline(let val):
            return val
        default:
            return nil
        }
    }

    public var offer: OfferEntryXDR? {
        switch self {
        case .offer(let val):
            return val
        default:
            return nil
        }
    }

    public var data: DataEntryXDR? {
        switch self {
        case .data(let val):
            return val
        default:
            return nil
        }
    }

    public var claimableBalance: ClaimableBalanceEntryXDR? {
        switch self {
        case .claimableBalance(let val):
            return val
        default:
            return nil
        }
    }

    public var liquidityPool: LiquidityPoolEntryXDR? {
        switch self {
        case .liquidityPool(let val):
            return val
        default:
            return nil
        }
    }

    public var contractData: ContractDataEntryXDR? {
        switch self {
        case .contractData(let val):
            return val
        default:
            return nil
        }
    }

    public var contractCode: ContractCodeEntryXDR? {
        switch self {
        case .contractCode(let val):
            return val
        default:
            return nil
        }
    }

    public var configSetting: ConfigSettingEntryXDR? {
        switch self {
        case .configSetting(let val):
            return val
        default:
            return nil
        }
    }

    public var ttl: TTLEntryXDR? {
        switch self {
        case .ttl(let val):
            return val
        default:
            return nil
        }
    }
}
