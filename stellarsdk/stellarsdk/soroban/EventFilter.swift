//
//  EventFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Part of the getEvents request
/// https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
public class EventFilter {
    
    /// (optional) A comma separated list of event types (system, contract, or diagnostic) used to filter events. If omitted, all event types are included.
    public let type:String?
    
    /// (optional) List of contract ids to query for events. If omitted, return events for all contracts. Maximum 5 contract IDs are allowed per request.
    public let contractIds: [String]?
    
    /// (optional) List of topic filters. If omitted, query for all events. If multiple filters are specified, events will be included if they match any of the filters. Maximum 5 filters are allowed per request.
    public let topics: [TopicFilter]?
    
    public init(type:String? = nil, contractIds: [String]? = nil, topics: [TopicFilter]? = nil) {
        self.type = type
        self.contractIds = contractIds
        self.topics = topics
    }
    
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        if type != nil {
            result["type"] = type!
        }
        // contractIds
        if (contractIds != nil && contractIds!.count > 0) {
            var arr:[String] = []
            for contractId in contractIds! {
                arr.append(contractId)
            }
            result["contractIds"] = arr
        }
        // topics
        if (topics != nil && topics!.count > 0) { // TODO: Test this!
            var arr:[[String]] = []
            for topic in topics! {
                arr.append(topic.segmentMatchers)
            }
            result["topics"] = arr
        }
        return result;
    }
}
