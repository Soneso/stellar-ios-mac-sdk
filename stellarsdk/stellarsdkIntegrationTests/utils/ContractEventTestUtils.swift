//
//  ContractEventTestUtils.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

/// The reason an event helper could not return what a test asked for. A test that lets it
/// propagate fails with `description`.
struct ContractEventTestError: Error, CustomStringConvertible {
    let description: String
}

/// Decodes the contract events of a transaction, in the order the RPC server reports them:
/// operation by operation, and within an operation in the order of emission.
///
/// A response without events, such as one of a transaction that is not confirmed, gives an
/// empty list.
///
/// - Throws: The decoding error of an event that is not a valid `ContractEventXDR`.
func contractEvents(of response: GetTransactionResponse) throws -> [ContractEventXDR] {
    let encodedEvents = (response.events?.contractEventsXdr ?? []).flatMap { $0 }
    return try encodedEvents.map { try ContractEventXDR(xdr: $0) }
}

/// Returns the single contract event of a transaction whose first topic is the symbol
/// `transfer`, the event a token contract emits for a transfer.
///
/// - Throws: `ContractEventTestError` when the transaction has no such event or more than
///   one, so a test that expects exactly one transfer fails.
func transferEvent(in response: GetTransactionResponse) throws -> ContractEventXDR {
    let transfers = try contractEvents(of: response).filter { event in
        switch event.body {
        case .v0(let body):
            return body.topics.first?.symbol == "transfer"
        }
    }
    guard transfers.count == 1 else {
        throw ContractEventTestError(description: "Expected exactly one transfer event in transaction \(response.txHash ?? "without a hash"), found \(transfers.count)")
    }
    return transfers[0]
}

/// Returns the data of a contract event whose data is a map, as a dictionary from each
/// symbol key to its value. Entries with a key of another type are left out.
///
/// - Throws: `ContractEventTestError` when the data of the event is not a map, as for a
///   transfer to a destination without a multiplexing id, whose data is the bare amount.
func eventDataMap(_ event: ContractEventXDR) throws -> [String: SCValXDR] {
    let data: SCValXDR
    switch event.body {
    case .v0(let body):
        data = body.data
    }
    guard let entries = data.map else {
        throw ContractEventTestError(description: "Expected the event data to be a map, got \(data)")
    }
    var values: [String: SCValXDR] = [:]
    for entry in entries {
        if let key = entry.key.symbol {
            values[key] = entry.val
        }
    }
    return values
}
