//
//  MuxedAccountMed25519XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct MuxedAccountMed25519XDR: XDRCodable, Sendable {
    public let id: UInt64
    public let sourceAccountEd25519: [UInt8]
    
    public init(id: UInt64, sourceAccountEd25519: [UInt8]) {
        self.id = id
        self.sourceAccountEd25519 = sourceAccountEd25519
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        id = try container.decode(UInt64.self)
        let wrappedData = try container.decode(WrappedData32.self)
        self.sourceAccountEd25519 = wrappedData.wrapped.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            [UInt8](UnsafeBufferPointer(start: rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), count: wrappedData.wrapped.count))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(id)
        var bytesArray = sourceAccountEd25519
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }
    
    public func toMuxedAccountMed25519XDRInverted() -> MuxedAccountMed25519XDRInverted {
        return MuxedAccountMed25519XDRInverted(id: self.id, sourceAccountEd25519: self.sourceAccountEd25519)
    }
    
    public var accountId: String {
        let muxedAccountXdr = MuxedAccountXDR.med25519(self)
        do {
            var muxEncoded = try XDREncoder.encode(muxedAccountXdr)
            let muxData = Data(bytes: &muxEncoded, count: muxEncoded.count)
            return try muxData.encodeMuxedAccount()
        } catch {
            return ""
        }
    }
    
}

public struct MuxedAccountMed25519XDRInverted: XDRCodable, Sendable {
    public let id: UInt64
    public let sourceAccountEd25519: [UInt8]
    
    public init(id: UInt64, sourceAccountEd25519: [UInt8]) {
        self.id = id
        self.sourceAccountEd25519 = sourceAccountEd25519
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let wrappedData = try container.decode(WrappedData32.self)
        self.sourceAccountEd25519 = wrappedData.wrapped.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            [UInt8](UnsafeBufferPointer(start: rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), count: wrappedData.wrapped.count))
        }
        id = try container.decode(UInt64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        var bytesArray = sourceAccountEd25519
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
        try container.encode(id)
    }
    
    public func toMuxedAccountMed25519XDR() -> MuxedAccountMed25519XDR {
        return MuxedAccountMed25519XDR(id: self.id, sourceAccountEd25519: self.sourceAccountEd25519)
    }
}

// MARK: - TxRep
//
// Hand-written TxRep for MuxedAccountMed25519XDR because this struct is
// in SKIP_TYPES (not emitted by the generator) but is reachable from
// SCAddressXDR.muxedAccount, which does get a generated union TxRep.
//
// The serialized representation follows the SEP-0011 M... strkey encoding
// via the pre-existing accountId accessor (which wraps the struct in a
// MuxedAccountXDR and invokes the M-strkey formatter). Parsing reverses the
// transformation by decoding the M-strkey through the existing TxRepHelper
// and extracting the inner med25519 arm.
extension MuxedAccountMed25519XDR {
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        lines.append("\(prefix): \(self.accountId)")
    }

    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> MuxedAccountMed25519XDR {
        guard let raw = TxRepHelper.getValue(map, prefix) else {
            throw TxRepError.missingValue(key: prefix)
        }
        let parsed = try TxRepHelper.parseMuxedAccount(raw)
        if case .med25519(let inner) = parsed {
            return inner
        }
        throw TxRepError.invalidValue(key: prefix)
    }
}
