//
//  SendTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response when submitting a real transaction to the stellar network.
/// See:  https://soroban.stellar.org/api/methods/sendTransaction
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
    
    private enum CodingKeys: String, CodingKey {
        case transactionId = "hash"
        case status
        case latestLedger
        case latestLedgerCloseTime
        case error
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        status = try values.decode(String.self, forKey: .status)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        latestLedgerCloseTime = try values.decode(String.self, forKey: .latestLedgerCloseTime)
        error = try values.decodeIfPresent(TransactionStatusError.self, forKey: .error)
    }
}
