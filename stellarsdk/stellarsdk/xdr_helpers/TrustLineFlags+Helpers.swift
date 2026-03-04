// Backward-compatible bitmask constants for TrustLineFlags.
// Previously TrustLineFlags was a struct-with-constants; now it is an auto-generated enum.
// These UInt32 constants preserve bitmask OR operations.

import Foundation

extension TrustLineFlags {
    public static let AUTHORIZED_FLAG: UInt32 = UInt32(TrustLineFlags.authorizedFlag.rawValue)
    public static let AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG: UInt32 = UInt32(TrustLineFlags.authorizedToMaintainLiabilitiesFlag.rawValue)
    public static let TRUSTLINE_CLAWBACK_ENABLED_FLAG: UInt32 = UInt32(TrustLineFlags.trustlineClawbackEnabledFlag.rawValue)
}
