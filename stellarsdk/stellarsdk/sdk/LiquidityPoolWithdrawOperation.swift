//
//  LiquidityPoolWithdrawOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolWithdrawOperation:Operation {
    
    public let liquidityPoolId:String
    public let amount: Decimal
    public let minAmountA: Decimal
    public let minAmountB: Decimal

    /// Creates a new LiquidityPoolDepositOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "M" or "G" and must be valid, otherwise it will be ignored.
    /// - Parameter liquidityPoolId: The liquidity pool ID
    /// - Parameter amount: Amount of pool shares to withdraw.
    /// - Parameter minAmountA: Minimum amount of first asset to withdraw.
    /// - Parameter minAmountB: Minimum amount of second asset to withdraw.
    ///
    public init(sourceAccountId:String?, liquidityPoolId:String, amount:Decimal, minAmountA:Decimal, minAmountB:Decimal) {
        self.liquidityPoolId = liquidityPoolId
        self.amount = amount
        self.minAmountA = minAmountA
        self.minAmountB = minAmountB
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new LiquidityPoolWithdrawOperation object from the given LiquidityPoolWithdrawOpXDR object.
    ///
    /// - Parameter fromXDR: the LiquidityPoolWithdrawOpXDR object to be used to create a new LiquidityPoolWithdrawOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:LiquidityPoolWithdrawOpXDR, sourceAccountId:String?) {
        
        self.liquidityPoolId = fromXDR.liquidityPoolID.wrapped.hexEncodedString()
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        self.minAmountA = Operation.fromXDRAmount(fromXDR.minAmountA)
        self.minAmountB = Operation.fromXDRAmount(fromXDR.minAmountB)
        
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return try OperationBodyXDR.liquidityPoolWithdraw(
            LiquidityPoolWithdrawOpXDR(liquidityPoolId:liquidityPoolId,
                                       amount: Operation.toXDRAmount(amount:amount),
                                       minAmountA: Operation.toXDRAmount(amount:minAmountA),
                                       minAmountB: Operation.toXDRAmount(amount:minAmountB)))
    }
}
