//
//  AssetLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for asset-related resources.
///
/// Provides hypermedia links to resources associated with an asset, primarily
/// the issuer's stellar.toml file which contains asset metadata and verification.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AssetResponse for complete asset details
public struct AssetLinksResponse: Decodable, Sendable {

    /// Link to the stellar.toml file hosted by the asset issuer. Contains asset metadata and verification.
    public let toml:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case toml
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        toml = try values.decode(LinkResponse.self, forKey: .toml)
    }
}
