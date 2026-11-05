//
//  LedgerEntry.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar ledger entry with its key, XDR value, and validity metadata.
public struct LedgerEntry: Decodable, Sendable {

    /// The key of the ledger entry (serialized in a base64 string)
    public let key:String

    /// The current value of the given ledger entry (serialized in a base64 string)
    public let xdr:String

    /// The ledger sequence number of the last time this entry was updated.
    public let lastModifiedLedgerSeq:Int

    /// The ledger sequence number after which the ledger entry would expire. This field exists only for ContractCodeEntry and ContractDataEntry ledger entries (optional).
    public let liveUntilLedgerSeq:Int?

    /// The entry extension from the "extXdr" response key, encoded as base64 XDR. Available for protocol version >= 23.
    public let ext:String?


    private enum CodingKeys: String, CodingKey {
        case key
        case xdr
        case lastModifiedLedgerSeq
        case liveUntilLedgerSeq
        case ext = "extXdr"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        xdr = try values.decode(String.self, forKey: .xdr)
        lastModifiedLedgerSeq = try values.decode(Int.self, forKey: .lastModifiedLedgerSeq)
        liveUntilLedgerSeq = try values.decodeIfPresent(Int.self, forKey: .liveUntilLedgerSeq)
        ext = try values.decodeIfPresent(String.self, forKey: .ext)
    }

    /// The key decoded as a LedgerKeyXDR, or nil if decoding fails.
    public var ledgerKeyXdr: LedgerKeyXDR? {
        return try? LedgerKeyXDR(fromBase64: key)
    }

    /// The key bytes decoded as an `SCValXDR`. The key is a `LedgerKeyXDR`, so the result
    /// does not represent the key; `ledgerKeyXdr` decodes it.
    @available(*, deprecated, message: "keyXdrValue decodes the LedgerKey as an SCValXDR; use ledgerKeyXdr.")
    public var keyXdrValue: SCValXDR? {
        return try? SCValXDR.fromXdr(base64: key)
    }

    /// Converst the valzue to a LedgerEntryDataXDR if valid
    public var valueXdr: LedgerEntryDataXDR? {
        return try? LedgerEntryDataXDR(fromBase64: xdr)
    }
}
