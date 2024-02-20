//
//  QuoteServiceError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public enum QuoteServiceError: Error {
    case invalidArgument(message:String)
    case badRequest(message:String)
    case permissionDenied(message:String)
    case notFound(message:String)
    case parsingResponseFailed(message:String)
    case horizonError(error: HorizonRequestError)
}
