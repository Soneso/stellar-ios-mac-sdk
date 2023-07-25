//
//  RestoreFootprintResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum RestoreFootprintResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1
    case resourceLimitExceeded = -2
}

public enum RestoreFootprintResultXDR: XDRCodable {

    case success
    case malformed
    case resourceLimitExceeded
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = RestoreFootprintResultCode(rawValue: discriminant)!
        
        switch code {
        case .success:
            self = .success
        case .malformed:
            self = .malformed
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
        }
    }
}
