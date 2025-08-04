//
//  NativeUnionVal.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// This class is used in ContractSpec to represent native union values
/// that need to be converted to XdrSCVal for Soroban contract invocation.
public class NativeUnionVal {
    
    /// The tag identifying which union case is being used
    public let tag: String
    
    /// Optional array of values for tuple union cases
    public let values: [Any]?
    
    /// Initialize a NativeUnionVal for a void union case
    /// - Parameter tag: The tag identifying the union case
    public init(tag: String) {
        self.tag = tag
        self.values = nil
    }
    
    /// Initialize a NativeUnionVal for a tuple union case
    /// - Parameters:
    ///   - tag: The tag identifying the union case
    ///   - values: Array of values for the tuple case
    public init(tag: String, values: [Any]) {
        self.tag = tag
        self.values = values
    }
}