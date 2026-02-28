import Foundation

extension SignerKeyXDR: Equatable {
    public static func ==(lhs: SignerKeyXDR, rhs: SignerKeyXDR) -> Bool {
        switch (lhs, rhs) {
        case let (.ed25519(l), .ed25519(r)): return l == r
        case let (.preAuthTx(l), .preAuthTx(r)): return l == r
        case let (.hashX(l), .hashX(r)): return l == r
        case let (.signedPayload(l), .signedPayload(r)): return l == r
        default: return false
        }
    }
}
