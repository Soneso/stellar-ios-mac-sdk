//
//  FeeBumpTransactionEnvelopeXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class FeeBumpTransactionEnvelopeXDR: NSObject, XDRCodable, @unchecked Sendable {
    public let tx: FeeBumpTransactionXDR
    public var signatures: [DecoratedSignatureXDR] {
        lock.lock()
        defer { lock.unlock() }
        return _signatures
    }
    private var _signatures: [DecoratedSignatureXDR]
    private let lock = NSLock()

    public init(tx: FeeBumpTransactionXDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self._signatures = signatures
    }

    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        tx = try container.decode(FeeBumpTransactionXDR.self)
        _signatures = try decodeArray(type: DecoratedSignatureXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(tx)
        lock.lock()
        let sigs = _signatures
        lock.unlock()
        try container.encode(sigs)
    }

    public func appendSignature(_ signature: DecoratedSignatureXDR) {
        lock.lock()
        defer { lock.unlock() }
        _signatures.append(signature)
    }
}
