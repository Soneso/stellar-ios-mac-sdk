//
//  Thresholds.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Thresholds: NSObject, Codable {
    public var lowThreshold:Int
    public var medThreshold:Int
    public var highThreshold:Int
    
    override init() {
        lowThreshold = 1
        medThreshold = 0
        highThreshold = 0
    }
    
    enum CodingKeys: String, CodingKey {
        case lowThreshold = "low_threshold"
        case medThreshold = "med_threshold"
        case highThreshold = "high_threshold"
    }
    
}
