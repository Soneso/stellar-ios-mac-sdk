//
//  InflationResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum InflationResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0
    // codes considered as "failure" for the operation
    case notTime = -1
}

public enum InflationResultXDR: XDRCodable {
    case success(Int32, [InflationPayoutXDR])
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = InflationResultCode(rawValue: discriminant)!
        
        switch code {
            case .success:
                let inflationPayouts = try decodeArray(type: InflationPayoutXDR.self, dec: decoder)
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

