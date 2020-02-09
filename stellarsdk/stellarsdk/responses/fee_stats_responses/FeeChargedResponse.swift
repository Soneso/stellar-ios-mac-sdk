//
//  FeeChargedResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 09.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class FeeChargedResponse: NSObject, Decodable {
    
    public var max:String
    public var min:String
    public var mode:String
    public var p10:String
    public var p20:String
    public var p30:String
    public var p40:String
    public var p50:String
    public var p60:String
    public var p70:String
    public var p80:String
    public var p90:String
    public var p95:String
    public var p99:String
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case max
        case min
        case mode
        case p10
        case p20
        case p30
        case p40
        case p50
        case p60
        case p70
        case p80
        case p90
        case p95
        case p99
    }
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        max = try values.decode(String.self, forKey: .max)
        min = try values.decode(String.self, forKey: .min)
        mode = try values.decode(String.self, forKey: .mode)
        p10 = try values.decode(String.self, forKey: .p10)
        p20 = try values.decode(String.self, forKey: .p20)
        p30 = try values.decode(String.self, forKey: .p30)
        p40 = try values.decode(String.self, forKey: .p40)
        p50 = try values.decode(String.self, forKey: .p50)
        p60 = try values.decode(String.self, forKey: .p60)
        p70 = try values.decode(String.self, forKey: .p70)
        p80 = try values.decode(String.self, forKey: .p80)
        p90 = try values.decode(String.self, forKey: .p90)
        p95 = try values.decode(String.self, forKey: .p95)
        p99 = try values.decode(String.self, forKey: .p99)
    }
}
