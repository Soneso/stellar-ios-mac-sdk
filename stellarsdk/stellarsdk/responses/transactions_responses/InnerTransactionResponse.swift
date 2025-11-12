//
//  InnerTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents the inner (original) transaction that has been wrapped by a fee bump transaction.
///
/// When a transaction is wrapped in a fee bump, this response contains details about the original
/// transaction including its hash, signatures, and max fee. The fee bump transaction replaces the
/// fee but preserves the operations and original signatures.
///
/// This response is included in TransactionResponse for fee bump transactions.
///
/// See also:
/// - [Fee Bump Transactions](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/fee-bump-transactions)
/// - FeeBumpTransactionResponse for the wrapper transaction details
/// - TransactionResponse for complete transaction information
public class InnerTransactionResponse: NSObject, Decodable {

    /// Hex-encoded SHA-256 hash of the inner (original) transaction.
    public var transactionHash:String // hash

    /// Array of base64-encoded signatures from the original transaction.
    public var signatures:[String]

    /// Maximum fee (in stroops) specified in the original transaction before fee bump.
    public var maxFee:String
    
    private enum CodingKeys: String, CodingKey {
        case transactionHash = "hash"
        case signatures
        case maxFee = "max_fee"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        signatures = try values.decode([String].self, forKey: .signatures)
        maxFee = try values.decode(String.self, forKey: .maxFee)
    }
}
