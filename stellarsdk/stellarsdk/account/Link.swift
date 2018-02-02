//
//  Link.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Link: NSObject, Codable {
    
    public var href:String
    public var templated:Bool?
    
    enum CodingKeys: String, CodingKey {
        case href
        case templated
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        href = try values.decode(String.self, forKey: .href)
        templated = try values.decodeIfPresent(Bool.self, forKey: .templated)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(href, forKey: .href)
        try container.encode(templated, forKey: .templated)
    }
}
