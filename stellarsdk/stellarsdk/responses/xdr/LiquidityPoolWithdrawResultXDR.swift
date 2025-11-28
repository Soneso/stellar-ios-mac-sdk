//
//  LiquidityPoolWithdrawResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum LiquidityPoolWithdrawResulCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1 // bad input
    case noTrustLine = -2 // no trust line for one of the assets
    case underfunded = -3 // not enough balance of the pool share
    case lineFull = -4 // would go above limit for one of the assets
    case underMinimum = -5 // didn't withdraw enough
}

public enum LiquidityPoolWithdrawResultXDR: XDRCodable, Sendable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = LiquidityPoolWithdrawResulCode(rawValue: discriminant)!
        
        switch code {
            case .success:
                self = .success(code.rawValue)
            default:
                self = .empty(code.rawValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
            case .success(let code):
                try container.encode(code)
            case .empty (let code):
                try container.encode(code)
                break
        }
    }
}
