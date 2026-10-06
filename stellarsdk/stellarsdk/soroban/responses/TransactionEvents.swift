//
//  TransactionEvents.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.07.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Container for the transaction and contract events of a Soroban transaction in XDR format.
public struct TransactionEvents: Decodable, Sendable {

    /// Backing storage for the deprecated diagnosticEventsXdr property.
    private let _diagnosticEventsXdr:[String]?

    /// XDR-encoded diagnostic events from the `diagnosticEventsXdr` key of the events object.
    @available(*, deprecated, message: "stellar-rpc does not send this field; read diagnosticEventsXdr of GetTransactionResponse or TransactionInfo.")
    public var diagnosticEventsXdr:[String]? { _diagnosticEventsXdr }

    /// XDR-encoded transaction events emitted during execution.
    public let transactionEventsXdr:[String]?

    /// XDR-encoded contract events grouped by operation index.
    public let contractEventsXdr:[[String]]?

    private enum CodingKeys: String, CodingKey {
        case diagnosticEventsXdr
        case transactionEventsXdr
        case contractEventsXdr
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _diagnosticEventsXdr = try values.decodeIfPresent([String].self, forKey: .diagnosticEventsXdr)
        transactionEventsXdr = try values.decodeIfPresent([String].self, forKey: .transactionEventsXdr)
        contractEventsXdr = try values.decodeIfPresent([[String]].self, forKey: .contractEventsXdr)

    }
}
