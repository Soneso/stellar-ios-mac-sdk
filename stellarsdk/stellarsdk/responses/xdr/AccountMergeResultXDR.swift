//
//  AccountMergeResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AccountMergeResultCode: Int {
    case success = 0
    case malformed = -1
    case noAccount = -2
    case immutableSet = -3
    case hasSubEntries = -4
}

enum AccountMergeResultXDR: XDRCodable {
    case success(Int, Int64)
    case empty (Int)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = AccountMergeResultCode(rawValue: try container.decode(Int.self))!
        
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
