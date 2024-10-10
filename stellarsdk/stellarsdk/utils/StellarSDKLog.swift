//
//  StellarSDKLog.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 23.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public final class StellarSDKLog {

    
    public static func printHorizonRequestErrorMessage(tag: String, horizonRequestError: HorizonRequestError) {
        switch horizonRequestError {
        case .requestFailed(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .badRequest(let message, let errorResponse):
            print("\(tag): Horizon request error of type bad request with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .unauthorized(let message):
            print("\(tag): Horizon request error of type unauthorized with message: \(message)")
        case .forbidden(let message, let errorResponse):
            print("\(tag): Horizon request error of type forbidden with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notFound(let message, let errorResponse):
            print("\(tag): Horizon request error of type not found with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .duplicate(let message, let errorResponse):
            print("\(tag): Horizon request error of type duplicate with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notAcceptable(let message, let errorResponse):
            print("\(tag): Horizon request error of type not acceptable with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .beforeHistory(let message, let errorResponse):
            print("\(tag): Horizon request error of type before history with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .rateLimitExceeded(let message, let errorResponse):
            print("\(tag): Horizon request error of type rate limit exceeded with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .internalServerError(let message, let errorResponse):
            print("\(tag): Horizon request error of type internal server error with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notImplemented(let message, let errorResponse):
            print("\(tag): Horizon request error of type not implemented with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .staleHistory(let message, let errorResponse):
            print("\(tag): Horizon request error of type stale history with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .timeout(let message, let errorResponse):
            print("\(tag): Horizon request error of type timeout with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .emptyResponse:
            print("\(tag): Horizon request error of type empty response.")
        case .parsingResponseFailed(let message):
            print("\(tag): Horizon request error of type parsing response failed with message: \(message)")
        case .errorOnStreamReceive(let message):
            print("\(tag): Horizon request error of type error on stream receive with message: \(message)")
        }
    }
    
    public static func printErrorResponse(tag: String, errorResponse: ErrorResponse?) {
        if let response = errorResponse {
            print("\(tag): Horizon Error response type: \(response.type)")
            print("\(tag): Horizon Error response tite: \(response.title)")
            print("\(tag): Horizon Error response httpStatusCode: \(response.httpStatusCode)")
            print("\(tag): Horizon Error response detail: \(response.detail)")
            if let horizonInstance = response.instance {
                print("\(tag): Horizon Error response instance: \(horizonInstance)")
            }
            
            if let extras = response.extras {
                if let envelopeXdr = extras.envelopeXdr {
                    print("\(tag): Horizon Error response extras.envelopeXdr : \(envelopeXdr)")
                }
                if let resultXdr = extras.resultXdr {
                    print("\(tag): Horizon Error response extras.resultXdr : \(resultXdr)")
                }
                if let txHash = extras.txHash {
                    print("\(tag): Horizon Error response extras.txHash : \(txHash)")
                }
                if let resultCodes = extras.resultCodes {
                    if let tx = resultCodes.transaction {
                        print("\(tag): Horizon Error response extras.resultCodes.transaction : \(tx)")
                    }
                    if let operations = resultCodes.operations {
                        for code in operations {
                            print("\(tag): Horizon Error response extras.resultCodes.operation:\(code)")
                        }
                    }
                }
            }
        }
    }
}

