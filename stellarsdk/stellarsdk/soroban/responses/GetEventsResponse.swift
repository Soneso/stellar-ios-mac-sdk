//
//  GetEventsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response from querying contract events.
///
/// Contains a list of events emitted by smart contracts within the specified ledger range.
/// Events are ordered by their emission time and include all relevant metadata.
///
/// Use this response to:
/// - Monitor contract state changes
/// - Track token transfers and other contract activities
/// - Build event-driven applications
/// - Populate databases with on-chain event data
///
/// Important: When making multiple requests, deduplicate events by their unique ID
/// to prevent double-processing in case of overlapping queries.
///
/// Example:
/// ```swift
/// let response = await server.getEvents(
///     startLedger: 1000000,
///     eventFilters: [filter],
///     paginationOptions: PaginationOptions(limit: 100)
/// )
///
/// switch response {
/// case .success(let eventsResponse):
///     for event in eventsResponse.events {
///         print("Event ID: \(event.id)")
///         print("Contract: \(event.contractId ?? "system")")
///         print("Ledger: \(event.ledger)")
///         print("Topics: \(event.topic)")
///         print("Value: \(event.value)")
///     }
///
///     // Fetch next page if available
///     if let cursor = eventsResponse.cursor {
///         let nextPageOptions = PaginationOptions(cursor: cursor, limit: 100)
///         // Query next page...
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [SorobanServer.getEvents] for querying events
/// - [EventInfo] for individual event details
/// - [EventFilter] for filtering events
public struct GetEventsResponse: Decodable, Sendable {

    /// Contract events returned from Soroban RPC matching the query filters.
    public let events:[EventInfo]

    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public let latestLedger:Int

    /// For paging, only avaliable for protocol version >= 22
    public let cursor:String?

    /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the request.
    /// Only available for protocol version >= 23
    public let latestLedgerCloseTime:String?

    /// The oldest ledger ingested by Soroban-RPC at the time it handled the request.
    /// Only available for protocol version >= 23
    public let oldestLedger:Int?

    /// The unix timestamp of the close time of the oldest ledger ingested by Soroban-RPC at the time it handled the request.
    /// Only available for protocol version >= 23
    public let oldestLedgerCloseTime:String?

    private enum CodingKeys: String, CodingKey {
        case events
        case latestLedger
        case cursor
        case latestLedgerCloseTime
        case oldestLedger
        case oldestLedgerCloseTime
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let evs =  try? values.decode([EventInfo].self, forKey: .events) {
            events = evs
        } else {
            events = []
        }
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        cursor = try values.decodeIfPresent(String.self, forKey: .cursor) // protocol version > 22
        latestLedgerCloseTime = try values.decodeIfPresent(String.self, forKey: .latestLedgerCloseTime) // protocol version > 23
        oldestLedger = try values.decodeIfPresent(Int.self, forKey: .oldestLedger) // protocol version > 23
        oldestLedgerCloseTime = try values.decodeIfPresent(String.self, forKey: .oldestLedgerCloseTime) // protocol version > 23
    }
}
