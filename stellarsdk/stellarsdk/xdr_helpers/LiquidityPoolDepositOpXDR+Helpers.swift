import Foundation

extension LiquidityPoolDepositOpXDR {
    public init(liquidityPoolId: String, maxAmountA: Int64, maxAmountB: Int64, minPrice: PriceXDR, maxPrice: PriceXDR) throws {
        var liquidityPoolIdHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L") {
            liquidityPoolIdHex = try liquidityPoolId.decodeLiquidityPoolIdToHex()
        }
        if let _ = liquidityPoolIdHex.data(using: .hexadecimal) {
            self.init(liquidityPoolID: liquidityPoolIdHex.wrappedData32FromHex(),
                      maxAmountA: maxAmountA,
                      maxAmountB: maxAmountB,
                      minPrice: minPrice,
                      maxPrice: maxPrice)
        } else {
            throw StellarSDKError.encodingError(message: "error creating LiquidityPoolDepositOpXDR, invalid liquidity pool id")
        }
    }
}
