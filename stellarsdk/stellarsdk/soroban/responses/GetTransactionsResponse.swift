//
//  GetTransactionsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public class GetTransactionsResponse: NSObject, Decodable {
    
    public var transactions:[TransactionInfo]
    
    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public var latestLedger:Int
    
    /// The unix timestamp of the close time of the latest ledger known to Soroban RPC at the time it handled the request.
    public var latestLedgerCloseTimestamp:Int
    
    /// The sequence number of the oldest ledger ingested by Soroban RPC at the time it handled the request.
    public var oldestLedger:Int
    
    /// The unix timestamp of the close time of the oldest ledger ingested by Soroban RPC at the time it handled the request.
    public var oldestLedgerCloseTimestamp:Int
    
    /// For pagination
    public var cursor:String?
    
    private enum CodingKeys: String, CodingKey {
        case transactions
        case latestLedger
        case latestLedgerCloseTimestamp
        case oldestLedger
        case oldestLedgerCloseTimestamp
        case cursor
    }

    public required init(from decoder: Decoder) throws {
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

public class TransactionInfo: NSObject, Decodable {
    
    /// Indicates whether the transaction was successful or not.
    public var status:String
    
    /// The 1-based index of the transaction among all transactions included in the ledger.
    public var applicationOrder:Int
    
    /// Indicates whether the transaction was fee bumped.
    public var feeBump:Bool
    
    /// A base64 encoded string of the raw TransactionEnvelope XDR struct for this transaction.
    public var envelopeXdr:String
    
    /// A base64 encoded string of the raw TransactionResult XDR struct for this transaction.
    public var resultXdr:String
    
    /// A base64 encoded string of the raw TransactionMeta XDR struct for this transaction.
    public var resultMetaXdr:String
    
    /// (optional) A base64 encoded slice of xdr.DiagnosticEvent. This is only present if the ENABLE_SOROBAN_DIAGNOSTIC_EVENTS has been enabled in the stellar-core config.
    public var diagnosticEventsXdr:[String]?
    
    /// The sequence number of the ledger which included the transaction.
    public var ledger:Int
    
    /// The unix timestamp of when the transaction was included in the ledger.
    public var createdAt:String
    
    /// hex-encoded transaction hash string. Only available for protocol version >= 22
    public var txHash:String?
    
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
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        applicationOrder = try values.decode(Int.self, forKey: .applicationOrder)
        feeBump = try values.decode(Bool.self, forKey: .feeBump)
        envelopeXdr = try values.decode(String.self, forKey: .envelopeXdr)
        resultXdr = try values.decode(String.self, forKey: .resultXdr)
        resultMetaXdr = try values.decode(String.self, forKey: .resultMetaXdr)
        diagnosticEventsXdr = try values.decodeIfPresent([String].self, forKey: .diagnosticEventsXdr)
        ledger = try values.decode(Int.self, forKey: .ledger)
        var createdAtVal:String?
        do {
            createdAtVal = try values.decodeIfPresent(String.self, forKey: .createdAt) // protocol >= 22
        } catch {}
        if (createdAtVal != nil) {
            createdAt = createdAtVal!
        } else {
            let createAtInt = try values.decode(Int.self, forKey: .createdAt) // protocol version <= 22
            createdAt = String(createAtInt)
        }
        
        txHash = try values.decodeIfPresent(String.self, forKey: .txHash) // protocol version >= 22
    }
}
