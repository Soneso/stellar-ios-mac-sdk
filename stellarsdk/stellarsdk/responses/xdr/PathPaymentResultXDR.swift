//
//  PathPaymentResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum PaymentPathResultCode: Int {
    case success = 0
    case malformed = -1
    case underfounded = -2
    case srcNoTrust = -3
    case srcNotAuthorized = -4
    case noDestination = -5
    case noTrust = -6
    case notAuthorized = -7
    case lineFull = -8
    case noIssuer = -9
}

enum PathPaymentResultXDR: XDRCodable {
    case success([ClaimOfferAtomXDR], SimplePaymentResultXDR)
    case noIssuer(AssetXDR)
    case empty
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = PaymentPathResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
        case .success:
            let offers = try container.decode([ClaimOfferAtomXDR].self)
            let last = try container.decode(SimplePaymentResultXDR.self)
            self = .success(offers, last)
        case .noIssuer:
            self = .noIssuer(try container.decode(AssetXDR.self))
        default:
            self = .empty
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
        case .success(let offers, let last):
            try container.encode(offers)
            try container.encode(last)
        case .noIssuer(let asset):
            try container.encode(asset)
        case .empty:
            break
        }
        
    }
    
}
