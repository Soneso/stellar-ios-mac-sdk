//
//  RecoveryService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Result enum for SEP-30 account operations (register, update, get, delete).
public enum Sep30AccountResponseEnum {
    /// Successfully completed account operation, returns account details.
    case success(response: Sep30AccountResponse)
    /// Request failed with recovery service error.
    case failure(error: RecoveryServiceError)
}

/// Result enum for SEP-30 transaction signing requests.
public enum Sep30SignatureResponseEnum {
    /// Successfully signed transaction, returns signature and network passphrase.
    case success(response: Sep30SignatureResponse)
    /// Request failed with recovery service error.
    case failure(error: RecoveryServiceError)
}

/// Result enum for SEP-30 list accounts requests.
public enum Sep30AccountsResponseEnum {
    /// Successfully retrieved list of accessible accounts.
    case success(response: Sep30AccountsResponse)
    /// Request failed with recovery service error.
    case failure(error: RecoveryServiceError)
}

/// Implements SEP-0030 - Account Recovery: Multi-Party Recovery of Stellar Accounts.
///
/// This class provides account recovery functionality allowing users to regain access to their
/// Stellar accounts through registered identities. Multiple recovery methods can be configured
/// as a safety net if primary authentication is lost.
///
/// ## Typical Usage
///
/// ```swift
/// let service = RecoveryService(serviceAddress: "https://recovery.example.com")
///
/// // Register account with recovery identities
/// let request = Sep30Request()
/// request.identities = [
///     Sep30Identity(role: "owner", authMethods: [...])
/// ]
/// let result = await service.registerAccount(
///     address: accountId,
///     request: request,
///     jwt: jwtToken
/// )
///
/// // Sign transaction for recovery
/// let signResult = await service.signTransaction(
///     address: accountId,
///     signingAddress: signerAddress,
///     transaction: transactionXdr,
///     jwt: jwtToken
/// )
/// ```
///
/// See also:
/// - [SEP-0030 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md)
/// - [WebAuthenticator] for SEP-10 authentication
public class RecoveryService: NSObject {

    /// The base URL of the SEP-30 account recovery service endpoint for multi-party account recovery.
    public var serviceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()

    /// Creates a RecoveryService instance with a direct service endpoint URL.
    ///
    /// - Parameter serviceAddress: The URL of the SEP-30 recovery server (e.g., "https://recovery.example.com")
    public init(serviceAddress:String) {
        self.serviceAddress = serviceAddress
        serviceHelper = ServiceHelper(baseURL: serviceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    
    /// Registers an account with the recovery service.
    ///
    /// - Parameter address: The Stellar account address (G...) to register
    /// - Parameter request: Sep30Request containing the identities and authentication methods for recovery
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication
    /// - Returns: Sep30AccountResponseEnum with account details, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddress
    public func registerAccount(address: String, request: Sep30Request, jwt:String) async -> Sep30AccountResponseEnum {
        
        let requestData = try! JSONSerialization.data(withJSONObject: request.toJson())
        let result = await serviceHelper.POSTRequestWithPath(path: "/accounts/\(address)", jwtToken: jwt, body: requestData, contentType: "application/json")
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep30AccountResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Updates the identities for the account.
    ///
    /// The identities should be entirely replaced with the identities provided in the request, and not merged.
    /// Either owner or other or both should be set. If one is currently set and the request does not include it, it is removed.
    ///
    /// - Parameter address: The Stellar account address (G...) to update
    /// - Parameter request: Sep30Request containing the new identities to replace existing ones
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication
    /// - Returns: Sep30AccountResponseEnum with updated account details, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#put-accountsaddress
    public func updateIdentitiesForAccount(address: String, request: Sep30Request, jwt:String) async -> Sep30AccountResponseEnum {
        
        let requestData = try! JSONSerialization.data(withJSONObject: request.toJson())
        let result = await serviceHelper.PUTRequestWithPath(path: "/accounts/\(address)", jwtToken: jwt, body: requestData, contentType: "application/json")
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep30AccountResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Signs a transaction using the recovery service's signer.
    ///
    /// - Parameter address: The Stellar account address (G...) that the transaction is for
    /// - Parameter signingAddress: The address of the signer on the recovery service that should sign
    /// - Parameter transaction: The transaction envelope XDR (base64 encoded) to sign
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication
    /// - Returns: Sep30SignatureResponseEnum with the signature and network passphrase, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddresssignsigning-address
    public func signTransaction(address: String, signingAddress: String, transaction:String, jwt:String) async -> Sep30SignatureResponseEnum {
        
        let requestData = try! JSONSerialization.data(withJSONObject: ["transaction" : transaction])
        let result = await serviceHelper.POSTRequestWithPath(path: "/accounts/\(address)/sign/\(signingAddress)", jwtToken: jwt, body: requestData, contentType: "application/json")
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep30SignatureResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Returns the registered account's details.
    ///
    /// - Parameter address: The Stellar account address (G...) to retrieve
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication
    /// - Returns: Sep30AccountResponseEnum with account details including identities and signers, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#get-accountsaddress
    public func accountDetails(address: String, jwt:String) async -> Sep30AccountResponseEnum {
        
        let result = await serviceHelper.GETRequestWithPath(path: "/accounts/\(address)", jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep30AccountResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Deletes the record for an account. This should be irrecoverable.
    ///
    /// - Parameter address: The Stellar account address (G...) to delete
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication
    /// - Returns: Sep30AccountResponseEnum with the deleted account details, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#delete-accountsaddress
    public func deleteAccount(address: String, jwt:String) async -> Sep30AccountResponseEnum {
        
        let result = await serviceHelper.DELETERequestWithPath(path: "/accounts/\(address)", jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep30AccountResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    
    /// Returns a list of accounts that the JWT allows access to.
    ///
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication
    /// - Parameter after: Optional account address for pagination (returns accounts after this address)
    /// - Returns: Sep30AccountsResponseEnum with list of accessible accounts, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#get-accounts
    public func accounts(jwt:String, after:String? = nil) async -> Sep30AccountsResponseEnum {
        
        var path = "/accounts"
        if let af = after {
            path = "/accounts?after=\(af)"
        }
        let result = await serviceHelper.GETRequestWithPath(path: path, jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep30AccountsResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    private func errorFor(horizonError:HorizonRequestError) -> RecoveryServiceError {
        switch horizonError {
        case .badRequest(let message, _):
            return .badRequest(message: extractErrorMessage(message: message))
        case .unauthorized(let message):
            return .unauthorized(message: extractErrorMessage(message: message))
        case .notFound(let message, _):
            return .notFound(message: extractErrorMessage(message: message))
        case .duplicate(let message, _):
            return .conflict(message: extractErrorMessage(message: message))
        default:
            return .horizonError(error: horizonError)
        }
    }
    
    private func extractErrorMessage(message:String) -> String {
        if let data = message.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let error = json["error"] as? String {
                    return error
                }
            } catch {
                return message
            }
        }
        return message
    }
}
