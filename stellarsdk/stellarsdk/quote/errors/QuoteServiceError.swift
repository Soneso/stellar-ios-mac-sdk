//
//  QuoteServiceError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when interacting with the Quote Service (SEP-38).
///
/// This enum represents all possible error conditions that may arise during
/// quote service operations, including validation errors, HTTP errors, and
/// response parsing failures.
///
/// See [SEP-38: Quote Service](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)
public enum QuoteServiceError: Error {

    /// An invalid argument was provided to the service.
    ///
    /// This error occurs when request parameters fail validation before being sent to the server.
    ///
    /// - Parameter message: Description of which argument is invalid and why
    case invalidArgument(message:String)

    /// The server returned a 400 Bad Request response.
    ///
    /// This error occurs when the request is malformed or contains invalid data according to the server.
    ///
    /// - Parameter message: Error message from the server explaining the bad request
    case badRequest(message:String)

    /// The server returned a 403 Forbidden response.
    ///
    /// This error occurs when the client lacks proper authentication or authorization
    /// to access the requested resource.
    ///
    /// - Parameter message: Error message from the server explaining the permission denial
    case permissionDenied(message:String)

    /// The server returned a 404 Not Found response.
    ///
    /// This error occurs when the requested quote or resource does not exist.
    ///
    /// - Parameter message: Error message from the server indicating what was not found
    case notFound(message:String)

    /// Failed to parse the response from the server.
    ///
    /// This error occurs when the server returns data in an unexpected format or structure
    /// that cannot be decoded into the expected response model.
    ///
    /// - Parameter message: Description of the parsing failure
    case parsingResponseFailed(message:String)

    /// An error occurred during Horizon interaction.
    ///
    /// This error occurs when the underlying Horizon request fails, typically during
    /// operations that require on-chain data or transactions.
    ///
    /// - Parameter error: The underlying Horizon request error
    case horizonError(error: HorizonRequestError)
}
