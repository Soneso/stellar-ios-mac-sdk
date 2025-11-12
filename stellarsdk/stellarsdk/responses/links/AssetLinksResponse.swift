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
/// - [Asset Links](https://developers.stellar.org/api/horizon/reference/resources/asset)
/// - [Stellar TOML](https://developers.stellar.org/docs/issuing-assets/publishing-asset-info)
/// - AssetResponse for complete asset details
public class AssetLinksResponse: NSObject, Decodable {

    /// Link to the stellar.toml file hosted by the asset issuer. Contains asset metadata and verification.
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
