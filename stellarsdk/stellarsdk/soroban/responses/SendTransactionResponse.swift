//
//  SendTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response from submitting a transaction to the Stellar network.
///
/// After calling sendTransaction, this response indicates whether the transaction
/// was accepted for processing. Note that acceptance does not mean the transaction
/// has executed - you must poll with getTransaction to check final status.
///
/// Status values:
/// - PENDING: Transaction accepted and waiting to be included in a ledger
/// - DUPLICATE: Transaction already submitted (same hash exists)
/// - TRY_AGAIN_LATER: Server is busy, retry the submission
/// - ERROR: Transaction rejected (check error field for details)
///
/// After receiving a PENDING status, use getTransaction with the returned
/// transactionId (hash) to poll for completion.
///
/// Example:
/// ```swift
/// let sendResponse = await server.sendTransaction(transaction: signedTx)
/// switch sendResponse {
/// case .success(let result):
///     switch result.status {
///     case SendTransactionResponse.STATUS_PENDING:
///         print("Transaction submitted: \(result.transactionId)")
///         // Poll for status with getTransaction
///     case SendTransactionResponse.STATUS_ERROR:
///         print("Transaction rejected: \(result.error?.message ?? "unknown")")
///     default:
///         print("Status: \(result.status)")
///     }
/// case .failure(let error):
///     print("RPC error: \(error)")
/// }
/// ```
///
/// See also:
/// - [SorobanServer.sendTransaction] for submitting transactions
/// - [GetTransactionResponse] for polling transaction status
/// - [Stellar developer docs](https://developers.stellar.org)
public class SendTransactionResponse: NSObject, Decodable {

    /// Transaction pending in queue.
    public static let STATUS_PENDING = "PENDING"
    /// Transaction is a duplicate submission.
    public static let STATUS_DUPLICATE = "DUPLICATE"
    /// Temporary failure, retry submission.
    public static let STATUS_TRY_AGAIN_LATER = "TRY_AGAIN_LATER"
    /// Transaction submission error.
    public static let STATUS_ERROR = "ERROR"

    /// The transaction hash identifier.
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

    /// Base64-encoded XDR of the transaction error result if the transaction failed.
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
            var events: [DiagnosticEventXDR] = []
            for xdrEntry in xdrEntries {
                events.append(try DiagnosticEventXDR(fromBase64: xdrEntry))
            }
            diagnosticEvents = events
        }
    }
}
