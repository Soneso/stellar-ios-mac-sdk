//
//  LiquidityPoolDepositResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum LiquidityPoolDepositResulCode: Int32, Sendable {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1 // bad input
    case noTrustLine = -2 // no trust line for one of the assets
    case notAuhorized = -3 // not authorized for one of the assets
    case underfunded = -4 // not enough balance for one of the assets
    case lineFull = -5 // pool share trust line doesn't have sufficient limit
    case badPrice = -6 // deposit price outside bounds
    case poolFull = -7 // pool reserves are full
}

public enum LiquidityPoolDepositResultXDR: XDRCodable, Sendable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = LiquidityPoolDepositResulCode(rawValue: discriminant)!
        
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
