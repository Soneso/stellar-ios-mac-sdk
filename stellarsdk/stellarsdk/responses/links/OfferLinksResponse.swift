//
//  OfferLinksResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to an offer response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/offer.html "Offer")
public class OfferLinksResponse: NSObject, Decodable {
    
    /// Link to the current offer request URL of this offer.
    public var selflink:LinkResponse
    
    /// Link to details about the account that made this offer.
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

