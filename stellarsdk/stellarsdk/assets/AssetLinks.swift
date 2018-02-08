//
//  AssetLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Represents the links connected to an asset response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/asset.html "Asset")
public class AssetLinks: NSObject, Codable {
    
    /// Link to the TOML file for this issuer.
    public var toml:Link
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case toml
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        toml = try values.decode(Link.self, forKey: .toml)
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toml, forKey: .toml)
    }
}
