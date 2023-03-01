//
//  SegmentFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SegmentFilter {
    
    public let wildcard:String?
    public let scval: [SCValXDR]?
    
    public init(wildcard:String? = nil, scval: [SCValXDR]? = nil) {
        self.wildcard = wildcard
        self.scval = scval
    }
    
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        if wildcard != nil {
            result["wildcard"] = wildcard!
        }
        // scval
        if (scval != nil && scval!.count > 0) {
            var arr:[String] = []
            for val in scval! {
                arr.append(val.xdrEncoded!)
            }
            result["scval"] = arr
        }
        return result;
    }
}
