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
/// lives here and is applied on both sides rather than written twice.
///
/// See: [SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md)
internal enum ClaimableBalanceIdFraming {

    /// The type discriminant a body opens with.
    ///
    /// CLAIMABLE_BALANCE_ID_TYPE_V0 is the only type the XDR union defines, so a body opening
    /// with any other byte names a type that does not exist.
    static let typeDiscriminant = UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)

    /// The width of a well formed body in bytes: the discriminant followed by the id.
    static let bodySize = StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE
        + StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE

    /// Returns true if `body` is `bodySize` bytes wide and opens with the type discriminant.
    ///
    /// - Parameter body: a claimable balance id body, the discriminant followed by the id
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
    ///
    /// - Parameter body: an XDR encoded claimable balance id, the union discriminant followed
    /// by the id
    static func isValidXdrBody<Body: Collection>(_ body: Body) -> Bool where Body.Element == UInt8 {
        return body.count == xdrBodySize
            && body.prefix(xdrDiscriminant.count).elementsEqual(xdrDiscriminant)
    }
}
