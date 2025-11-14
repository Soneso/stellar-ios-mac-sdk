//
//  LedgerInfo.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 05.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Represents a single ledger in the getLedgers response.
/// See: [Stellar developer docs](https://developers.stellar.org)
public class LedgerInfo: NSObject, Decodable {

    /// Hash of the ledger as a hex-encoded string
    public var ledgerHash: String

    /// Sequence number of the ledger
    public var sequence: UInt32

    /// The unix timestamp of the close time of the ledger
    public var ledgerCloseTime: String

    /// Base64-encoded ledger header XDR
    public var headerXdr: String?

    /// JSON representation of the ledger header (if requested with format=json)
    public var headerJson: [String: Any]?

    /// Base64-encoded ledger metadata XDR
    public var metadataXdr: String?

    /// JSON representation of the ledger metadata (if requested with format=json)
    public var metadataJson: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case ledgerHash = "hash"
        case sequence
        case ledgerCloseTime
        case headerXdr
        case headerJson
        case metadataXdr
        case metadataJson
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ledgerHash = try values.decode(String.self, forKey: .ledgerHash)
        sequence = try values.decode(UInt32.self, forKey: .sequence)
        ledgerCloseTime = try values.decode(String.self, forKey: .ledgerCloseTime)
        headerXdr = try values.decodeIfPresent(String.self, forKey: .headerXdr)
        metadataXdr = try values.decodeIfPresent(String.self, forKey: .metadataXdr)

        // Decode JSON fields as dictionaries if present
        if let headerJsonData = try? values.decodeIfPresent(Data.self, forKey: .headerJson) {
            headerJson = try? JSONSerialization.jsonObject(with: headerJsonData, options: []) as? [String: Any]
        }

        if let metadataJsonData = try? values.decodeIfPresent(Data.self, forKey: .metadataJson) {
            metadataJson = try? JSONSerialization.jsonObject(with: metadataJsonData, options: []) as? [String: Any]
        }
    }
}
