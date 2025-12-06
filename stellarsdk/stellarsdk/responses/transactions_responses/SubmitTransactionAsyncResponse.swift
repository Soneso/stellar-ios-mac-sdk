//
//  SubmitTransactionAsyncResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

import Foundation

/// Response returned from asynchronously submitting a transaction to Horizon.
///
/// When using async transaction submission, Horizon immediately returns this response indicating
/// the submission status without waiting for the transaction to be included in a ledger.
/// The transaction may still be pending or require later polling to confirm final status.
///
/// Status values:
/// - ERROR: Transaction validation failed
/// - PENDING: Transaction accepted and pending inclusion in a ledger
/// - DUPLICATE: Transaction was already submitted
/// - TRY_AGAIN_LATER: System temporarily unable to accept transaction
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - SubmitTransactionResponse for synchronous submission
public struct SubmitTransactionAsyncResponse: Decodable, Sendable {

    /// Status of the async transaction submission: "ERROR", "PENDING", "DUPLICATE", or "TRY_AGAIN_LATER".
    public var txStatus:String

    /// Hex-encoded SHA-256 hash of the transaction. Use this to query transaction status later.
    public var txHash:String
    
    private enum CodingKeys: String, CodingKey {
        case txStatus = "tx_status"
        case txHash = "hash"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        txStatus = try values.decode(String.self, forKey: .txStatus)
        txHash = try values.decode(String.self, forKey: .txHash)
    }
}
