//
//  TransactionResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

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
    
    public var memo:Memo?
    
    public var signatures:[String]
    
    public var transactionEnvelope: TransactionEnvelopeXDR
    public var transactionResult: TransactionResultXDR
    public var transactionMeta: TransactionMetaXDR
    
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
        case memo = "memo"
        case signatures
        case envelopeXDR = "envelope_xdr"
        case transactionResult = "result_xdr"
        case transactionMeta = "result_meta_xdr"
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
        
        if memoType == "none" {
            memo = Memo.none
        } else {
            let memo = try values.decodeIfPresent(String.self, forKey: .memo)
            if memoType == "text" {
                try self.memo = Memo(text: memo ?? "")
            } else if memoType == "id" {
                if let m = memo, let memoId = UInt64(m) {
                    self.memo = .id(memoId)
                }
            } else if memoType == "hash" {
                if let m = memo , let data = Data(base64Encoded: m) {
                    try self.memo = Memo(hash: data)
                }
            } else if memoType == "return" {
                if let m = memo , let data = Data(base64Encoded: m) {
                    try self.memo = Memo(returnHash: data)
                }
            } else {
                throw StellarSDKError.decodingError(message: "Unknown memo type.")
            }
        }
        
        signatures = try values.decode([String].self, forKey: .signatures)
        
        let encodedEnvelope = try values.decode(String.self, forKey: .envelopeXDR)
        let data = Data(base64Encoded: encodedEnvelope)!
        transactionEnvelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data:data)
        
        let encodedResult = try values.decode(String.self, forKey: .transactionResult)
        let resultData = Data(base64Encoded: encodedResult)!
        transactionResult = try XDRDecoder.decode(TransactionResultXDR.self, data:resultData)
        
        let encodedMeta = try values.decode(String.self, forKey: .transactionMeta)
        let metaData = Data(base64Encoded: encodedMeta)!
        transactionMeta = try XDRDecoder.decode(TransactionMetaXDR.self, data:metaData)
    }
}
