//
//  LedgerEntry.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class LedgerEntry: NSObject, Decodable {
    
    /// The key of the ledger entry (serialized in a base64 string)
    public var key:String
    
    /// The current value of the given ledger entry (serialized in a base64 string)
    public var xdr:String
    
    /// The ledger sequence number of the last time this entry was updated.
    public var lastModifiedLedgerSeq:String
    
    /// The ledger sequence number after which the ledger entry would expire. This field exists only for ContractCodeEntry and ContractDataEntry ledger entries (optional).
    public var expirationLedgerSeq:String?
    
    
    private enum CodingKeys: String, CodingKey {
        case key
        case xdr
        case lastModifiedLedgerSeq
        case expirationLedgerSeq
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        xdr = try values.decode(String.self, forKey: .xdr)
        lastModifiedLedgerSeq = try values.decode(String.self, forKey: .lastModifiedLedgerSeq)
        expirationLedgerSeq = try values.decodeIfPresent(String.self, forKey: .expirationLedgerSeq)
    }
}
