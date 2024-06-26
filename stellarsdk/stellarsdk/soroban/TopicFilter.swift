//
//  SegmentFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// part of the get Events request
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
public class TopicFilter {
    
    public let segmentMatchers: [String]
    
    public init(segmentMatchers:[String]) {
        self.segmentMatchers = segmentMatchers
    }
}
