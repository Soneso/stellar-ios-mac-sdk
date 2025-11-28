//
//  InternalServerErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 500 Internal Server Error from Horizon indicating an unexpected server-side problem.
///
/// This error occurs when:
/// - Horizon encounters an unexpected internal error
/// - Database connection failures
/// - Stellar Core connection issues
/// - Unhandled exceptions on the server
///
/// These errors are typically transient. Retry the request after a delay.
/// If errors persist, check Horizon server status or contact administrators.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class InternalServerErrorResponse: ErrorResponse, @unchecked Sendable {}
