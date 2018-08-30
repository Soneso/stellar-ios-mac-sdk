//
//  BumpSequenceResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum BumpSequenceResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case bad_seq = -1 // `bumpTo` is not within bounds
}

public enum BumpSequenceResultXDR: XDRCodable {

    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = BumpSequenceResultCode(rawValue: discriminant)!
        
        switch code {
        case .success:
            self = .success(code.rawValue)
        default:
            self = .empty(code.rawValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .success(let code):
            try container.encode(code)
        case .empty (let code):
            try container.encode(code)
            break
        }
    }
    
}
