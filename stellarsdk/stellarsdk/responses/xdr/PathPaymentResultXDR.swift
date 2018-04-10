//
//  PathPaymentResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum PathPaymentResultCode: Int32 {

    // codes considered as "success" for the operation
    case success = 0
    
    // codes considered as "failure" for the operation
    case malformed = -1 // bad input
    case underfounded = -2 // not enough funds in source account
    case srcNoTrust = -3 // no trust line on source account
    case srcNotAuthorized = -4 // source not authorized to transfer
    case noDestination = -5 // destination account does not exist
    case noTrust = -6 // dest missing a trust line for asset
    case notAuthorized = -7 // dest not authorized to hold asset
    case lineFull = -8 // dest would go above their limit
    case noIssuer = -9 // missing issuer on one asset
    case tooFewOffers = -10 // not enough offers to satisfy path
    case offerCrossSelf = -11 // would cross one of its own offers
    case overSendMax = -12 // could not satisfy sendmax
}

public enum PathPaymentResultXDR: XDRCodable {
    case success(Int32, [ClaimOfferAtomXDR], SimplePaymentResultXDR)
    case noIssuer(Int32, AssetXDR)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = PathPaymentResultCode(rawValue: discriminant)!
        
        switch code {
            case .success:
                let offers = try decodeArray(type: ClaimOfferAtomXDR.self, dec: decoder)
                let last = try container.decode(SimplePaymentResultXDR.self)
                self = .success(code.rawValue, offers, last)
            case .noIssuer:
                self = .noIssuer(code.rawValue, try container.decode(AssetXDR.self))
            default:
                self = .empty (code.rawValue)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
            case .success(let code, let offers, let last):
                try container.encode(code)
                try container.encode(offers)
                try container.encode(last)
            case .noIssuer(let code, let asset):
                try container.encode(code)
                try container.encode(asset)
            case .empty:
                break
        }
    }
}
