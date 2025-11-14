//
//  PayloadTooLargeErrorResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// HTTP 413 Payload Too Large error from Horizon indicating request body exceeds size limits.
///
/// This error occurs when:
/// - Transaction XDR is too large
/// - Request body exceeds Horizon's configured maximum size
/// - Batch request contains too many items
///
/// Reduce the size of the request by:
/// - Splitting large transactions into multiple smaller ones
/// - Reducing the number of operations per transaction
/// - Using pagination for large queries
///
/// See also:
/// - ErrorResponse for common error properties
public class PayloadTooLargeErrorResponse: ErrorResponse {}
