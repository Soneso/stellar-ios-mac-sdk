//
//  ClaimableBalanceIDXDR+Helpers.swift
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
    /// A string as long as a strkey is read as one: the base32 and the hexadecimal alphabets
    /// overlap, but no hexadecimal spelling has that length, so the strkey reading is the
    /// only one that can succeed.
    ///
    /// - Throws: StellarSDKError.encodingError if the string holds none of these spellings or
    /// carries a discriminant naming no claimable balance id type,
    /// KeyUtilsError if a "B..." strkey is malformed
    public init(claimableBalanceId: String) throws {
        if claimableBalanceId.count == StellarProtocolConstants.STRKEY_ENCODED_LENGTH_CLAIMABLE_BALANCE {
            guard claimableBalanceId.hasPrefix(StellarProtocolConstants.STRKEY_PREFIX_CLAIMABLE_BALANCE) else {
                throw StellarSDKError.encodingError(message: "a \(StellarProtocolConstants.STRKEY_ENCODED_LENGTH_CLAIMABLE_BALANCE) character claimable balance id must be a strkey beginning with \"\(StellarProtocolConstants.STRKEY_PREFIX_CLAIMABLE_BALANCE)\"")
            }
            // The decode verifies the checksum and the type discriminant and hands back the
            // body: the discriminant followed by the id.
            let body = try claimableBalanceId.decodeClaimableBalanceId()
            self = .claimableBalanceIDTypeV0(WrappedData32(Data(body.dropFirst(StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE))))
            return
        }
        guard let data = claimableBalanceId.data(using: .hexadecimal) else {
            throw StellarSDKError.encodingError(message: ClaimableBalanceIDXDR.spellingMessage(claimableBalanceId))
        }
        switch data.count {
        case StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE:
            self = .claimableBalanceIDTypeV0(WrappedData32(data))
        case ClaimableBalanceIdFraming.bodySize:
            guard ClaimableBalanceIdFraming.isValidBody(data) else {
                throw StellarSDKError.encodingError(message: ClaimableBalanceIDXDR.discriminantMessage(Int32(data[data.startIndex])))
            }
            self = .claimableBalanceIDTypeV0(WrappedData32(Data(data.dropFirst(StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE))))
        case ClaimableBalanceIdFraming.xdrBodySize:
            guard ClaimableBalanceIdFraming.isValidXdrBody(data) else {
                let carried = data.prefix(ClaimableBalanceIdFraming.xdrDiscriminant.count)
                    .reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
                throw StellarSDKError.encodingError(message: ClaimableBalanceIDXDR.discriminantMessage(Int32(bitPattern: carried)))
            }
            self = .claimableBalanceIDTypeV0(WrappedData32(Data(data.suffix(StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE))))
        default:
            throw StellarSDKError.encodingError(message: ClaimableBalanceIDXDR.spellingMessage(claimableBalanceId))
        }
    }

    /// The id as the hex of the 33 byte body: the one byte type discriminant followed by the
    /// 32 byte id, in lower case.
    public var claimableBalanceIdString: String {
        switch self {
        case .claimableBalanceIDTypeV0(let data):
            var result = Data([ClaimableBalanceIdFraming.typeDiscriminant])
            result.append(data.wrapped)
            return result.base16EncodedString()
        }
    }

    /// The id in the spelling Horizon serves: the hex of the 36 byte XDR encoding, the four
    /// byte big endian union discriminant followed by the 32 byte id, in lower case.
    public var paddedBalanceIdHex: String {
        switch self {
        case .claimableBalanceIDTypeV0(let data):
            var result = ClaimableBalanceIdFraming.xdrDiscriminant
            result.append(data.wrapped)
            return result.base16EncodedString()
        }
    }

    /// Names the spellings an id may hold and the length the given one has.
    private static func spellingMessage(_ claimableBalanceId: String) -> String {
        return "claimable balance id must be a \(StellarProtocolConstants.STRKEY_ENCODED_LENGTH_CLAIMABLE_BALANCE) character strkey (\(StellarProtocolConstants.STRKEY_PREFIX_CLAIMABLE_BALANCE)...), or hex of the bare id (\(StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE * 2) characters), which a discriminant may prefix to \(ClaimableBalanceIdFraming.bodySize * 2) or \(ClaimableBalanceIdFraming.xdrBodySize * 2) characters; \(claimableBalanceId.count) characters given"
    }

    /// Names a discriminant the XDR union does not define.
    private static func discriminantMessage(_ carried: Int32) -> String {
        return "claimable balance id carries the discriminant \(carried), which names no claimable balance id type"
    }
}
