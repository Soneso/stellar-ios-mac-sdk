//
//  BeforeHistoryErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP 410 Before History error from Horizon indicating requested data predates available history.
///
/// This error occurs when:
/// - Requested ledger sequence is before Horizon's earliest retained ledger
/// - Historical data has been pruned from the database
/// - Cursor points to data that is no longer available
///
/// Horizon servers retain limited historical data. Query more recent ledgers or
/// use a Horizon server with longer history retention.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class BeforeHistoryErrorResponse: ErrorResponse, @unchecked Sendable {}
