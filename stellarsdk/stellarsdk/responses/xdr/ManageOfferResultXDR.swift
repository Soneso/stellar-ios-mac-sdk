//
//  ManageOfferResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ManageOfferResultXDR: XDRCodable, Sendable {
    case success(Int32, ManageOfferSuccessResultXDR)
    case empty (Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let code = ManageOfferResultCode(rawValue: discriminant)!
        
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
