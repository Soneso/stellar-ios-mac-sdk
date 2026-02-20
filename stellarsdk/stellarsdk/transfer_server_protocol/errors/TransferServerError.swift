//
//  TransferServerError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the type of customer information needed for a transfer operation.
///
/// This enum differentiates between non-interactive customer information requests
/// and customer information status responses in SEP-6 transfer operations.
///
/// See also:
/// - [SEP-0006 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
public enum InformationNeededEnum: Sendable {
    /// Non-interactive customer information is needed to complete the transfer.
    ///
    /// The anchor requires additional customer information fields to be submitted
    /// to the /customer endpoint before the deposit or withdrawal can proceed.
    case nonInteractive(info:CustomerInformationNeededNonInteractive)

    /// Customer information processing status response.
    ///
    /// Indicates the current status of customer information processing, such as
    /// pending or denied, along with optional details about the review process.
    case status(info:CustomerInformationStatus)
}

/// Errors that can occur during SEP-6 transfer server operations.
///
/// This enum represents all possible error conditions when interacting with
/// a transfer server for deposit and withdrawal operations according to SEP-6.
///
/// See also:
/// - [SEP-0006 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
/// - [TransferServerService] for SEP-6 implementation
public enum TransferServerError: Error, Sendable {
    /// The provided domain is invalid or malformed.
    ///
    /// Occurs when attempting to resolve a transfer server from an invalid domain name.
    case invalidDomain

    /// The stellar.toml file for the domain is invalid or cannot be parsed.
    ///
    /// Occurs when the TRANSFER_SERVER or TRANSFER_SERVER_SEP0024 field is missing
    /// or the TOML file structure is malformed.
    case invalidToml

    /// No transfer server endpoint is configured in the stellar.toml file.
    ///
    /// Occurs when neither TRANSFER_SERVER nor TRANSFER_SERVER_SEP0024 is defined
    /// in the domain's stellar.toml file.
    case noTransferServerSet

    /// The response from the transfer server could not be parsed.
    ///
    /// Occurs when the server returns a response that does not match the expected
    /// JSON structure or contains invalid data types.
    case parsingResponseFailed(message:String)

    /// The anchor returned an error response.
    ///
    /// Occurs when the transfer server returns an error status with a message
    /// explaining why the operation failed.
    case anchorError(message:String)

    /// Additional customer information is needed to complete the transfer.
    ///
    /// Occurs when the anchor requires more customer data before processing
    /// the deposit or withdrawal. The response indicates what information is needed
    /// or the status of information previously submitted.
    case informationNeeded(response:InformationNeededEnum)

    /// Authentication is required to perform the requested operation.
    ///
    /// Occurs when a transfer operation requires SEP-10 authentication but no
    /// valid JWT token was provided or the token has expired.
    case authenticationRequired

    /// An error occurred during a Horizon request.
    ///
    /// Occurs when an underlying Stellar Horizon API call fails, such as when
    /// submitting a transaction or querying account information.
    case horizonError(error: HorizonRequestError)
}
