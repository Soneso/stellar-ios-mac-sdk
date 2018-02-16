//
//  TimeBounds.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/15/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    TimeBounds represents the time interval that a transaction is valid.
 
    - See Transaction
 */
final public class TimeBounds {
    final let minTime:UInt64
    final let maxTime:UInt64
    
    /**
        Init
     
        - Parameter minTime: 64bit Unix timestamp
        - Parameter maxTime 64bit Unix timestamp
     */
    public init(minTime:UInt64, maxTime:UInt64) throws {
        if minTime >= maxTime {
            throw StellarSDKError.invalidArgument(message: "minTime must be less than maxTime")
        }
        self.minTime = minTime
        self.maxTime = maxTime
    }
    
     /// Generates Time Bounds XDR object.
    public func toXdr() -> TimeBoundsXDR {
        return TimeBoundsXDR(minTime: minTime, maxTime: maxTime)
    }
}
