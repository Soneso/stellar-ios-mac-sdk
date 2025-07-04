//
//  TransactionEvents.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.07.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public class TransactionEvents: NSObject, Decodable {
    public var diagnosticEventsXdr:[String]?
    public var transactionEventsXdr:[String]?
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
