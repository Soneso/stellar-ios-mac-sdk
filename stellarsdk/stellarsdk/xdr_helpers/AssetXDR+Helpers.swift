import Foundation

extension AssetXDR {
    public var assetCode: String {
        switch self {
        case .native:
            return "native"
        case .alphanum4(let a4):
            return a4.assetCodeString
        case .alphanum12(let a12):
            return a12.assetCodeString
        }
    }

    public var issuer: PublicKey? {
        switch self {
        case .native:
            return nil
        case .alphanum4(let a4):
            return a4.issuer
        case .alphanum12(let a12):
            return a12.issuer
        }
    }

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
}
