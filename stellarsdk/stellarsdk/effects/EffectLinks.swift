//
//  EffectLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Represents the links connected to an effect response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/effects-all.html "Effect")
public class EffectLinks: NSObject, Codable {
    
    /// Link to the operation that created the effect.
    public var operation:Link
    
    /// Link to the next effect.
    public var precedes:Link
    
    /// Link to the previous effect.
    public var succeeds:Link
    
    
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
        operation = try values.decode(Link.self, forKey: .operation)
        precedes = try values.decode(Link.self, forKey: .precedes)
        succeeds = try values.decode(Link.self, forKey: .succeeds)
    }
    
    /**
     Encodes this value into the given encoder.
     
     - Parameter encoder: The encoder to receive the data
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(operation, forKey: .operation)
        try container.encode(precedes, forKey: .precedes)
        try container.encode(succeeds, forKey: .succeeds)
    }
}
