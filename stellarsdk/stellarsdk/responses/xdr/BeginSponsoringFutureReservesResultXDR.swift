//
//  BeginSponsoringFutureReservesResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum BeginSponsoringFutureReservesResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
     // codes considered as "failure" for the operation
    case malformed = -1 // can't sponsor self
    case alreadySponsored = -2 // can't sponsor an account that is already sponsored
    case recursive = -3 // can't sponsor an account that is itself sponsoring an account
}

public enum BeginSponsoringFutureReservesResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = BeginSponsoringFutureReservesResultCode(rawValue: discriminant)!
        
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
