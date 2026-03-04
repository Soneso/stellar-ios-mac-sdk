import Foundation

extension Alpha12XDR {
    public init(assetCodeString: String, issuer: KeyPair) throws {
        guard var codeData = assetCodeString.data(using: .utf8),
              assetCodeString.count > 4,
              assetCodeString.count <= 12
        else {
            throw StellarSDKError.invalidArgument(message: "Invalid asset type")
        }

        let extraCount = 12 - assetCodeString.count
        codeData.append(contentsOf: Array<UInt8>(repeating: 0, count: extraCount))
        self.init(assetCode: WrappedData12(codeData), issuer: issuer.publicKey)
    }

    public var assetCodeString: String {
        return (String(bytes: assetCode.wrapped, encoding: .utf8) ?? "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
}
