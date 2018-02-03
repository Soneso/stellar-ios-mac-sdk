//
//  AllAssetsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class AssetsResponse: NSObject, Codable {
    
    public var links:Links
    public var assets:[Asset]

    private var embeddedRecords:EmbeddedAssetsService
    
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    struct EmbeddedAssetsService: Codable {
        let records: [Asset]
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(Links.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedAssetsService.self, forKey: .embeddedRecords)
        self.assets = self.embeddedRecords.records
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(embeddedRecords, forKey: .embeddedRecords)
    }
}
