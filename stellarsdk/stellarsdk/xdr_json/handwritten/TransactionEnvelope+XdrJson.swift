//
//  TransactionEnvelope+XdrJson.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// XDR-JSON conversion for the three transaction envelopes the generator does not emit.
///
/// Each envelope carries the same two keys,
/// [SEP-0051](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md)
/// §Struct applied to `tx` and `signatures`.
///
/// These three are classes rather than structs, and not final ones, so they carry the five
/// conversion members directly instead of conforming to ``XdrJsonCodable``: satisfying that
/// protocol's `Self`-returning requirement would need a `required` initializer on a public
/// class, which is a source-breaking change to an API this feature does not otherwise
/// touch. Callers see the same members either way.
extension TransactionV0EnvelopeXDR {
    /// This envelope as an XDR-JSON tree.
    public func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(key: "tx", value: try self.tx.toXdrJsonValue()))
        members.append(XdrJsonMember(
            key: "signatures",
            value: XdrJson.array(try self.signatures.map { element in try element.toXdrJsonValue() })))
        return .object(members)
    }

    /// This envelope as canonical XDR-JSON text.
    public func toXdrJson() throws -> String {
        try XdrJsonWriter.canonicalString(from: try toXdrJsonValue())
    }

    /// Reads an envelope from an XDR-JSON tree.
    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> TransactionV0EnvelopeXDR {
        let members = try XdrJson.object(value, type: "TransactionV0EnvelopeXDR",
                                         keys: ["tx", "signatures"])
        let tx = try TransactionV0XDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "tx", type: "TransactionV0EnvelopeXDR"))
        let signatureValues = try XdrJson.array(
            try XdrJson.field(members, key: "signatures", type: "TransactionV0EnvelopeXDR"),
            type: "TransactionV0EnvelopeXDR", key: "signatures")
        let signatures = try signatureValues.map { element in
            try DecoratedSignatureXDR.fromXdrJsonValue(element)
        }
        return TransactionV0EnvelopeXDR(tx: tx, signatures: signatures)
    }

    /// Reads an envelope from XDR-JSON text.
    public static func fromXdrJson(_ json: String) throws -> TransactionV0EnvelopeXDR {
        try fromXdrJsonValue(try XdrJsonParser.parse(json))
    }

    /// Reads an envelope from a tree built by hand rather than parsed, bounding its nesting
    /// first.
    public static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> TransactionV0EnvelopeXDR {
        try XdrJson.validateDepth(value)
        return try fromXdrJsonValue(value)
    }
}

extension TransactionV1EnvelopeXDR {
    /// This envelope as an XDR-JSON tree.
    public func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(key: "tx", value: try self.tx.toXdrJsonValue()))
        members.append(XdrJsonMember(
            key: "signatures",
            value: XdrJson.array(try self.signatures.map { element in try element.toXdrJsonValue() })))
        return .object(members)
    }

    /// This envelope as canonical XDR-JSON text.
    public func toXdrJson() throws -> String {
        try XdrJsonWriter.canonicalString(from: try toXdrJsonValue())
    }

    /// Reads an envelope from an XDR-JSON tree.
    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> TransactionV1EnvelopeXDR {
        let members = try XdrJson.object(value, type: "TransactionV1EnvelopeXDR",
                                         keys: ["tx", "signatures"])
        let tx = try TransactionXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "tx", type: "TransactionV1EnvelopeXDR"))
        let signatureValues = try XdrJson.array(
            try XdrJson.field(members, key: "signatures", type: "TransactionV1EnvelopeXDR"),
            type: "TransactionV1EnvelopeXDR", key: "signatures")
        let signatures = try signatureValues.map { element in
            try DecoratedSignatureXDR.fromXdrJsonValue(element)
        }
        return TransactionV1EnvelopeXDR(tx: tx, signatures: signatures)
    }

    /// Reads an envelope from XDR-JSON text.
    public static func fromXdrJson(_ json: String) throws -> TransactionV1EnvelopeXDR {
        try fromXdrJsonValue(try XdrJsonParser.parse(json))
    }

    /// Reads an envelope from a tree built by hand rather than parsed, bounding its nesting
    /// first.
    public static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> TransactionV1EnvelopeXDR {
        try XdrJson.validateDepth(value)
        return try fromXdrJsonValue(value)
    }
}

extension FeeBumpTransactionEnvelopeXDR {
    /// This envelope as an XDR-JSON tree.
    public func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(key: "tx", value: try self.tx.toXdrJsonValue()))
        members.append(XdrJsonMember(
            key: "signatures",
            value: XdrJson.array(try self.signatures.map { element in try element.toXdrJsonValue() })))
        return .object(members)
    }

    /// This envelope as canonical XDR-JSON text.
    public func toXdrJson() throws -> String {
        try XdrJsonWriter.canonicalString(from: try toXdrJsonValue())
    }

    /// Reads an envelope from an XDR-JSON tree.
    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> FeeBumpTransactionEnvelopeXDR {
        let members = try XdrJson.object(value, type: "FeeBumpTransactionEnvelopeXDR",
                                         keys: ["tx", "signatures"])
        let tx = try FeeBumpTransactionXDR.fromXdrJsonValue(
            try XdrJson.field(members, key: "tx", type: "FeeBumpTransactionEnvelopeXDR"))
        let signatureValues = try XdrJson.array(
            try XdrJson.field(members, key: "signatures", type: "FeeBumpTransactionEnvelopeXDR"),
            type: "FeeBumpTransactionEnvelopeXDR", key: "signatures")
        let signatures = try signatureValues.map { element in
            try DecoratedSignatureXDR.fromXdrJsonValue(element)
        }
        return FeeBumpTransactionEnvelopeXDR(tx: tx, signatures: signatures)
    }

    /// Reads an envelope from XDR-JSON text.
    public static func fromXdrJson(_ json: String) throws -> FeeBumpTransactionEnvelopeXDR {
        try fromXdrJsonValue(try XdrJsonParser.parse(json))
    }

    /// Reads an envelope from a tree built by hand rather than parsed, bounding its nesting
    /// first.
    public static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> FeeBumpTransactionEnvelopeXDR {
        try XdrJson.validateDepth(value)
        return try fromXdrJsonValue(value)
    }
}
