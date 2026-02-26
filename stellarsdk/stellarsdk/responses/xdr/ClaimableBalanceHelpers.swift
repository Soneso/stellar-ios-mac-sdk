//
//  ClaimableBalanceEntryXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct ClaimableBalanceFlags: Sendable {

    // If set, the issuer account of the asset held by the claimable balance may
    // clawback the claimable balance
    public static let CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG: UInt32 = 1
}

extension ClaimableBalanceIDXDR {
    public init(claimableBalanceId: String) throws {
        var claimableBalanceIdHex = claimableBalanceId
        if claimableBalanceId.hasPrefix("B") {
            claimableBalanceIdHex = try claimableBalanceId.decodeClaimableBalanceIdToHex()
        }
        if let data = claimableBalanceIdHex.data(using: .hexadecimal) {
            if data.count == 33 { // contains the discriminant in the first byte
                let type = data.first.map { Int32($0) } ?? 0
                if type == ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue {
                    self = .claimableBalanceIDTypeV0(claimableBalanceIdHex.wrappedData32FromHex())
                } else {
                    throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, unknown discriminant: \(type)")
                }
            } else {
                self = .claimableBalanceIDTypeV0(claimableBalanceIdHex.wrappedData32FromHex())
            }
        } else {
            throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, invalid claimable balance id")
        }
    }

    public var claimableBalanceIdString: String {
        switch self {
        case .claimableBalanceIDTypeV0(let data):
            let type = UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
            var result = Data([type])
            result.append(data.wrapped)
            return result.base16EncodedString()
        }
    }
}
