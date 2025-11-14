//
//  TransactionEvents.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.07.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Container for Soroban transaction diagnostic and execution events in XDR format.
public class TransactionEvents: NSObject, Decodable {

    /// XDR-encoded diagnostic events for debugging transaction execution.
    public var diagnosticEventsXdr:[String]?

    /// XDR-encoded transaction events emitted during execution.
    public var transactionEventsXdr:[String]?

    /// XDR-encoded contract events grouped by operation index.
    public var contractEventsXdr:[[String]]?
    
    private enum CodingKeys: String, CodingKey {
        case diagnosticEventsXdr
        case transactionEventsXdr
        case contractEventsXdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        diagnosticEventsXdr = try values.decodeIfPresent([String].self, forKey: .diagnosticEventsXdr)
        transactionEventsXdr = try values.decodeIfPresent([String].self, forKey: .transactionEventsXdr)
        contractEventsXdr = try values.decodeIfPresent([[String]].self, forKey: .contractEventsXdr)
        
    }
}
