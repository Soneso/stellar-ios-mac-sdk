//
//  TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.08.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur during TxRep parsing or generation.
public enum TxRepError: Error, Sendable {
    /// A required value is missing for the specified key.
    case missingValue(key: String)

    /// The value for the specified key is invalid or cannot be parsed.
    case invalidValue(key: String)
}

/// TxRep is a human-readable text format for Stellar transactions.
///
/// TxRep provides a readable low-level representation of Stellar transactions that can be
/// used for debugging, auditing, or manual transaction construction. It converts between
/// the standard base64-encoded XDR format and a human-readable key-value format.
///
/// Example:
/// ```swift
/// let txEnvelopeXdr = "AAAAAC..." // Base64 XDR
/// let txRep = try TxRep.toTxRep(transactionEnvelope: txEnvelopeXdr)
/// // Returns human-readable format:
/// // type: ENVELOPE_TYPE_TX
/// // tx.sourceAccount: GBZX...
/// // tx.fee: 100
/// // ...
///
/// // Convert back to XDR
/// let xdrAgain = try TxRep.fromTxRep(txRep: txRep)
/// ```
///
/// See: [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md) for the TxRep specification.
public final class TxRep: Sendable {

    public init() {}

    /// Converts a transaction envelope XDR to TxRep format.
    ///
    /// Takes a base64-encoded transaction envelope XDR and converts it to a human-readable
    /// TxRep representation. Supports V0, V1, and fee-bump envelopes per SEP-0011.
    ///
    /// - Parameter transactionEnvelope: Base64-encoded transaction envelope XDR.
    /// - Returns: Human-readable TxRep string with key-value pairs, lines separated by `\n`.
    /// - Throws: `TxRepError` if the XDR cannot be parsed.
    public static func toTxRep(transactionEnvelope: String) throws -> String {
        let envelope = try TransactionEnvelopeXDR(fromBase64: transactionEnvelope)
        var lines = [String]()
        try envelope.toTxRep(prefix: "", lines: &lines)
        return lines.joined(separator: "\n")
    }

    /// Converts a TxRep string to a base64-encoded transaction envelope XDR.
    ///
    /// Parses the human-readable TxRep representation and encodes the result as
    /// a base64-encoded XDR transaction envelope. Supports V0, V1, and fee-bump
    /// envelopes. Handles legacy preconditions format and unsigned transactions.
    ///
    /// - Parameter txRep: Human-readable TxRep string.
    /// - Returns: Base64-encoded transaction envelope XDR.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(txRep: String) throws -> String {
        let map = TxRepHelper.parse(txRep)
        let envelope = try TransactionEnvelopeXDR.fromTxRep(map, prefix: "")
        var encoded = try XDREncoder.encode(envelope)
        return Data(bytes: &encoded, count: encoded.count).base64EncodedString()
    }
}
