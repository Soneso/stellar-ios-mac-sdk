//
//  PaymentResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum PaymentResultCode: Int {
    case success = 0
    case malformed = -1
    case underfunded = -2
    case srcNoTrust = -3
    case srcNotAuthorized = -4
    case noDestination = -5
    case noTrust = -6
    case notAuthorized = -7
    case lineFull = -8
    case noIssuer = -9
}

enum PaymentResultXDR: XDRCodable {
    case success
    case empty
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = PaymentResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
        case .success:
            self = .success
        default:
            self = .empty
        }
    }
    
    public func encode(to encoder: Encoder) throws {
    }
    
}
