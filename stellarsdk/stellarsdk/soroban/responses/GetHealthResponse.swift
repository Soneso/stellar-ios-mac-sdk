//
//  GetHealthResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// General node health check response.
public class GetHealthResponse: NSObject, Decodable {
    
    /// Health status e.g. "healthy"
    public var status:String
    public var ledgerRetentionWindow:Int?
    
    private enum CodingKeys: String, CodingKey {
        case status
        case ledgerRetentionWindow
        
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        ledgerRetentionWindow = try values.decodeIfPresent(Int.self, forKey: .ledgerRetentionWindow)
    }
}

public struct HealthStatus {
    public static let HEALTHY: String = "healthy"
}
