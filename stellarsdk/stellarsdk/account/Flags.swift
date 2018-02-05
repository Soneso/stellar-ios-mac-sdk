//
//  Flags.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Flags: NSObject, Codable {
    
    public var authRequired:Bool!
    public var authRevocable:Bool!
    public var authImmutable:Bool!
    
    enum CodingKeys: String, CodingKey {
        case authRequired = "auth_required"
        case authRevocable = "auth_revocable"
        case authImmutable = "auth_immutable"
    }
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        authRequired = try values.decodeIfPresent(Bool.self, forKey: .authRequired)
        if authRequired == nil {
            authRequired = false
        }
        
        authRevocable = try values.decodeIfPresent(Bool.self, forKey: .authRevocable)
        if authRevocable == nil {
            authRevocable = false
        }
        
        authImmutable = try values.decodeIfPresent(Bool.self, forKey: .authImmutable)
        if authImmutable == nil {
            authImmutable = false
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authRequired, forKey: .authRequired)
        try container.encode(authRevocable, forKey: .authRevocable)
        try container.encode(authImmutable, forKey: .authImmutable)
    }
}
