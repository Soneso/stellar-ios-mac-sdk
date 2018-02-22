//
//  VersionByte.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

enum VersionByte:UInt8 {
    case accountId = 48
    case seed = 144
    case preAuthTX = 152
    case sha256Hash = 184
}

extension VersionByte: RawRepresentable {
    typealias RawValue = UInt8
    
    init?(rawValue: UInt8) {
        return nil
    }
    
    var rawValue: UInt8 {
        switch self {
        case .accountId:
            return 48
        case .seed:
            return 144
        case .preAuthTX:
            return 152
        case .sha256Hash:
            return 184
        }
    }
}
