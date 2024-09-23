//
//  BadRequestErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a transaction malformed (bad request) error response from the horizon api (code 400), containing information related to the error
///  See [Horizon API](https://developers.stellar.org/docs/data/horizon/api-reference/errors/http-status-codes/horizon-specific/transaction-malformed "Transaction malformed")
public class BadRequestErrorResponse: ErrorResponse {}
