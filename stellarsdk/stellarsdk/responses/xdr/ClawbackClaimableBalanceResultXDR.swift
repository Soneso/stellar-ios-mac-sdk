//
//  ClawbackClaimableBalanceResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum ClawbackClaimableBalanceResultCode: Int32, Sendable {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case doesNotExist = -1
    case notIssuer = -2
    case notClawbackEnabled = -3
}

public enum ClawbackClaimableBalanceResultXDR: XDRCodable, Sendable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = ClawbackClaimableBalanceResultCode(rawValue: discriminant)!
        
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

