//
//  LiquidityPoolDepositOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolDepositOperation:Operation {
    
    public let liquidityPoolId:String
    public let maxAmountA:Decimal
    public let maxAmountB:Decimal
    public let minPrice:Price
    public let maxPrice:Price

    /// Creates a new LiquidityPoolDepositOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "M" or "G" and must be valid, otherwise it will be ignored.
    /// - Parameter liquidityPoolId: The liquidity pool ID
    /// - Parameter maxAmountA: Maximum amount of first asset to deposit.
    /// - Parameter maxAmountB: Maximum amount of second asset to deposit.
    /// - Parameter minPrice:Minimum depositA/depositB price.
    /// - Parameter maxPrice:Maximum depositA/depositB price.
    ///
    public init(sourceAccountId:String?, liquidityPoolId:String, maxAmountA:Decimal, maxAmountB:Decimal, minPrice:Price, maxPrice:Price) {
        self.liquidityPoolId = liquidityPoolId
        self.maxAmountA = maxAmountA
        self.maxAmountB = maxAmountB
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new LiquidityPoolDepositOperation object from the given LiquidityPoolDepositOperationXDR object.
    ///
    /// - Parameter fromXDR: the LiquidityPoolDepositOperationXDR object to be used to create a new LiquidityPoolDepositOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:LiquidityPoolDepositOpXDR, sourceAccountId:String?) {
        
        self.liquidityPoolId = fromXDR.liquidityPoolID.wrapped.hexEncodedString()
        self.maxAmountA = Operation.fromXDRAmount(fromXDR.maxAmountA)
        self.maxAmountB = Operation.fromXDRAmount(fromXDR.maxAmountB)
        
        self.minPrice = Price(numerator: fromXDR.minPrice.n, denominator: fromXDR.minPrice.d)
        self.maxPrice = Price(numerator: fromXDR.maxPrice.n, denominator: fromXDR.maxPrice.d)
        
        
        
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let maxAmountAXDR = Operation.toXDRAmount(amount: maxAmountA)
        let maxAmountBXDR = Operation.toXDRAmount(amount: maxAmountB)
        return try OperationBodyXDR.liquidityPoolDeposit(
            LiquidityPoolDepositOpXDR(liquidityPoolId:liquidityPoolId,
                                      maxAmountA: maxAmountAXDR,
                                      maxAmountB: maxAmountBXDR,
                                      minPrice: minPrice.toXdr(),
                                      maxPrice: maxPrice.toXdr()))
    }
}
