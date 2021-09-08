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
