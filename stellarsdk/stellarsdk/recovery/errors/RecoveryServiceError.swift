//
//  RecoveryServiceErrors.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when interacting with a SEP-30 account recovery service.
public enum RecoveryServiceError: Error {
    /// The request is invalid. Returned when request parameters are malformed or missing required fields.
    case badRequest(message:String)

    /// Authentication failed. Returned when the JWT token is missing, invalid, or does not grant access to the requested resource.
    case unauthorized(message:String)

    /// The requested resource was not found. Returned when the account does not exist or the authenticated user lacks permission to access it.
    case notFound(message:String)

    /// Resource conflict. Returned when attempting to register an account that is already registered.
    case conflict(message:String)

    /// Failed to parse the server response. Returned when the response data cannot be decoded into the expected structure.
    case parsingResponseFailed(message:String)

    /// An error occurred at the Horizon level. Wraps underlying Horizon API errors.
    case horizonError(error: HorizonRequestError)
}
