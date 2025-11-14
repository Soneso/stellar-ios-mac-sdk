//
//  StaleHistoryErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 503 Stale History error from Horizon indicating the server is behind the network.
///
/// This error occurs when:
/// - Horizon's database is not synced with the latest ledgers
/// - Ingestion from Stellar Core has fallen behind
/// - Server is catching up after maintenance or downtime
///
/// The Horizon server is temporarily unable to serve current data. Retry after a delay
/// or use a different Horizon server that is in sync.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class StaleHistoryErrorResponse: ErrorResponse {}
