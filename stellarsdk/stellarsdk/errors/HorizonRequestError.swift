//
//  HorizonRequestError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 01/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum HorizonRequestError: Error {
    case requestFailed(message: String)
    case badRequest(message:String, horizonErrorResponse:BadRequestErrorResponse?) // HTTP Status Code 400
    case forbidden(message:String, horizonErrorResponse:ForbiddenErrorResponse?) // HTTP Status Code 403
    case notFound(message: String, horizonErrorResponse:NotFoundErrorResponse?) //HTTP Status Code 404
    case notAcceptable(message: String, horizonErrorResponse:NotAcceptableErrorResponse?) /// HTTP Status code 406
    case beforeHistory(message: String, horizonErrorResponse:BeforeHistoryErrorResponse?) // HTTP Status code 410
    case rateLimitExceeded(message: String, horizonErrorResponse:RateLimitExceededErrorResponse?) // HTTP Status code 429
    case internalServerError(message:String, horizonErrorResponse:InternalServerErrorResponse?) // HTTP Status cose 500
    case notImplemented(message:String, horizonErrorResponse:NotImplementedErrorResponse?) // HTTP Status code 501
    case staleHistory(message:String, horizonErrorResponse:StaleHistoryErrorResponse?) // HTTP Status code 503
    case emptyResponse
    case parsingResponseFailed(message:String)
    case errorOnStreamReceive(message:String)
}
