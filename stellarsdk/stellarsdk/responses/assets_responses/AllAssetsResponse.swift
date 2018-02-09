//
//  AllAssetsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all assets response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/assets-all.html "All Assets Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/asset.html "Asset")
public class AllAssetsResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:AllAssetsLinksResponse
    
    /// Assets found in the response.
    public var assets:[AssetResponse]

    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The assets are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedAssetsResponseService
    struct EmbeddedAssetsResponseService: Decodable {
        let records: [AssetResponse]
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(AllAssetsLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedAssetsResponseService.self, forKey: .embeddedRecords)
        self.assets = self.embeddedRecords.records
    }
}
