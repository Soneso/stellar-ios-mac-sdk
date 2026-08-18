import Foundation

extension TrustlineAssetXDR {
    public init(assetCode: String, issuer: KeyPair) throws {
        if assetCode.count <= 4 {
            let a4 = try Alpha4XDR(assetCodeString: assetCode, issuer: issuer)
            self = .alphanum4(a4)
            return
        }
        else if assetCode.count <= 12 {
            let a12 = try Alpha12XDR(assetCodeString: assetCode, issuer: issuer)
            self = .alphanum12(a12)
            return
        }

        throw StellarSDKError.invalidArgument(message: "Invalid asset type")
    }

    /// Creates a pool share trustline asset from the 64 character hex of the 32 byte pool id.
    ///
    /// - Throws: StellarSDKError.invalidArgument if the id is not exactly 64 hexadecimal characters
    public init(poolId: String) throws {
        self = .poolShare(try poolId.wrappedData32FromHex(idKind: "liquidity pool id"))
    }

    public var assetCode: String? {
        switch self {
            case .native:
                return "native"
            case .alphanum4(let a4):
                return a4.assetCodeString
            case .alphanum12(let a12):
                return a12.assetCodeString
            default:
                return nil
        }
    }

    public var issuer: PublicKey? {
        switch self {
        case .alphanum4(let a4):
            return a4.issuer
        case .alphanum12(let a12):
            return a12.issuer
        default:
            return nil
        }
    }

    public var poolId: String? {
        switch self {
        case .poolShare(let data):
            return data.wrapped.base16EncodedString()
        default:
            return nil
        }
    }
}
