import Foundation

extension AllowTrustOpAssetXDR {
    public var assetCode: String {
        switch self {
        case .alphanum4(let a4):
            return (String(bytes: a4.wrapped, encoding: .utf8) ?? "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        case .alphanum12(let a12):
            return (String(bytes: a12.wrapped, encoding: .utf8) ?? "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        }
    }
}
