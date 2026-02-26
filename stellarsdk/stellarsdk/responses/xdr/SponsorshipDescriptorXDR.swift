//
//  SponsorshipDescriptorXDR.swift
//  stellarsdk
//
//  Hand-written wrapper for XDR typedef AccountID* SponsorshipDescriptor.
//  Each instance wraps an optional PublicKey with per-element present/absent
//  flag encoding, enabling standard array decode for [SponsorshipDescriptorXDR].
//

import Foundation

public struct SponsorshipDescriptorXDR: XDRCodable, Sendable {
    public var value: PublicKey?

    public init(_ value: PublicKey? = nil) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let present = try container.decode(UInt32.self)
        if present != 0 {
            value = try container.decode(PublicKey.self)
        } else {
            value = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        if let val = value {
            try container.encode(UInt32(1))
            try container.encode(val)
        } else {
            try container.encode(UInt32(0))
        }
    }
}
