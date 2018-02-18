//
//  CreateAccountResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum CreateAccountResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // account was created
    
     // codes considered as "failure" for the operation
    case malformed = -1 // invalid destination
    case underfunded = -2 // not enough funds in source account
    case lowReserve = -3  // would create an account below the min reserve
    case alreadyExists = -4 // account already exists
}

public enum CreateAccountResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = CreateAccountResultCode(rawValue: discriminant)!
        
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
