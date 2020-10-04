//
//  ClaimClaimableBalanceResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum ClaimClaimableBalanceResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case doesNotExist = -1
    case cannotClaim = -2
    case lineFill = -3
    case noTrust = -4
    case notAUthorized = -5
}

public enum ClaimClaimableBalanceResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = ClaimClaimableBalanceResultCode(rawValue: discriminant)!
        
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
