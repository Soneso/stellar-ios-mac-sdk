import Foundation

extension LiquidityPoolWithdrawOpXDR {
    /// Creates a withdraw operation for an "L..." strkey pool id or for the 64 character hex
    /// of the 32 byte id.
    ///
    /// - Throws: KeyUtilsError if an "L..." strkey is malformed,
    /// StellarSDKError.invalidArgument if a hex id is not exactly 64 hexadecimal characters
    public init(liquidityPoolId: String, amount: Int64, minAmountA: Int64, minAmountB: Int64) throws {
        var liquidityPoolIdHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L") {
            liquidityPoolIdHex = try liquidityPoolId.decodeLiquidityPoolIdToHex()
        }
        self.init(liquidityPoolID: try liquidityPoolIdHex.wrappedData32FromHex(idKind: "liquidity pool id"),
                  amount: amount,
                  minAmountA: minAmountA,
                  minAmountB: minAmountB)
    }
}
