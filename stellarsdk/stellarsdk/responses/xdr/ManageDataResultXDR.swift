//
//  ManageDataResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ManageDataResultCode: Int {
    case success = 0
    case notSupportedYet = -1
    case nameNotFound = -2
    case lowReserve = -3
    case invalidName = -4
}

enum ManageDataResultXDR: XDRCodable {
    case success (Int)
    case empty (Int)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = ManageDataResultCode(rawValue: try container.decode(Int.self))!
        
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
