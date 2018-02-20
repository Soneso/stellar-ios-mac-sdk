//
//  AccountMergeResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AccountMergeResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
     // codes considered as "failure" for the operation
    case malformed = -1 // can't merge onto itself
    case noAccount = -2 // destination does not exist
    case immutableSet = -3 // source account has AUTH_IMMUTABLE set
    case hasSubEntries = -4 // account has trust lines/offers
}

public enum AccountMergeResultXDR: XDRCodable {
    case success(Int32, Int64)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = AccountMergeResultCode(rawValue: discriminant)!
        
        switch code {
        case .success:
            let sourceAccountBalance = try container.decode(Int64.self)
            self = .success(code.rawValue, sourceAccountBalance)
        default:
            self = .empty(code.rawValue)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
        case .success(let code, let sourceAccountBalance):
            try container.encode(code)
            try container.encode(sourceAccountBalance)
        case .empty(let code):
            try container.encode(code)
            break
        }
    }
}
