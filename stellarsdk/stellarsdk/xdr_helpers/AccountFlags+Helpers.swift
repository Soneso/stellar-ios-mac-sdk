// Backward-compatible bitmask constants for AccountFlags.
// Previously AccountFlags was a struct-with-constants; now it is an auto-generated enum.
// These UInt32 constants preserve bitmask OR operations.

import Foundation

extension AccountFlags {
    public static let AUTH_REQUIRED_FLAG: UInt32 = UInt32(AccountFlags.requiredFlag.rawValue)
    public static let AUTH_REVOCABLE_FLAG: UInt32 = UInt32(AccountFlags.revocableFlag.rawValue)
    public static let AUTH_IMMUTABLE_FLAG: UInt32 = UInt32(AccountFlags.immutableFlag.rawValue)
    public static let AUTH_CLAWBACK_ENABLED_FLAG: UInt32 = UInt32(AccountFlags.clawbackEnabledFlag.rawValue)
}
