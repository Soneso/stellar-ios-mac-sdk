//
//  FeeBumpTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents the outer fee bump transaction that wraps an inner transaction with a higher fee.
///
/// Fee bump transactions allow one account to pay a higher fee for another account's transaction
/// to prioritize it for inclusion when the network is congested. The fee bump transaction replaces
/// the original transaction's fee but preserves all operations and signatures.
///
/// This response is included in TransactionResponse when the transaction is a fee bump.
///
/// See also:
/// - [Fee Bump Transactions](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/fee-bump-transactions)
/// - InnerTransactionResponse for the wrapped transaction details
/// - TransactionResponse for complete transaction information
public class FeeBumpTransactionResponse: NSObject, Decodable {

    /// Hex-encoded SHA-256 hash of the fee bump transaction (the outer transaction hash).
    public var transactionHash:String // hash

    /// Array of base64-encoded signatures for the fee bump transaction from the fee source account.
    public var signatures:[String]
    
    private enum CodingKeys: String, CodingKey {
        case transactionHash = "hash"
        case signatures
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        signatures = try values.decode([String].self, forKey: .signatures)
    }
}
