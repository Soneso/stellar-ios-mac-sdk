//
//  NotImplementedErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 501 Not Implemented error from Horizon indicating unsupported functionality.
///
/// This error occurs when:
/// - Requested feature is not yet implemented in this Horizon version
/// - API endpoint exists but functionality is disabled
/// - Requested operation is not supported by the server configuration
///
/// Check Horizon version and configuration, or use an alternative approach.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class NotImplementedErrorResponse: ErrorResponse, @unchecked Sendable {}
