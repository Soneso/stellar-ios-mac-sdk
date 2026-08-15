//
//  ClaimableBalanceEntryXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

extension ClaimableBalanceIDXDR {
    /// Creates a claimable balance id from any of its spellings: the "B..." strkey, the hex
    /// of the bare 32 byte id, the hex of the 33 byte body opening with the one byte type
    /// discriminant, or the hex of the 36 byte XDR encoding opening with the four byte union
    /// discriminant, the shape Horizon reports.
    ///
    /// - Throws: StellarSDKError.encodingError if the string is none of these,
    /// KeyUtilsError if a "B..." strkey is malformed
    public init(claimableBalanceId: String) throws {
        var claimableBalanceIdHex = claimableBalanceId
        if claimableBalanceId.hasPrefix("B") {
            claimableBalanceIdHex = try claimableBalanceId.decodeClaimableBalanceIdToHex()
        }
        guard let data = claimableBalanceIdHex.data(using: .hexadecimal) else {
            throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, invalid claimable balance id")
        }
        switch data.count {
        case StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE:
            self = .claimableBalanceIDTypeV0(WrappedData32(data))
        case ClaimableBalanceIdFraming.bodySize:
            guard ClaimableBalanceIdFraming.isValidBody(data) else {
                throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, unknown discriminant: \(data.first ?? 0)")
            }
            self = .claimableBalanceIDTypeV0(WrappedData32(Data(data.dropFirst(StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE))))
        case ClaimableBalanceIdFraming.xdrBodySize:
            guard ClaimableBalanceIdFraming.isValidXdrBody(data) else {
                throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, unknown discriminant")
            }
            self = .claimableBalanceIDTypeV0(WrappedData32(Data(data.suffix(StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE))))
        default:
            throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, invalid claimable balance id length \(data.count), must be \(StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE), \(ClaimableBalanceIdFraming.bodySize) or \(ClaimableBalanceIdFraming.xdrBodySize) bytes")
        }
    }

    public var claimableBalanceIdString: String {
        switch self {
        case .claimableBalanceIDTypeV0(let data):
            var result = Data([ClaimableBalanceIdFraming.typeDiscriminant])
            result.append(data.wrapped)
            return result.base16EncodedString()
        }
    }
}
