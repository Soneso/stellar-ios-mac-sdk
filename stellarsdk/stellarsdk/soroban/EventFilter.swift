//
//  EventFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class EventFilter {
    
    public let type:String?
    public let contractIds: [String]?
    public let topics: [[SegmentFilter]]?
    
    public init(type:String? = nil, contractIds: [String]? = nil, topics: [[SegmentFilter]]? = nil) {
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
        if (topics != nil && topics!.count > 0) {
            var arr:[[[String : Any]]] = []
            for segments in topics! {
                var segArr:[[String : Any]] = []
                for segement in segments {
                    segArr.append(segement.buildRequestParams())
                }
                arr.append(segArr)
            }
            result["topics"] = arr
        }
        return result;
    }
}
