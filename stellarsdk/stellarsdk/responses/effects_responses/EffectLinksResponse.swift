//
//  EffectLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to an effect response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
public class EffectLinksResponse: NSObject, Decodable {
    
    /// Link to the operation that created the effect.
    public var operation:LinkResponse
    
    /// Link to the next effect.
    public var precedes:LinkResponse
    
    /// Link to the previous effect.
    public var succeeds:LinkResponse
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case operation
        case precedes
        case succeeds
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        operation = try values.decode(LinkResponse.self, forKey: .operation)
        precedes = try values.decode(LinkResponse.self, forKey: .precedes)
        succeeds = try values.decode(LinkResponse.self, forKey: .succeeds)
    }
}
