//
//  ManageOfferResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ManageOfferResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1 // generated offer would be invalid
    case sellNoTrust = -2 // no trust line for what we're selling
    case buyNoTrust = -3 // no trust line for what we're buying
    case sellNotAuthorized = -4 // not authorized to sell
    case buyNotAuthorized = -5 // not authorized to buy
    case lineFull = -6 // can't receive more of what it's buying
    case underfunded = -7 // doesn't hold what it's trying to sell
    case crossSelf = -8 // would cross an offer from the same user
    case sellNoIssuer = -9 // no issuer for what we're selling
    case buyNoIssuer = -10 // no issuer for what we're buying
    
    // update errors
    case notFound = -11 // offerID does not match an existing offer
    case lowReserve = -12 // not enough funds to create a new Offer
}

public enum ManageOfferResultXDR: XDRCodable {
    case success(Int32, ManageOfferSuccessResultXDR)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = ManageOfferResultCode(rawValue: discriminant)!
        
        switch code {
            case .success:
                let result = try container.decode(ManageOfferSuccessResultXDR.self)
                self = .success(code.rawValue, result)
            default:
                self = .empty(code.rawValue)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
            case .success(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .empty(let code):
                try container.encode(code)
                break
        }
    }
}
