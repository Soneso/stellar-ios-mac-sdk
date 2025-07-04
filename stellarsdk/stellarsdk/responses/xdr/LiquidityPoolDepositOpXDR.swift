//
//  LiquidityPoolDepositOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation


public struct LiquidityPoolDepositOpXDR: XDRCodable {
    public let liquidityPoolID:WrappedData32
    public let maxAmountA: Int64
    public let maxAmountB: Int64
    public let minPrice: PriceXDR
    public let maxPrice: PriceXDR
    
    public init(liquidityPoolID:WrappedData32, maxAmountA: Int64, maxAmountB: Int64, minPrice: PriceXDR, maxPrice: PriceXDR) {
        self.liquidityPoolID = liquidityPoolID
        self.maxAmountA = maxAmountA
        self.maxAmountB = maxAmountB
        self.minPrice = minPrice
        self.maxPrice = maxPrice
    }
    
    public init(liquidityPoolId:String, maxAmountA: Int64, maxAmountB: Int64, minPrice: PriceXDR, maxPrice: PriceXDR) throws {
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

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liquidityPoolID = try container.decode(WrappedData32.self)
        maxAmountA = try container.decode(Int64.self)
        maxAmountB = try container.decode(Int64.self)
        minPrice = try container.decode(PriceXDR.self)
        maxPrice = try container.decode(PriceXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
        try container.encode(maxAmountA)
        try container.encode(maxAmountB)
        try container.encode(minPrice)
        try container.encode(maxPrice)
    }
}
