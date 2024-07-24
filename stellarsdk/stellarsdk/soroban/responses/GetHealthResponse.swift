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
    
    /// Most recent known ledger sequence
    public var latestLedger:Int
    
    /// Oldest ledger sequence kept in history
    public var oldestLedger:Int
    
    /// Maximum retention window configured. A full window state can be determined via: ledgerRetentionWindow = latestLedger - oldestLedger + 1
    public var ledgerRetentionWindow:Int
    
    private enum CodingKeys: String, CodingKey {
        case status
        case latestLedger
        case oldestLedger
        case ledgerRetentionWindow
        
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        oldestLedger = try values.decode(Int.self, forKey: .oldestLedger)
        ledgerRetentionWindow = try values.decode(Int.self, forKey: .ledgerRetentionWindow)
    }
}

public struct HealthStatus {
    public static let HEALTHY: String = "healthy"
}
