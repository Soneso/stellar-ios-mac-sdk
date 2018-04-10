//
//  ManageOfferSuccessResult.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 15.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ManageOfferEffect: Int32 {
    case created = 0
    case updated = 1
    case deleted = 2
}

public enum ManageOfferSuccessResultOfferXDR: Encodable {
    case created(OfferEntryXDR)
    case updated
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .created(let offer):
            var container = encoder.unkeyedContainer()
            try container.encode(offer)
        default:
            break
        }
    }
}

public struct ManageOfferSuccessResultXDR: XDRCodable {
    public var offersClaimed:[ClaimOfferAtomXDR]
    public var offer:ManageOfferSuccessResultOfferXDR?
    
    public init(offersClaimed: [ClaimOfferAtomXDR], offer:ManageOfferSuccessResultOfferXDR?) {
        self.offersClaimed = offersClaimed
        self.offer = offer
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        offersClaimed = try decodeArray(type: ClaimOfferAtomXDR.self, dec: decoder)
        let discriminant = try container.decode(Int32.self)
        let type = ManageOfferEffect(rawValue: discriminant)!
        switch type {
        case .created:
            fallthrough
        case .updated:
            offer = .created(try container.decode(OfferEntryXDR.self))
        default:
            break
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(offersClaimed)
        try container.encode(offer)
    }

}
