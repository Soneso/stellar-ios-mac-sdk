//
//  GetTransactionsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Response containing an array of Soroban transaction records from RPC queries.
public struct GetTransactionsResponse: Decodable, Sendable {

    /// Array of transaction records from Soroban RPC.
    public let transactions:[TransactionInfo]

    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public let latestLedger:Int

    /// The unix timestamp of the close time of the latest ledger known to Soroban RPC at the time it handled the request.
    public let latestLedgerCloseTimestamp:Int

    /// The sequence number of the oldest ledger ingested by Soroban RPC at the time it handled the request.
    public let oldestLedger:Int

    /// The unix timestamp of the close time of the oldest ledger ingested by Soroban RPC at the time it handled the request.
    public let oldestLedgerCloseTimestamp:Int

    /// For pagination
    public let cursor:String?

    private enum CodingKeys: String, CodingKey {
        case transactions
        case latestLedger
        case latestLedgerCloseTimestamp
        case oldestLedger
        case oldestLedgerCloseTimestamp
        case cursor
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let txs = try? values.decode([TransactionInfo].self, forKey: .transactions) {
            transactions = txs
        } else {
            transactions = []
        }
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        latestLedgerCloseTimestamp = try values.decode(Int.self, forKey: .latestLedgerCloseTimestamp)
        oldestLedger = try values.decode(Int.self, forKey: .oldestLedger)
        oldestLedgerCloseTimestamp = try values.decode(Int.self, forKey: .oldestLedgerCloseTimestamp)
        cursor = try values.decodeIfPresent(String.self, forKey: .cursor)
    }
}

/// Detailed information about a Soroban transaction including status, ledger, and result XDR.
public struct TransactionInfo: Decodable, Sendable {

    /// Indicates whether the transaction was successful or not.
    public let status:String

    /// The 1-based index of the transaction among all transactions included in the ledger.
    public let applicationOrder:Int

    /// Indicates whether the transaction was fee bumped.
    public let feeBump:Bool

    /// A base64 encoded string of the raw TransactionEnvelope XDR struct for this transaction.
    public let envelopeXdr:String

    /// A base64 encoded string of the raw TransactionResult XDR struct for this transaction.
    public let resultXdr:String

    /// A base64 encoded string of the raw TransactionMeta XDR struct for this transaction.
    public let resultMetaXdr:String

    /// (optional) A base64 encoded slice of xdr.DiagnosticEvent. This is only present if the ENABLE_SOROBAN_DIAGNOSTIC_EVENTS has been enabled in the stellar-core config.
    public let diagnosticEventsXdr:[String]?

    /// The sequence number of the ledger which included the transaction.
    public let ledger:Int

    /// The unix timestamp of when the transaction was included in the ledger.
    public let createdAt:Int

    /// hex-encoded transaction hash string. Only available for protocol version >= 22
    public let txHash:String?

    /// events for the transaction. Only available for protocol version >= 23
    public let events:TransactionEvents?
    
    private enum CodingKeys: String, CodingKey {
        case status
        case applicationOrder
        case feeBump
        case envelopeXdr
        case resultXdr
        case resultMetaXdr
        case diagnosticEventsXdr
        case ledger
        case createdAt
        case txHash
        case events
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        applicationOrder = try values.decode(Int.self, forKey: .applicationOrder)
        feeBump = try values.decode(Bool.self, forKey: .feeBump)
        envelopeXdr = try values.decode(String.self, forKey: .envelopeXdr)
        resultXdr = try values.decode(String.self, forKey: .resultXdr)
        resultMetaXdr = try values.decode(String.self, forKey: .resultMetaXdr)
        diagnosticEventsXdr = try values.decodeIfPresent([String].self, forKey: .diagnosticEventsXdr)
        ledger = try values.decode(Int.self, forKey: .ledger)
        var createdAtIntVal:Int?
        do {
            createdAtIntVal = try values.decodeIfPresent(Int.self, forKey: .createdAt)
        } catch {}
        if (createdAtIntVal != nil) {
            createdAt = createdAtIntVal!
        } else {
            let createStringAt = try values.decode(String.self, forKey: .createdAt)
            createdAt = Int(createStringAt) ?? 0
        }
        
        txHash = try values.decodeIfPresent(String.self, forKey: .txHash) // protocol version >= 22
        events = try values.decodeIfPresent(TransactionEvents.self, forKey: .events) // protocol version >= 23
    }
}
