//
//  GetHealthResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class GetHealthResponse: NSObject, Decodable {
    
    /// Health status e.g. "healthy"
    public var status:String
    
    private enum CodingKeys: String, CodingKey {
        case status
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
    }
}
