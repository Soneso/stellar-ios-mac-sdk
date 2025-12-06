//
//  ForbiddenErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 403 Forbidden error from Horizon indicating access to the resource is denied.
///
/// This error occurs when:
/// - Authentication required but not provided
/// - Invalid or expired authentication credentials
/// - Insufficient permissions for the requested operation
/// - IP-based access restrictions
///
/// Contact the Horizon server administrator if you believe access should be granted.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class ForbiddenErrorResponse: ErrorResponse, @unchecked Sendable {}
