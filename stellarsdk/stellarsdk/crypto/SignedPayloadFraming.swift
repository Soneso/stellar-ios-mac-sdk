//
//  SignedPayloadFraming.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// The framing a signed payload signer body carries: the 32 byte ed25519 signer key, the
/// length of the signed data as a 4 byte big endian unsigned integer, the signed data itself
/// and zero padding up to the next multiple of four bytes.
///
/// The strkey decoder and the strkey encoder both hold bodies in this shape, so the rule
/// lives here.
///
/// See: [SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md)
/// and [CAP-40](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md)
internal enum SignedPayloadFraming {

    /// The lengths the signed data itself may have.
    ///
    /// A signed payload signer authorizes one specific payload, so a signer over an empty
    /// payload authorizes nothing and the ecosystem encodes no strkey for it. The upper
    /// bound is the one CAP-40 sets.
    static let payloadLengthRange = 1...StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD

    /// The signer key and the length field preceding the signed data (36 bytes).
    private static let headerSize = StellarProtocolConstants.SIGNED_PAYLOAD_SIGNER_SIZE
        + StellarProtocolConstants.SIGNED_PAYLOAD_SIZE_FIELD

    /// XDR pads variable length opaque data to a multiple of four bytes.
    private static let paddingAlignment = 4

    /// Returns true if `body` is framed as a signed payload signer body.
    ///
    /// - Parameter body: the decoded strkey body, without version byte and checksum
    static func isValidBody(_ body: [UInt8]) -> Bool {
        guard body.count >= headerSize else {
            return false
        }
        let signerSize = StellarProtocolConstants.SIGNED_PAYLOAD_SIGNER_SIZE
        let declared = UInt32(body[signerSize]) << 24
            | UInt32(body[signerSize + 1]) << 16
            | UInt32(body[signerSize + 2]) << 8
            | UInt32(body[signerSize + 3])
        guard let payloadLength = Int(exactly: declared),
              payloadLengthRange.contains(payloadLength) else {
            return false
        }
        guard body.count == headerSize + paddedWidth(of: payloadLength) else {
            return false
        }
        return body[(headerSize + payloadLength)...].allSatisfy { $0 == 0 }
    }

    /// The width the signed data occupies once padded to a multiple of four bytes.
    private static func paddedWidth(of payloadLength: Int) -> Int {
        return (payloadLength + paddingAlignment - 1) / paddingAlignment * paddingAlignment
    }
}
