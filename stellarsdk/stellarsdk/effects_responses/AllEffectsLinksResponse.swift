//
//  AllEffectsLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Represents the links connected to the all effects response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/effects-all.html "All Effects")
public class AllEffectsLinksResponse: NSObject, Codable {
    
    /// Link to the effects request URL.
    public var selflink:LinkResponse
    
    /// Link to the next "page" of the result.
    public var next:LinkResponse!
    
    /// Link to the previous "page" of the result.
    public var prev:LinkResponse!
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case next
        case prev
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        next = try values.decodeIfPresent(LinkResponse.self, forKey: .next)
        prev = try values.decodeIfPresent(LinkResponse.self, forKey: .prev)
    }
    
    /**
     Encodes this value into the given encoder.
     
     - Parameter encoder: The encoder to receive the data
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selflink, forKey: .selflink)
        try container.encode(prev, forKey: .prev)
        try container.encode(next, forKey: .next)
    }
}
