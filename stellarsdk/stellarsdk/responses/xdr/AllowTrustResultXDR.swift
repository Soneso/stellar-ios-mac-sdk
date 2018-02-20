//
//  AllowTrustResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllowTrustResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case malformed = -1 // asset is not ASSET_TYPE_ALPHANUM
    case noTrustline = -2 // trustor does not have a trustline
    case trustNotRequired = -3 // source account does not require trust
    case cantRevoke = -4  // source account can't revoke trust
    case selfNotAllowed = -5 // trusting self is not allowed
}

public enum AllowTrustResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = AllowTrustResultCode(rawValue: discriminant)!
        
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
