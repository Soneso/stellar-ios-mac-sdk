//
//  Price.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/15/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents Price. Price in Stellar is represented as a fraction.
public class Price {
    
    /// Numerator.
    public final let n:Int
    
    /// Denominator.
    public final let d:Int
    
    /// Create a new price. Price in Stellar is represented as a fraction. E.g. Price of 1 unit of selling in terms of buying. For example, if you wanted to sell 30 XLM and buy 5 BTC, the price would be {numerator, denominator} = {5,30}.
    ///
    /// - Parameter numerator: numerator
    /// - Parameter denominator: denominator
    ///
    public init(numerator:Int, denominator:Int) {
        self.n = numerator
        self.d = denominator
    }
    
    /// Approximates 'price' to a fraction. Please remember that this function can give unexpected results for values that cannot be represented as a fraction with 32-bit numerator and denominator. It's safer to create a Price object using the constructor.
    ///
    /// - Parameter price: E.g. "1.25"
    ///
    /// - Returns the created Price object.
    ///
    public static func fromString(price:String) -> Price {
        
        let maxInt:Decimal = Decimal(Int.max)
        guard var number = Decimal(string: price) else { return Price(numerator: 0, denominator: 0)}
        var a:Decimal = 0
        var f:Decimal
        var fractions = Array<[Decimal]>()
        fractions.append([Decimal(0), Decimal(1)])
        fractions.append([Decimal(1), Decimal(0)])
        var i:Int = 2
        while (true) {
            if number > maxInt { break }
            NSDecimalRound(&a, &number, 0, .plain)
            f = number - a
            let h:Decimal = a * fractions[i-1][0] + fractions[i-2][0]
            let k:Decimal = a * fractions[i-1][1] + fractions[i-2][1]
            if h > maxInt || k > maxInt { break }
            fractions.append([h,k])
            if f == 0 { break }
            number = 1/f
            i += 1
        }
        let n = NSDecimalNumber(decimal:fractions.last?.first ?? 0)
        let d = NSDecimalNumber(decimal:fractions.last?.last ?? 0)
        return Price(numerator: n.intValue, denominator: d.intValue)
    }
    
    
    /// Generates a PriceXDR object from the current Price object.
    ///
    /// - Returns the generated PriceXDR object.
    public func toXdr() -> PriceXDR {
        return PriceXDR(n: Int32(n), d: Int32(d))
    }
}

extension Price: Equatable {
    public static func == (lhs: Price, rhs: Price) -> Bool {
        return lhs.n == rhs.n && lhs.d == rhs.d
    }
}
