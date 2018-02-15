//
//  TimeBounds.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/15/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
 * <p>TimeBounds represents the time interval that a transaction is valid.</p>
 * @see Transaction
 */
final public class TimeBounds {
    final let minTime:UInt64
    final let maxTime:UInt64
    
    /**
     * @param minTime 64bit Unix timestamp
     * @param maxTime 64bit Unix timestamp
     */
    public init(minTime:UInt64, maxTime:UInt64) throws {
        if minTime >= maxTime {
            throw StellarSDKError.invalidArgument(message: "minTime must be less than maxTime")
        }
        self.minTime = minTime
        self.maxTime = maxTime
    }
    
    public func toXdr() -> TimeBoundsXDR {
        return TimeBoundsXDR(minTime: minTime, maxTime: maxTime)
    }
}
