//
//  RateLimitExceededErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 429 Rate Limit Exceeded error from Horizon indicating too many requests.
///
/// This error occurs when:
/// - Request rate exceeds the configured limit for the Horizon server
/// - Too many requests sent in a short time period
/// - Need to implement backoff and retry logic
///
/// Check response headers for rate limit information:
/// - X-RateLimit-Limit: Maximum requests per time window
/// - X-RateLimit-Remaining: Requests remaining in current window
/// - X-RateLimit-Reset: Time when rate limit resets
///
/// Implement exponential backoff when retrying after rate limit errors.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class RateLimitExceededErrorResponse: ErrorResponse {}

