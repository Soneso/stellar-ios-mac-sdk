//
//  StaleHistoryErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a stale history error response (code 503) from the horizon api, containing information related to the error
///  See [Horizon API](https://developers.stellar.org/docs/data/horizon/api-reference/errors/http-status-codes/horizon-specific/stale-history "Stale History")
public class StaleHistoryErrorResponse: ErrorResponse {}
