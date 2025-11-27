//
//  EventFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Filter criteria for querying contract events.
///
/// EventFilter allows you to narrow event queries by:
/// - Event type (system, contract, or diagnostic)
/// - Specific contract IDs
/// - Event topic patterns
///
/// Use filters to reduce the amount of data returned and focus on events relevant
/// to your application. Multiple filters can be combined, and events matching any
/// filter will be included in results.
///
/// Limitations:
/// - Maximum 5 contract IDs per request
/// - Maximum 5 topic filters per request
///
/// Example:
/// ```swift
/// // Filter events from specific contracts
/// let contractFilter = EventFilter(
///     type: "contract",
///     contractIds: ["CCONTRACT123...", "CCONTRACT456..."]
/// )
///
/// // Filter by event topics
/// let topicFilter = TopicFilter(segmentMatchers: [
///     "transfer",  // Topic 0: event name
///     "*",         // Topic 1: any value
///     "GADDR..."   // Topic 2: specific address
/// ])
/// let filter = EventFilter(
///     type: "contract",
///     topics: [topicFilter]
/// )
///
/// // Query events with filter
/// let response = await server.getEvents(
///     startLedger: 1000000,
///     eventFilters: [contractFilter]
/// )
/// ```
///
/// See also:
/// - [SorobanServer.getEvents] for querying events
/// - [TopicFilter] for topic-based filtering
/// - [Stellar developer docs](https://developers.stellar.org)
public class EventFilter {
    
    /// Event type filter criteria (system, contract, or diagnostic). If omitted, all types are included.
    public let type:String?
    
    /// (optional) List of contract ids to query for events. If omitted, return events for all contracts. Maximum 5 contract IDs are allowed per request.
    public let contractIds: [String]?
    
    /// (optional) List of topic filters. If omitted, query for all events. If multiple filters are specified, events will be included if they match any of the filters. Maximum 5 filters are allowed per request.
    public let topics: [TopicFilter]?
    
    /// Creates an event filter for querying Soroban contract events by type, contract, and topics.
    public init(type:String? = nil, contractIds: [String]? = nil, topics: [TopicFilter]? = nil) {
        self.type = type
        self.contractIds = contractIds
        self.topics = topics
    }
    
    /// Converts the filter into request parameters for the Soroban RPC API.
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        if let type = type {
            result["type"] = type
        }
        // contractIds
        if let contractIds = contractIds, !contractIds.isEmpty {
            var arr:[String] = []
            for contractId in contractIds {
                arr.append(contractId)
            }
            result["contractIds"] = arr
        }
        // topics
        if let topics = topics, !topics.isEmpty {
            var arr:[[String]] = []
            for topic in topics {
                arr.append(topic.segmentMatchers)
            }
            result["topics"] = arr
        }
        return result;
    }
}
