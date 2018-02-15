//
//  ManageOfferSuccessResult.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 15.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

enum ManageOfferEffect: Int {
    case created = 0
    case updated = 1
    case deleted = 2
}

enum ManageOfferSuccessResultOfferXDR {
    case created(OfferEntryXDR)
    case updated
}

struct ManageOfferSuccessResultXDR: XDRCodable {
    public var offersClaimed:[ClaimOfferAtomXDR]
    public var offer:ManageOfferSuccessResultOfferXDR?
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        offersClaimed = try container.decode(Array<ClaimOfferAtomXDR>.self)
        let type = ManageOfferEffect(rawValue: try container.decode(Int.self))!
        switch type {
        case .created:
            fallthrough
        case .updated:
            offer = .created(try container.decode(OfferEntryXDR.self))
        default:
            break
        }
        
        _ = try container.decode(Int.self)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(offersClaimed)
        try container.encode(offer)
    }

}
