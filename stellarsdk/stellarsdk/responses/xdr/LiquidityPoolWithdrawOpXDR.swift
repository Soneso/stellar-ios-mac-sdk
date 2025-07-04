//
//  LiquidityPoolWithdrawOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public struct LiquidityPoolWithdrawOpXDR: XDRCodable {
    public let liquidityPoolID:WrappedData32
    public let amount: Int64
    public let minAmountA: Int64
    public let minAmountB: Int64

    public init(liquidityPoolID:WrappedData32, amount: Int64, minAmountA: Int64, minAmountB: Int64) {
        self.liquidityPoolID = liquidityPoolID
        self.amount = amount
        self.minAmountA = minAmountA
        self.minAmountB = minAmountB
    }
    
    public init(liquidityPoolId:String,  amount: Int64, minAmountA: Int64, minAmountB: Int64) throws {
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

    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liquidityPoolID = try container.decode(WrappedData32.self)
        amount = try container.decode(Int64.self)
        minAmountA = try container.decode(Int64.self)
        minAmountB = try container.decode(Int64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
        try container.encode(amount)
        try container.encode(minAmountA)
        try container.encode(minAmountB)
    }
}
