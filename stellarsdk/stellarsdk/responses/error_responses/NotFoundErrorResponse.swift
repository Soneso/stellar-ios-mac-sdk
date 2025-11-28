//
//  NotFoundErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 404 Not Found error from Horizon indicating the requested resource does not exist.
///
/// This error occurs when:
/// - Account ID not found on the network
/// - Transaction hash does not exist
/// - Ledger sequence not available
/// - Data entry key not found for account
/// - Invalid or non-existent resource identifier
///
/// Verify the resource identifier is correct and that the resource exists on the network.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class NotFoundErrorResponse: ErrorResponse, @unchecked Sendable {}
