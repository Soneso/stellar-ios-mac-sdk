//
//  HorizonRequestError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 01/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when making requests to the Horizon API server.
public enum HorizonRequestError: Error {
    /// The request failed due to a network or connection error.
    case requestFailed(message: String, horizonErrorResponse:ErrorResponse?)
    /// The request was invalid or malformed. HTTP status code 400.
    case badRequest(message:String, horizonErrorResponse:BadRequestErrorResponse?)
    /// Authentication credentials were missing or invalid. HTTP status code 401.
    case unauthorized(message:String)
    /// The server understood the request but refuses to authorize it. HTTP status code 403.
    case forbidden(message:String, horizonErrorResponse:ForbiddenErrorResponse?)
    /// The requested resource could not be found on the server. HTTP status code 404.
    case notFound(message: String, horizonErrorResponse:NotFoundErrorResponse?)
    /// The requested content type is not supported by the server. HTTP status code 406.
    case notAcceptable(message: String, horizonErrorResponse:NotAcceptableErrorResponse?)
    /// The request conflicts with an existing resource or transaction. HTTP status code 409.
    case duplicate(message: String, horizonErrorResponse:DuplicateErrorResponse?)
    /// The requested data is before the recorded history retention period. HTTP status code 410.
    case beforeHistory(message: String, horizonErrorResponse:BeforeHistoryErrorResponse?)
    /// The request payload exceeds the server's size limit. HTTP status code 413.
    case payloadTooLarge(message: String, horizonErrorResponse:PayloadTooLargeErrorResponse?)
    /// Too many requests were sent in a given timeframe. HTTP status code 429.
    case rateLimitExceeded(message: String, horizonErrorResponse:RateLimitExceededErrorResponse?)
    /// The server encountered an unexpected condition. HTTP status code 500.
    case internalServerError(message:String, horizonErrorResponse:InternalServerErrorResponse?)
    /// The server does not support the functionality required to fulfill the request. HTTP status code 501.
    case notImplemented(message:String, horizonErrorResponse:NotImplementedErrorResponse?)
    /// The server's history is out of sync with the network. HTTP status code 503.
    case staleHistory(message:String, horizonErrorResponse:StaleHistoryErrorResponse?)
    /// The server did not respond within the expected timeframe. HTTP status code 504.
    case timeout(message:String, horizonErrorResponse:TimeoutErrorResponse?)
    /// Horizon returned empty response body.
    case emptyResponse
    /// Failed to parse the JSON response from the server.
    case parsingResponseFailed(message:String)
    /// An error occurred while receiving data from a streaming endpoint.
    case errorOnStreamReceive(message:String)
}
