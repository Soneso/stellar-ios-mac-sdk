//
//  SendTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response when submitting a real transaction to the stellar network.
/// See:  https://developers.stellar.org/network/soroban-rpc/api-reference/methods/sendTransaction
public class SendTransactionResponse: NSObject, Decodable {
    
    public static let STATUS_PENDING = "PENDING"
    public static let STATUS_DUPLICATE = "DUPLICATE"
    public static let STATUS_TRY_AGAIN_LATER = "TRY_AGAIN_LATER"
    public static let STATUS_ERROR = "ERROR"
    
    /// The transaction hash (in an hex-encoded string)
    public var transactionId:String
    
    /// the current status of the transaction by hash, one of: PENDING, DUPLICATE, TRY_AGAIN_LATER, ERROR
    public var status:String
    
    /// The latest ledger known to Soroban-RPC at the time it handled the sendTransaction() request.
    public var latestLedger:Int
    
    /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the sendTransaction() request.
    public var latestLedgerCloseTime:String
    
    /// (optional) If the transaction was rejected immediately, this will be an error object.
    public var error:TransactionStatusError?
    
    /// (optional) If the transaction status is ERROR, this will be the raw TransactionResult XDR struct containing details on why stellar-core rejected the transaction.
    public var errorResult:TransactionResultXDR?
    
    public var errorResultXdr:String?
    
    /// (optional) If the transaction status is ERROR, this field may be present. Each entry is a raw DiagnosticEvent XDR struct containing details on why stellar-core rejected the transaction.
    public var diagnosticEvents:[DiagnosticEventXDR]?
    
    private enum CodingKeys: String, CodingKey {
        case transactionId = "hash"
        case status
        case latestLedger
        case latestLedgerCloseTime
        case error
        case errorResultXdr
        case diagnosticEventsXdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        status = try values.decode(String.self, forKey: .status)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        latestLedgerCloseTime = try values.decode(String.self, forKey: .latestLedgerCloseTime)
        error = try values.decodeIfPresent(TransactionStatusError.self, forKey: .error)
        if let errorResultXdrStr = try values.decodeIfPresent(String.self, forKey: .errorResultXdr) {
            errorResultXdr = errorResultXdrStr
            errorResult = try? TransactionResultXDR.fromXdr(base64: errorResultXdrStr)
        }
        
        let diagnosticEventsXdr = try values.decodeIfPresent([String].self, forKey: .diagnosticEventsXdr)
        if let xdrEntries = diagnosticEventsXdr {
            diagnosticEvents = []
            for xdrEntry in xdrEntries {
                diagnosticEvents!.append(try DiagnosticEventXDR(fromBase64: xdrEntry))
            }
        }
    }
}
