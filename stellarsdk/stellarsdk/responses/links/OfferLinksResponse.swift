//
//  OfferLinksResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for offer-related resources.
///
/// Provides hypermedia links to resources associated with an offer, including
/// the offer itself and the account that created the offer.
///
/// See also:
/// - [Offer Links](https://developers.stellar.org/api/horizon/reference/resources/offer)
/// - OfferResponse for complete offer details
/// - LinkResponse for individual link structure
public class OfferLinksResponse: NSObject, Decodable {

    /// Link to this offer resource (self reference).
    public var selflink:LinkResponse

    /// Link to the account that created this offer (offer maker).
    public var seller:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case seller = "offer_maker"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        seller = try values.decode(LinkResponse.self, forKey: .seller)
    }
}

