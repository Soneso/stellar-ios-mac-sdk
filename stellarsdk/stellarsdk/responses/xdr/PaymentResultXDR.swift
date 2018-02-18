//
//  PaymentResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum PaymentResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // payment successfuly completed
    
    // codes considered as "failure" for the operation
    case malformed = -1  // bad input
    case underfunded = -2 // not enough funds in source account
    case srcNoTrust = -3 // no trust line on source account
    case srcNotAuthorized = -4 // source not authorized to transfer
    case noDestination = -5 // destination account does not exist
    case noTrust = -6 // destination missing a trust line for asset
    case notAuthorized = -7 // destination not authorized to hold asset
    case lineFull = -8 // destination would go above their limit
    case noIssuer = -9 // missing issuer on asset
}

public enum PaymentResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = PaymentResultCode(rawValue: discriminant)!
        
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
