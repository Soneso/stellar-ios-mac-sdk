// Backward-compatible static constants for AssetType.
// Previously AssetType was a struct-with-constants; now it is an auto-generated enum.

import Foundation

extension AssetType {
    public static let ASSET_TYPE_NATIVE: Int32 = AssetType.native.rawValue
    public static let ASSET_TYPE_CREDIT_ALPHANUM4: Int32 = AssetType.creditAlphanum4.rawValue
    public static let ASSET_TYPE_CREDIT_ALPHANUM12: Int32 = AssetType.creditAlphanum12.rawValue
    public static let ASSET_TYPE_POOL_SHARE: Int32 = AssetType.poolShare.rawValue
}
