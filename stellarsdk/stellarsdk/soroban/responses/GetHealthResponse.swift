//
//  GetHealthResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// General node health check response.
public struct GetHealthResponse: Decodable, Sendable {

    /// Health status e.g. "healthy"
    public let status:String

    /// Most recent known ledger sequence
    public let latestLedger:Int

    /// Oldest ledger sequence kept in history
    public let oldestLedger:Int

    /// Maximum retention window configured. A full window state can be determined via: ledgerRetentionWindow = latestLedger - oldestLedger + 1
    public let ledgerRetentionWindow:Int

    /// The unix timestamp (seconds) of the close time of the latest known ledger, as a string.
    /// Returned by RPC servers from v27.1.0; nil when the server does not provide it.
    public let latestLedgerCloseTime:String?

    /// The unix timestamp (seconds) of the close time of the oldest ledger kept in history, as a string.
    /// Returned by RPC servers from v27.1.0; nil when the server does not provide it.
    public let oldestLedgerCloseTime:String?

    private enum CodingKeys: String, CodingKey {
        case status
        case latestLedger
        case oldestLedger
        case ledgerRetentionWindow
        case latestLedgerCloseTime
        case oldestLedgerCloseTime
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        oldestLedger = try values.decode(Int.self, forKey: .oldestLedger)
        ledgerRetentionWindow = try values.decode(Int.self, forKey: .ledgerRetentionWindow)
        latestLedgerCloseTime = try values.decodeIfPresent(String.self, forKey: .latestLedgerCloseTime)
        oldestLedgerCloseTime = try values.decodeIfPresent(String.self, forKey: .oldestLedgerCloseTime)
    }
}

/// Constants representing possible health status values for Soroban RPC nodes.
public struct HealthStatus: Sendable {
    /// Soroban RPC node is operational.
    public static let HEALTHY: String = "healthy"
}
