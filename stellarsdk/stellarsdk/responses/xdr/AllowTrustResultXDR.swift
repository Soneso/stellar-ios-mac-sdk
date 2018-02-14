//
//  AllowTrustResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllowTrustResultCode: Int {
    case success = 0
    case malformed = -1
    case noTrustline = -2
    case trustNotRequired = -3
    case cantRevoke = -4
    case selfNotAllowed = -5
}

enum AllowTrustResultXDR: XDRCodable {
    case success
    case empty
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = AllowTrustResultCode(rawValue: try container.decode(Int.self))!
        
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

