//
//  MuxedContractXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.10.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `MuxedContractXDR`.
///
/// The value is one line holding its "W..." strkey, the form `MuxedAccountMed25519XDR` gives
/// the muxed account arm of `SCAddressXDR`. The generator emits no TxRep methods for this
/// struct, and the generated muxed contract arm of `SCAddressXDR` delegates to these.
extension MuxedContractXDR {
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        let muxedContractId: String
        do {
            muxedContractId = try toStrKey()
        } catch {
            throw TxRepError.invalidValue(key: prefix)
        }
        lines.append("\(prefix): \(muxedContractId)")
    }

    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> MuxedContractXDR {
        guard let raw = TxRepHelper.getValue(map, prefix) else {
            throw TxRepError.missingValue(key: prefix)
        }
        do {
            return try MuxedContractXDR(muxedContractId: raw)
        } catch {
            throw TxRepError.invalidValue(key: prefix)
        }
    }
}
