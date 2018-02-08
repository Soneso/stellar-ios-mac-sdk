//
//  Transaction.swift
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

public class Transaction: NSObject, Codable {
    public var id:String
    public var pagingToken:String
    public var transactionHash:String
    public var ledger:Int
    public var createdAt:Date
    public var sourceAccount:String
    public var sourceAccountSequence:String
    public var feePaid:Int
    public var operationCount:Int
    public var memoType:String
    public var signatures:[String]
    
    private enum CodingKeys: String, CodingKey {
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pagingToken, forKey: .pagingToken)
        try container.encode(transactionHash, forKey: .transactionHash)
        try container.encode(ledger, forKey: .ledger)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sourceAccount, forKey: .sourceAccount)
        try container.encode(sourceAccountSequence, forKey: .sourceAccountSequence)
        try container.encode(feePaid, forKey: .feePaid)
        try container.encode(operationCount, forKey: .operationCount)
        try container.encode(memoType, forKey: .memoType)
        try container.encode(signatures, forKey: .signatures)
    }
    
}
