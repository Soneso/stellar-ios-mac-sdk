//
//  PublicKey+XdrJson.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// XDR-JSON conversion for the account key types the generator does not emit.
///
/// `PublicKey`, `MuxedAccount` and the muxed account body are hand-maintained in this SDK,
/// so their conversions are written here rather than generated. All three render as a
/// strkey: [SEP-0051](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md)
/// §Public Key gives the ed25519 key its `G` form and the muxed account its `M` form,
/// neither of which is the keyed-arm shape a union would otherwise take.
extension PublicKey: XdrJsonCodable {
    public func toXdrJsonValue() throws -> XdrJsonValue {
        .string(try XdrJson.strKey(Data(self.bytes), expectedLength: 32,
                                   type: "PublicKey", key: nil) { try $0.encodeEd25519PublicKey() })
    }

    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> PublicKey {
        let text = try XdrJson.string(value, type: "PublicKey")
        let raw = try XdrJson.strKeyBytes(text, expectedLength: 32,
                                          type: "PublicKey", key: nil) { try $0.decodeEd25519PublicKey() }
        return try PublicKey([UInt8](raw))
    }
}

extension MuxedAccountXDR: XdrJsonCodable {
    public func toXdrJsonValue() throws -> XdrJsonValue {
        switch self {
        case .ed25519(let key):
            return .string(try XdrJson.strKey(Data(key), expectedLength: 32,
                                              type: "MuxedAccountXDR", key: "ed25519") { try $0.encodeEd25519PublicKey() })
        case .med25519(let muxed):
            return try muxed.toXdrJsonValue()
        }
    }

    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> MuxedAccountXDR {
        let text = try XdrJson.string(value, type: "MuxedAccountXDR")
        switch text.first {
        case "G":
            let raw = try XdrJson.strKeyBytes(text, expectedLength: 32,
                                              type: "MuxedAccountXDR", key: "ed25519") { try $0.decodeEd25519PublicKey() }
            return .ed25519([UInt8](raw))
        case "M":
            return .med25519(try MuxedAccountMed25519XDR.fromXdrJsonValue(value))
        default:
            throw XdrJsonError.invalidValue(
                type: "MuxedAccountXDR", key: nil,
                message: "not an account or muxed account strkey: \(XdrJson.preview(text))")
        }
    }
}

/// The `M` strkey packs the ed25519 key ahead of the identifier, the reverse of the XDR
/// body, which is the order `MuxedAccountMed25519XDRInverted` already models.
extension MuxedAccountMed25519XDR: XdrJsonCodable {
    public func toXdrJsonValue() throws -> XdrJsonValue {
        guard self.sourceAccountEd25519.count == 32 else {
            throw XdrJsonError.invalidValue(
                type: "MuxedAccountMed25519XDR", key: "ed25519",
                message: "expected 32 bytes, got \(self.sourceAccountEd25519.count)")
        }
        let encoded = Data(try XDREncoder.encode(self.toMuxedAccountMed25519XDRInverted()))
        return .string(try XdrJson.strKey(encoded, expectedLength: 40,
                                          type: "MuxedAccountMed25519XDR", key: nil) { try $0.encodeMEd25519AccountId() })
    }

    public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> MuxedAccountMed25519XDR {
        let text = try XdrJson.string(value, type: "MuxedAccountMed25519XDR")
        let raw = try XdrJson.strKeyBytes(text, expectedLength: 40,
                                          type: "MuxedAccountMed25519XDR", key: nil) { try $0.decodeMed25519PublicKey() }
        let inverted = try XDRDecoder.decode(MuxedAccountMed25519XDRInverted.self, data: [UInt8](raw))
        return inverted.toMuxedAccountMed25519XDR()
    }
}
