//
//  ResourceConfig.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.12.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class ResourceConfig {
    
    /// allows budget instruction leeway used in preflight calculations to be configured.
    public let instructionLeeway: Int
    
    public init(instructionLeeway:Int) {
        self.instructionLeeway = instructionLeeway
    }
    
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        result["instructionLeeway"] = instructionLeeway
        return result;
    }
}
