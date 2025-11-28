//
//  BadRequestErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 400 Bad Request error from Horizon indicating malformed request parameters.
///
/// This error occurs when:
/// - Invalid or missing required parameters
/// - Malformed transaction XDR
/// - Invalid asset codes, account IDs, or other identifiers
/// - Transaction validation failures before submission
/// - Parameter format or type errors
///
/// Check the detail field for specific information about what was invalid.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class BadRequestErrorResponse: ErrorResponse, @unchecked Sendable {}
