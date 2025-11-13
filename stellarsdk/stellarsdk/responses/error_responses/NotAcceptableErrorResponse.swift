//
//  NotAcceptableErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 406 Not Acceptable error from Horizon indicating unsupported response format requested.
///
/// This error occurs when:
/// - Requested content type via Accept header is not supported by Horizon
/// - Invalid or missing Accept header
/// - Horizon cannot generate response in the requested format
///
/// Horizon supports JSON responses. Ensure Accept header is set to application/json or omitted.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class NotAcceptableErrorResponse: ErrorResponse {}
