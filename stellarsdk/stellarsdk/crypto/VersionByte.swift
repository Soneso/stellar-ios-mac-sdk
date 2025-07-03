//
//  VersionByte.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

enum VersionByte:UInt8 {
    case ed25519PublicKey = 48 // 6 << 3 - G (when encoded in base32)
    case ed25519SecretSeed = 144 // 18 << 3 - S
    case med25519PublicKey = 96 // 12 << 3 - M
    case preAuthTX = 152 // 19 << 3 - T
    case sha256Hash = 184 // 23 << 3 - X
    case signedPayload = 120 // 15 << 3 - P
    case contract = 16 // 2 << 3 - C
    case liquidityPool = 88 // 11 << 3 - L
    case claimableBalance = 8 // 1 << 3 - B
}

extension VersionByte: RawRepresentable {
    typealias RawValue = UInt8
    
    var rawValue: UInt8 {
        switch self {
        case .ed25519PublicKey:
            return 48
        case .med25519PublicKey:
            return 96
        case .signedPayload:
            return 120
        case .ed25519SecretSeed:
            return 144
        case .preAuthTX:
            return 152
        case .sha256Hash:
            return 184
        case .contract:
            return 16
        case .liquidityPool:
            return 88
        case .claimableBalance:
            return 8
        }
    }
}
