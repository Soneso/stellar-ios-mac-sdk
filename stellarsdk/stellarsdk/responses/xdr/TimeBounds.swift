//
//  TimeBounds.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TimeBounds: XDRCodable {
    public let minTime: UInt64
    public let maxTime: UInt64
}
