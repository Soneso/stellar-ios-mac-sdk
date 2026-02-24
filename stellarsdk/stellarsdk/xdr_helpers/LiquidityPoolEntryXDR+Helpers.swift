import Foundation

extension LiquidityPoolEntryXDR {
    public var poolIDString: String {
        return liquidityPoolID.wrapped.base16EncodedString()
    }
}
