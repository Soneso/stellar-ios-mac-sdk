//
//  PaginationOptions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class PaginationOptions {
    
    public let cursor:String?
    public let limit: Int?
    
    public init(cursor:String? = nil, limit: Int? = nil) {
        self.cursor = cursor
        self.limit = limit
    }
    
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        if cursor != nil {
            result["cursor"] = cursor!
        }
        if limit != nil {
            result["limit"] = limit!
        }
        return result;
    }
}
