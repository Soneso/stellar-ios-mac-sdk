//
//  SubmitTransactionResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 18.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Response returned from successfully submitting a transaction to Horizon.
///
/// This is returned when a transaction is successfully submitted and included in a ledger.
/// It contains all transaction details including the result, operations, fees, and metadata.
///
/// For asynchronous transaction submission, see SubmitTransactionAsyncResponse instead.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TransactionResponse for all available properties
/// - SubmitTransactionAsyncResponse for async submission
public typealias SubmitTransactionResponse = TransactionResponse
