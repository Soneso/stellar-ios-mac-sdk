//
//  ManageOfferResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ManageOfferResultCode: Int {
    case success = 0
    case malformed = -1
    case sellNoTrust = -2
    case buyNoTrust = -3
    case sellNotAuthorized = -4
    case buyNotAuthorized = -5
    case lineFull = -6
    case underfunded = -7
    case crossSelf = -8
    case sellNoIssuer = -9
    case buyNoIssuer = -10
    case notFound = -11
    case lowReserve = -12
}

enum ManageOfferResultXDR: XDRCodable {
    case success(Int, ManageOfferSuccessResultXDR)
    case empty (Int)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = ManageOfferResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
            case .success:
                let result = try container.decode(ManageOfferSuccessResultXDR.self)
                self = .success(code.rawValue, result)
            default:
                self = .empty(code.rawValue)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
            case .success(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .empty(let code):
                try container.encode(code)
                break
        }
    }
}
