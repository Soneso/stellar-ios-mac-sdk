import Foundation

extension LiquidityPoolParametersXDR {
    public init(params: LiquidityPoolConstantProductParametersXDR) {
        self = .constantProduct(params)
    }
}
