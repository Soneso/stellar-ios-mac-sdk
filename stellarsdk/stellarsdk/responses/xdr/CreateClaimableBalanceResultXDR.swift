//
//  CreateClaimableBalanceResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum CreateClaimableBalanceResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1
    case lowReserve = -2
    case noTrust = -3
    case notAUthorized = -4
    case underfunded = -5
}

public enum CreateClaimableBalanceResultXDR: XDRCodable {
    case success (Int32, ClaimableBalanceIDXDR)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = CreateClaimableBalanceResultCode(rawValue: discriminant)!
        
        switch code {
            case .success:
                let value = try container.decode(ClaimableBalanceIDXDR.self)
                self = .success(code.rawValue, value)
            default:
                self = .empty(code.rawValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
            case .success(let code, let balance):
                try container.encode(code)
                try container.encode(balance)
            case .empty (let code):
                try container.encode(code)
                break
        }
    }
}
