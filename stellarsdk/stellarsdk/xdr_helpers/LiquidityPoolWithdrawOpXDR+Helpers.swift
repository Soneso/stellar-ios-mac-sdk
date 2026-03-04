import Foundation

extension LiquidityPoolWithdrawOpXDR {
    public init(liquidityPoolId: String, amount: Int64, minAmountA: Int64, minAmountB: Int64) throws {
        var liquidityPoolIdHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L") {
            liquidityPoolIdHex = try liquidityPoolId.decodeLiquidityPoolIdToHex()
        }
        if let _ = liquidityPoolIdHex.data(using: .hexadecimal) {
            self.init(liquidityPoolID: liquidityPoolIdHex.wrappedData32FromHex(),
                      amount: amount,
                      minAmountA: minAmountA,
                      minAmountB: minAmountB)
        } else {
            throw StellarSDKError.encodingError(message: "error creating LiquidityPoolWithdrawOpXDR, invalid liquidity pool id")
        }
    }
}
