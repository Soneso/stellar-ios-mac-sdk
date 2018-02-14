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
    case success
    case empty
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = CreateAccountResultCode(rawValue: try container.decode(Int.self))!
        
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
