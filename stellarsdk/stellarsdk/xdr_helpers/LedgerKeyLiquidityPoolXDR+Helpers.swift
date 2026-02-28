import Foundation

extension LedgerKeyLiquidityPoolXDR {
    public var poolIDString: String {
        return liquidityPoolID.wrapped.base16EncodedString()
    }
}
