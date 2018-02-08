//
//  AllAssetsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an all assets response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/assets-all.html "All Assets Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/asset.html "Asset")
public class AssetsResponse: NSObject, Codable {
    
    /// A list of links related to this response.
    public var links:AllAssetsLinks
    
    /// Assets found in the response.
    public var assets:[Asset]

    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The assets are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedAssetsService
    struct EmbeddedAssetsService: Codable {
        let records: [Asset]
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(AllAssetsLinks.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedAssetsService.self, forKey: .embeddedRecords)
        self.assets = self.embeddedRecords.records
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(embeddedRecords, forKey: .embeddedRecords)
    }
}
