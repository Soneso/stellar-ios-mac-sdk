//
//  RevokeSponsorshipResultXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation


public enum RevokeSponsorshipResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
     // codes considered as "failure" for the operation
    case doesNotExist = -1 // specified entry does not exist
    case notSponsored = -2 // not sponsor of specified entry
    case lowReserve = -3 // new reserve payor cannot afford this entry
    case onlyTransferabel = -4 // sponsorship of ClaimableBalance must be transferred to another account
}

public enum RevokeSponsorshipResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = RevokeSponsorshipResultCode(rawValue: discriminant)!
        
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
