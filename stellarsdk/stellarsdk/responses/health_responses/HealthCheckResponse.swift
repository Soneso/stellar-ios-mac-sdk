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
/// See [Horizon API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/health "Health Check")
public class HealthCheckResponse: NSObject, Decodable {

    /// Indicates whether Horizon can successfully connect to its database
    public var databaseConnected: Bool

    /// Indicates whether Horizon can successfully connect to Stellar Core
    public var coreUp: Bool

    /// Indicates whether Stellar Core is synchronized with the network
    public var coreSynced: Bool

    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case databaseConnected = "database_connected"
        case coreUp = "core_up"
        case coreSynced = "core_synced"
    }

    /// Initializer from decoder
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if the data is corrupted or invalid
    public required init(from decoder: Decoder) throws {
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
