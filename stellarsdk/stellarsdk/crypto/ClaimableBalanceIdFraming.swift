//
//  ClaimableBalanceIdFraming.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// The framing a claimable balance id body carries: a one byte type discriminant followed by
/// the 32 byte id.
///
/// The strkey decoder and the strkey encoder both hold bodies in this shape, so the rule
/// lives here.
///
/// See: [SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md)
internal enum ClaimableBalanceIdFraming {

    /// Why data holding a claimable balance id is not one.
    ///
    /// The caller words the width case itself: the encoder counts the bytes it was handed,
    /// the reader the characters of the hexadecimal it was given.
    enum MalformedId: Error {
        /// The data has none of the widths a claimable balance id is written in.
        case width(Int)

        /// The data opens with a discriminant naming no claimable balance id type.
        case discriminant(Int32)
    }

    /// The type discriminant a body opens with.
    ///
    /// CLAIMABLE_BALANCE_ID_TYPE_V0 is the only type the XDR union defines, so a body opening
    /// with any other byte names a type that does not exist.
    static let typeDiscriminant = UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)

    /// The width of a well formed body in bytes: the discriminant followed by the id.
    static let bodySize = StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE
        + StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE

    /// Returns true if `body` is `bodySize` bytes wide and opens with the type discriminant.
    static func isValidBody<Body: Collection>(_ body: Body) -> Bool where Body.Element == UInt8 {
        return body.count == bodySize && body.first == typeDiscriminant
    }

    /// The width of the XDR encoding of a claimable balance id in bytes: the four byte XDR
    /// union discriminant followed by the id. Horizon reports claimable balance ids in this
    /// shape, hex encoded to 72 characters.
    static let xdrBodySize = MemoryLayout<Int32>.size
        + StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE

    /// The XDR encoding of the union discriminant: the type as a big endian Int32.
    static let xdrDiscriminant = withUnsafeBytes(
        of: ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue.bigEndian) { Data($0) }

    /// Returns true if `body` is `xdrBodySize` bytes wide and opens with the four byte XDR
    /// union discriminant of CLAIMABLE_BALANCE_ID_TYPE_V0.
    static func isValidXdrBody<Body: Collection>(_ body: Body) -> Bool where Body.Element == UInt8 {
        return body.count == xdrBodySize
            && body.prefix(xdrDiscriminant.count).elementsEqual(xdrDiscriminant)
    }

    /// The bare 32 byte id `data` carries, in whichever width a claimable balance id is
    /// written in: the id on its own, the body opening with the one byte type discriminant,
    /// or the XDR encoding opening with the four byte union discriminant.
    ///
    /// - Throws: MalformedId.width if the data has none of those widths,
    /// MalformedId.discriminant if it opens with a discriminant naming no type
    static func bareId(from data: Data) throws -> Data {
        switch data.count {
        case StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE:
            break
        case bodySize:
            guard isValidBody(data) else {
                throw MalformedId.discriminant(Int32(data[data.startIndex]))
            }
        case xdrBodySize:
            guard isValidXdrBody(data) else {
                throw MalformedId.discriminant(carriedXdrDiscriminant(data))
            }
        default:
            throw MalformedId.width(data.count)
        }
        // A discriminant only ever precedes the id, so the id is the trailing 32 bytes.
        return Data(data.suffix(StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE))
    }

    /// Names a discriminant the XDR union does not define.
    static func discriminantMessage(_ carried: Int32) -> String {
        return "claimable balance id carries the discriminant \(carried), which names no claimable balance id type"
    }

    /// The value the four leading bytes of an XDR encoded id spell, read as the big endian
    /// Int32 the union discriminant is.
    private static func carriedXdrDiscriminant(_ data: Data) -> Int32 {
        let carried = data.prefix(xdrDiscriminant.count)
            .reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
        return Int32(bitPattern: carried)
    }
}
