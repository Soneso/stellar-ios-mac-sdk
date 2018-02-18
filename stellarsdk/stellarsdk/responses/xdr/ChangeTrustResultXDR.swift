//
//  ChangeTrustResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ChangeTrustResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case trustMalformed = -1 // bad input
    case noIssuer = -2 // could not find issuer
    case trustInvalidLimit = -3 // cannot drop limit below balance
    case changeTrustLowReserve = -4 // not enough funds to create a new trust line
    case changeTrustSelfNotAllowed = -5 // trusting self is not allowed
}

public enum ChangeTrustResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = ChangeTrustResultCode(rawValue: discriminant)!
        
        switch code {
        case .success:
            self = .success (code.rawValue)
        default:
            self = .empty (code.rawValue)
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
