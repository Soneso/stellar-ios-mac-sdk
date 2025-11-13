//
//  DuplicateErrorResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// HTTP 409 Duplicate error from Horizon indicating the transaction was already submitted.
///
/// This error occurs when:
/// - Transaction with the same hash was already submitted and processed
/// - Duplicate transaction submission attempt detected
/// - Transaction is already in the pending queue
///
/// This typically happens with async transaction submission when the same transaction
/// is submitted multiple times. Check the transaction status rather than resubmitting.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class DuplicateErrorResponse: ErrorResponse {}
