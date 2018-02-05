//
//  Signer.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Signer: NSObject, Codable {
    
    public var publicKey:String
    public var weight:Int
    public var key:String!
    public var type:String!
    
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
        case key
        case type
    }
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        publicKey = try values.decode(String.self, forKey: .publicKey)
        weight = try values.decode(Int.self, forKey: .weight)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        type = try values.decodeIfPresent(String.self, forKey: .type)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(publicKey, forKey: .publicKey)
        try container.encode(weight, forKey: .weight)
        try container.encode(key, forKey: .key)
        try container.encode(type, forKey: .type)
    }
    
}
