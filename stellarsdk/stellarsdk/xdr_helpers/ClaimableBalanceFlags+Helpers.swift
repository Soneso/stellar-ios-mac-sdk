// Backward-compatible bitmask constants for ClaimableBalanceFlags.
// Previously ClaimableBalanceFlags was a struct-with-constants; now it is an auto-generated enum.
// These UInt32 constants preserve bitmask OR operations.

import Foundation

extension ClaimableBalanceFlags {
    public static let CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG: UInt32 = UInt32(ClaimableBalanceFlags.claimableBalanceClawbackEnabledFlag.rawValue)
}
