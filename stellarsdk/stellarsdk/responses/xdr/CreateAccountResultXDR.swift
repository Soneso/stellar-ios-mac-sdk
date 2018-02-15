//
//  CreateAccountResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum CreateAccountResultCode: Int {
    case success = 0
    case malformed = -1
    case underfunded = -2
    case lowReserve = -3
    case alreadyExists = -4
}
    
enum CreateAccountResultXDR: XDRCodable {
    case success (Int)
    case empty (Int)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = CreateAccountResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
            case .success:
                self = .success(code.rawValue)
            default:
                self = .empty (code.rawValue)
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
