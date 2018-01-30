//
//  Thresholds.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class Thresholds: NSObject, Codable {
    var low:Int
    var med:Int
    var high:Int
    
    override init() {
        low = 0
        med = 0
        high = 0
    }
    
    enum CodingKeys: String, CodingKey {
        case low = "low_threshold"
        case med = "med_threshold"
        case high = "high_threshold"
    }
    
}
