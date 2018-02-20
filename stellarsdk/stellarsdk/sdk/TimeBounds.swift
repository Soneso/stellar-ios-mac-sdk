//
//  TimeBounds.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/15/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// TimeBounds represents the time interval that a transaction is valid.
final public class TimeBounds {
    
    /// minTime - 64bit Unix timestamp
    final public let minTime:UInt64
    
    /// maxTime - 64bit Unix timestamp
    final public let maxTime:UInt64
    
    /// Creates a new TimeBounds object.
    ///
    /// - Parameter minTime: 64bit Unix timestamp
    /// - Parameter maxTime 64bit Unix timestamp
    ///
    /// - Throws a StellarSDKError.invalidArgument error if minTime is not less then maxTime
    ///
    public init(minTime:UInt64, maxTime:UInt64) throws {
        if minTime >= maxTime {
            throw StellarSDKError.invalidArgument(message: "minTime must be less than maxTime")
        }
        self.minTime = minTime
        self.maxTime = maxTime
    }
    
    /// Creates a TimeBounds XDR object from the current TimeBounds object.
    ///
    /// - Returns the created TimeBoundsXDR object.
    public func toXdr() -> TimeBoundsXDR {
        return TimeBoundsXDR(minTime:minTime, maxTime:maxTime)
    }
}
