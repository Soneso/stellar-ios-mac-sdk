//
//  SetOptionsResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum SetOptionsResultCode: Int32 {
    // codes considered as "success" for the operation
    case success = 0 // success
    
    // codes considered as "failure" for the operation
    case lowReserve = -1 // not enough funds to add a signer
    case tooManySigners = -2 // max number of signers already reached
    case badFlags = -3 // invalid combination of clear/set flags
    case invalidInflation = -4 // inflation account does not exist
    case cantChange = -5 // can no longer change this option
    case unknownFlag = -6 // can't set an unknown flag
    case thresholdOutOfRange = -7 // bad value for weight/threshold
    case badSigner = -8 // signer cannot be masterkey
    case invalidHomeDomain = -9 // malformed home domain
}

public enum SetOptionsResultXDR: XDRCodable {
    case success (Int32)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = SetOptionsResultCode(rawValue: discriminant)!
        
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

