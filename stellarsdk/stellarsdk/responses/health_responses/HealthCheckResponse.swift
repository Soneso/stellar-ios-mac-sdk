//
//  HealthCheckResponse.swift
//  stellarsdk
//
//  Created by Soneso on 05/10/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Represents the response from the Horizon health check endpoint.
/// This endpoint provides information about the health status of the Horizon server,
/// including database connectivity and Stellar Core status.
/// See [Stellar developer docs](https://developers.stellar.org)
public struct HealthCheckResponse: Decodable, Sendable {

    /// Indicates whether Horizon can successfully connect to its database
    public let databaseConnected: Bool

    /// Indicates whether Horizon can successfully connect to Stellar Core
    public let coreUp: Bool

    /// Indicates whether Stellar Core is synchronized with the network
    public let coreSynced: Bool

    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case databaseConnected = "database_connected"
        case coreUp = "core_up"
        case coreSynced = "core_synced"
    }

    /// Initializer from decoder
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if the data is corrupted or invalid
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        databaseConnected = try values.decode(Bool.self, forKey: .databaseConnected)
        coreUp = try values.decode(Bool.self, forKey: .coreUp)
        coreSynced = try values.decode(Bool.self, forKey: .coreSynced)
    }

    /// Indicates whether the Horizon server is healthy.
    /// The server is considered healthy if the database is connected,
    /// core is up, and core is synchronized with the network.
    public var isHealthy: Bool {
        return databaseConnected && coreUp && coreSynced
    }
}
