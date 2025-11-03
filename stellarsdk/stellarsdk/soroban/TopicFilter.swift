//
//  TopicFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Topic-based filter for querying contract events.
///
/// TopicFilter allows filtering events by their topic values. Topics are indexed
/// parameters emitted with contract events, typically including the event name
/// and key parameters.
///
/// Topic matching:
/// - Use exact values to match specific topics (e.g., "transfer")
/// - Use "*" as a wildcard to match any value at that position
///
/// Example:
/// ```swift
/// // Match transfer events to a specific address
/// let topicFilter = TopicFilter(segmentMatchers: [
///     "transfer",    // Topic 0: event name
///     "*",          // Topic 1: any sender
///     "GADDR..."    // Topic 2: specific recipient
/// ])
///
/// let eventFilter = EventFilter(
///     type: "contract",
///     topics: [topicFilter]
/// )
/// ```
///
/// See also:
/// - [EventFilter] for complete event filtering
/// - [SorobanServer.getEvents] for querying events
/// - [Soroban Events](https://developers.stellar.org/docs/smart-contracts/guides/events)
public class TopicFilter {
    
    public let segmentMatchers: [String]
    
    public init(segmentMatchers:[String]) {
        self.segmentMatchers = segmentMatchers
    }
}
