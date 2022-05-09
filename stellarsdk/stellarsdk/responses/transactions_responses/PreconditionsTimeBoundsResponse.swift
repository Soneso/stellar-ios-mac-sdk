//
//  PreconditionsTimeBoundsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

public class PreconditionsTimeBoundsResponse: NSObject, Decodable {
    
    public var minTime:String?
    public var maxTime:String?
    
    private enum CodingKeys: String, CodingKey {
        case minTime = "min_time"
        case maxTime = "max_time"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        minTime = try values.decodeIfPresent(String.self, forKey: .minTime)
        maxTime = try values.decodeIfPresent(String.self, forKey: .maxTime)
    }
}
