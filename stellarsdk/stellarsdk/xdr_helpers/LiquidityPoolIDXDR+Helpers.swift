import Foundation

extension LiquidityPoolIDXDR {
    public init(id: WrappedData32) {
        self.init(liquidityPoolID: id)
    }

    public var poolIDString: String {
        return liquidityPoolID.wrapped.base16EncodedString()
    }
}
