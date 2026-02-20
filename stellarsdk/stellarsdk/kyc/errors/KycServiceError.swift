//
//  KycServiceError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when interacting with SEP-0012 KYC service endpoints.
/// These errors represent various failure conditions during KYC operations including
/// service initialization, authentication, request validation, and data processing.
public enum KycServiceError: Error, Sendable {
    /// The provided domain is not a valid URL format. Occurs when constructing KycService from an invalid domain string.
    case invalidDomain
    /// The stellar.toml file at the domain could not be parsed or is malformed. Occurs when the TOML structure is invalid.
    case invalidToml
    /// The stellar.toml file does not contain a KYC_SERVER or TRANSFER_SERVER entry. Occurs when the anchor has not configured KYC endpoints.
    case noKycOrTransferServerSet
    /// Failed to parse the JSON response from the KYC server. Occurs when the server returns an unexpected response format.
    case parsingResponseFailed(message:String)
    /// HTTP 400 Bad Request. Occurs when the request contains invalid field values, missing required fields, or unrecognized parameters.
    case badRequest(error:String)
    /// HTTP 404 Not Found. Occurs when the customer ID does not exist or was created by a different account.
    case notFound(error:String)
    /// HTTP 401 Unauthorized. Occurs when the JWT authentication token is invalid, expired, or missing.
    case unauthorized(message:String)
    /// HTTP 413 Payload Too Large. Occurs when an uploaded file exceeds the server's size limit (typically 10MB).
    case payloadTooLarge(error:String?)
    /// Network or server error from the underlying HTTP request. Occurs when there are connection issues or unexpected server responses.
    case horizonError(error: HorizonRequestError)
}
