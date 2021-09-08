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
