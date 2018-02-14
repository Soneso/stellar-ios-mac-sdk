//
//  SetOptionsResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum SetOptionsResultCode: Int {
    case success = 0
    case lowReserve = -1
    case tooManySigners = -2
    case badFlags = -3
    case invalidInflation = -4
    case cantChange = -5
    case unknownFlag = -6
    case thresholdOutOfRange = -7
    case badSigner = -8
    case invalidHomeDomain = -9
}

enum SetOptionsResultXDR: XDRCodable {
    case success
    case empty
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = SetOptionsResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
        case .success:
            self = .success
        default:
            self = .empty
        }
    }
    
    public func encode(to encoder: Encoder) throws {
    }
}

