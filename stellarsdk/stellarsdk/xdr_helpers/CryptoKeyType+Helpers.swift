// Backward-compatible static constants for CryptoKeyType.
// Previously CryptoKeyType was a struct-with-constants; now it is an auto-generated enum.

import Foundation

extension CryptoKeyType {
    public static let KEY_TYPE_ED25519: Int32 = CryptoKeyType.ed25519.rawValue
    public static let KEY_TYPE_PRE_AUTH_TX: Int32 = CryptoKeyType.preAuthTx.rawValue
    public static let KEY_TYPE_HASH_X: Int32 = CryptoKeyType.hashX.rawValue
    public static let KEY_TYPE_ED25519_SIGNED_PAYLOAD: Int32 = CryptoKeyType.ed25519SignedPayload.rawValue
    public static let KEY_TYPE_MUXED_ED25519: Int32 = CryptoKeyType.muxedEd25519.rawValue
}
