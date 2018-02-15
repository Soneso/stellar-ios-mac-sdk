//
//  InflationResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum InflationResultCode: Int {
    case success = 0
    case notTime = -1
}

enum InflationResultXDR: XDRCodable {
    case success(Int, [InflationPayoutXDR])
    case empty (Int)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = InflationResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
            case .success:
                let inflationPayouts = try container.decode(Array<InflationPayoutXDR>.self)
                self = .success(code.rawValue, inflationPayouts)
            default:
                self = .empty(code.rawValue)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
            case .success(let code, let inflationPayouts):
                try container.encode(code)
                try container.encode(inflationPayouts)
            case .empty(let code):
                try container.encode(code)
                break
        }
    }
}

