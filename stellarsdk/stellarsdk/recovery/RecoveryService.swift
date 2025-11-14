//
//  RecoveryService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum Sep30AccountResponseEnum {
    case success(response: Sep30AccountResponse)
    case failure(error: RecoveryServiceError)
}

public enum Sep30SignatureResponseEnum {
    case success(response: Sep30SignatureResponse)
    case failure(error: RecoveryServiceError)
}

public enum Sep30AccountsResponseEnum {
    case success(response: Sep30AccountsResponse)
    case failure(error: RecoveryServiceError)
}

/// Callback closure for account operations (register, update, get, delete).
/// Receives a result containing either a Sep30AccountResponse or RecoveryServiceError.
public typealias Sep30AccountResponseClosure = (_ response:Sep30AccountResponseEnum) -> (Void)

/// Callback closure for transaction signing operations.
/// Receives a result containing either a Sep30SignatureResponse or RecoveryServiceError.
public typealias Sep30SignatureResponseClosure = (_ response:Sep30SignatureResponseEnum) -> (Void)

/// Callback closure for listing accounts operations.
/// Receives a result containing either a Sep30AccountsResponse or RecoveryServiceError.
public typealias Sep30AccountsResponseClosure = (_ response:Sep30AccountsResponseEnum) -> (Void)

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

    public var serviceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(serviceAddress:String) {
        self.serviceAddress = serviceAddress
        serviceHelper = ServiceHelper(baseURL: serviceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    
    /// This endpoint registers an account.
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddress
    @available(*, renamed: "registerAccount(address:request:jwt:)")
    public func registerAccount(address: String, request: Sep30Request, jwt:String, completion:@escaping Sep30AccountResponseClosure) {
        Task {
            let result = await registerAccount(address: address, request: request, jwt: jwt)
            completion(result)
        }
    }
    
    /// This endpoint registers an account.
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
    
    /// This endpoint updates the identities for the account.
    /// The identities should be entirely replaced with the identities provided in the request, and not merged. Either owner or other or both should be set. If one is currently set and the request does not include it, it is removed.
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#put-accountsaddress
    @available(*, renamed: "updateIdentitiesForAccount(address:request:jwt:)")
    public func updateIdentitiesForAccount(address: String, request: Sep30Request, jwt:String, completion:@escaping Sep30AccountResponseClosure) {
        Task {
            let result = await updateIdentitiesForAccount(address: address, request: request, jwt: jwt)
            completion(result)
        }
    }
    
    /// This endpoint updates the identities for the account.
    /// The identities should be entirely replaced with the identities provided in the request, and not merged. Either owner or other or both should be set. If one is currently set and the request does not include it, it is removed.
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
    
    /// This endpoint signs a transaction.
    /// See https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddresssignsigning-address
    @available(*, renamed: "signTransaction(address:signingAddress:transaction:jwt:)")
    public func signTransaction(address: String, signingAddress: String, transaction:String, jwt:String, completion:@escaping Sep30SignatureResponseClosure) {
        Task {
            let result = await signTransaction(address: address, signingAddress: signingAddress, transaction: transaction, jwt: jwt)
            completion(result)
        }
    }
    
    /// This endpoint signs a transaction.
    /// See https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddresssignsigning-address
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
    
    /// This endpoint returns the registered account’s details.
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#get-accountsaddress
    @available(*, renamed: "accountDetails(address:jwt:)")
    public func accountDetails(address: String, jwt:String, completion:@escaping Sep30AccountResponseClosure) {
        Task {
            let result = await accountDetails(address: address, jwt: jwt)
            completion(result)
        }
    }
    
    /// This endpoint returns the registered account’s details.
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
    
    /// This endpoint will delete the record for an account. This should be irrecoverable.
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#delete-accountsaddress
    @available(*, renamed: "deleteAccount(address:jwt:)")
    public func deleteAccount(address: String, jwt:String, completion:@escaping Sep30AccountResponseClosure) {
        Task {
            let result = await deleteAccount(address: address, jwt: jwt)
            completion(result)
        }
    }
    
    /// This endpoint will delete the record for an account. This should be irrecoverable.
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
    
    
    /// This endpoint will return a list of accounts that the JWT allows access to.
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#get-accounts
    @available(*, renamed: "accounts(jwt:after:)")
    public func accounts(jwt:String, after:String? = nil, completion:@escaping Sep30AccountsResponseClosure) {
        Task {
            let result = await accounts(jwt: jwt, after: after)
            completion(result)
        }
    }
    
    /// This endpoint will return a list of accounts that the JWT allows access to.
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
        default:
            return .horizonError(error: horizonError)
        
        // todo conflict 409
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
