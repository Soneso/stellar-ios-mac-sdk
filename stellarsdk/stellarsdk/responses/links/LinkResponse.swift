//
//  LinkResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a link response. Used for different responses such as for an account response or ledger response from the Horizon API.
public class LinkResponse: NSObject, Decodable {
    
    /// Specifies the URL of the page the link goes to.
    public var href:String
    
    /// Specifies if the URL is templated with arguments/parameters such as cursor, order, limit,.
    public var templated:Bool?
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case href
        case templated
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        href = try values.decode(String.self, forKey: .href)
        templated = try values.decodeIfPresent(Bool.self, forKey: .templated)
    }
}
