//
//  TransactionResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum MemoType: Int {
    case none = 0
    case text = 1
    case id = 2
    case hash = 3
    case `return` = 4
}

///  Represents a transaction response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/transaction.html "Transaction")
public class TransactionResponse: NSObject, Decodable {
    
    /// A list of links related to this asset.
    public var links:TransactionLinksResponse
    
    /// The id of this transaction.
    public var id:String
    
    /// A paging token suitable for use as the cursor parameter to transaction collection resources.
    public var pagingToken:String
    
    /// A hex-encoded SHA-256 hash of the transaction’s XDR-encoded form.
    public var transactionHash:String
    
    /// Sequence number of the ledger in which this transaction was applied.
    public var ledger:Int
    
    /// Date created.
    public var createdAt:Date
    
    /// The account that originates the transaction.
    public var sourceAccount:String
    
    /// The current transaction sequence number of the source account.
    public var sourceAccountSequence:String
    
    /// The fee paid by the source account of this transaction when the transaction was applied to the ledger.
    public var feePaid:Int
    
    /// The number of operations that are contained within this transaction.
    public var operationCount:Int
    
    /// The memo type. See enum MemoType. The memo contains optional extra information.
    public var memoType:String
    
    
    public var signatures:[String]
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case transactionHash = "hash"
        case ledger
        case createdAt = "created_at"
        case sourceAccount = "source_account"
        case sourceAccountSequence = "source_account_sequence"
        case feePaid = "fee_paid"
        case operationCount = "operation_count"
        case memoType = "memo_type"
        case signatures
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(TransactionLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        ledger = try values.decode(Int.self, forKey: .ledger)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        sourceAccount = try values.decode(String.self, forKey: .sourceAccount)
        sourceAccountSequence = try values.decode(String.self, forKey: .sourceAccountSequence)
        feePaid = try values.decode(Int.self, forKey: .feePaid)
        operationCount = try values.decode(Int.self, forKey: .operationCount)
        memoType = try values.decode(String.self, forKey: .memoType)
        signatures = try values.decode([String].self, forKey: .signatures)
    }
}
