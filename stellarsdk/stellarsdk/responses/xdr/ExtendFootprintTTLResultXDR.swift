//
//  ExtendFootprintTTLResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum ExtendFootprintTTLResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1
    case resourceLimitExceeded = -2
    case insufficientRefundableFee = -3
}

public enum ExtendFootprintTTLResultXDR: XDRCodable {
    case success
    case malformed
    case resourceLimitExceeded
    case insufficientRefundableFee
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = ExtendFootprintTTLResultCode(rawValue: discriminant)!
        
        switch code {
        case .success:
            self = .success
        case .malformed:
            self = .malformed
        case .insufficientRefundableFee:
            self = .insufficientRefundableFee
        default:
            self = .resourceLimitExceeded
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .success:
            break
        case .malformed:
            break
        case .resourceLimitExceeded:
            break
        case .insufficientRefundableFee:
            break
        }
    }
}
