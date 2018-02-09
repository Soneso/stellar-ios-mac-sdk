//
//  AssetLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to an asset response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/asset.html "Asset")
public class AssetLinksResponse: NSObject, Decodable {
    
    /// Link to the TOML file for this issuer.
    public var toml:LinkResponse
    
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
        toml = try values.decode(LinkResponse.self, forKey: .toml)
    }
}
