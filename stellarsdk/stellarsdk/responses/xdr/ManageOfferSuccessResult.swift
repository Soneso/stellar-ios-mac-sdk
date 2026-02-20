//
//  ManageOfferSuccessResult.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 15.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ManageOfferEffect: Int32, Sendable {
    case created = 0
    case updated = 1
    case deleted = 2
}

public enum ManageOfferSuccessResultOfferXDR: XDREncodable, Sendable {
    case created(OfferEntryXDR)
    case updated

    public func effect() -> ManageOfferEffect {
        switch self {
        case .created(_): return .created
        case .updated: return .updated
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(effect().rawValue)

        switch self {
        case .created(let offer):
            try container.encode(offer)
        default:
            break
        }
    }
}

public struct ManageOfferSuccessResultXDR: XDRCodable, Sendable {
    public let offersClaimed: [ClaimAtomXDR]
    public var offer: ManageOfferSuccessResultOfferXDR?
    
    public init(offersClaimed: [ClaimAtomXDR], offer:ManageOfferSuccessResultOfferXDR?) {
        self.offersClaimed = offersClaimed
        self.offer = offer
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        offersClaimed = try decodeArray(type: ClaimAtomXDR.self, dec: decoder)
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
