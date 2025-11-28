//
//  Federation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 22/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for federation address resolution requests.
public enum ResolveResponseEnum {
    /// Successfully resolved Stellar address to account ID and memo
    case success(response: ResolveAddressResponse)
    /// Failed to resolve address, contains error information
    case failure(error: FederationError)
}

/// Result enum for federation server discovery requests.
public enum FederationForDomainEnum {
    /// Successfully discovered federation server from stellar.toml
    case success(response: Federation)
    /// Failed to discover federation server, contains error information
    case failure(error: FederationError)
}

/// Implements SEP-0002 - Federation Protocol.
///
/// This class provides human-readable address resolution for Stellar accounts. Instead of using
/// long cryptographic addresses (G...), users can use addresses like "alice*example.com".
/// Federation makes Stellar more user-friendly by mapping memorable names to account IDs.
///
/// ## Typical Usage
///
/// ```swift
/// // Resolve a Stellar address to account ID
/// let result = await Federation.resolve(
///     stellarAddress: "alice*testanchor.stellar.org"
/// )
///
/// switch result {
/// case .success(let response):
///     print("Account ID: \(response.accountId)")
///     if let memo = response.memo {
///         print("Memo: \(memo)")
///     }
/// case .failure(let error):
///     print("Resolution failed: \(error)")
/// }
/// ```
///
/// ## Reverse Lookup
///
/// ```swift
/// // Look up address from account ID
/// let federation = Federation(federationAddress: "https://testanchor.stellar.org/federation")
/// let result = await federation.resolve(account_id: "GACCOUNT...")
///
/// if case .success(let response) = result {
///     print("Stellar address: \(response.stellarAddress ?? "unknown")")
/// }
/// ```
///
/// See also:
/// - [SEP-0002 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md)
/// - [StellarToml] for discovering federation servers
public class Federation: NSObject {

    /// The URL of the SEP-2 federation server endpoint for resolving addresses.
    public var federationAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()

    /// Initializes a new Federation instance with the specified federation server endpoint URL.
    ///
    /// - Parameter federationAddress: The URL of the federation server (e.g., "https://example.com/federation")
    public init(federationAddress:String) {
        self.federationAddress = federationAddress
        self.serviceHelper = ServiceHelper(baseURL: federationAddress)
    }
    
    /// Resolves a Stellar address (e.g., "alice*example.com") to an account ID.
    ///
    /// This is a convenience method that automatically discovers the federation server
    /// from the domain's stellar.toml file and performs the resolution.
    ///
    /// - Parameter stellarAddress: The Stellar address in the format "name*domain"
    /// - Parameter secure: If true, uses HTTPS to fetch stellar.toml (default: true)
    /// - Returns: ResolveResponseEnum with the account ID and optional memo, or an error
    public static func resolve(stellarAddress:String, secure:Bool = true) async -> ResolveResponseEnum {
        let components1 = stellarAddress.components(separatedBy: "*")
        guard components1.count == 2 else {
            return .failure(error: .invalidAddress)
        }
        let domain = components1[1]
        let response = await Federation.forDomain(domain: domain, secure: secure)
        switch response {
        case .success(let federation):
            return await federation.resolve(address: stellarAddress)
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Creates a Federation instance based on information from the stellar.toml file for a given domain.
    ///
    /// Fetches the stellar.toml file from `https://{domain}/.well-known/stellar.toml` (or `http://` if secure is false)
    /// and extracts the FEDERATION_SERVER URL.
    ///
    /// - Parameter domain: The domain without scheme (e.g., "example.com")
    /// - Parameter secure: If true, uses HTTPS to fetch stellar.toml (default: true)
    /// - Returns: FederationForDomainEnum with the Federation instance, or an error
    public static func forDomain(domain:String, secure:Bool = true) async -> FederationForDomainEnum {
        
        let result = await StellarToml.from(domain: domain, secure: secure)
        switch result {
        case .success(response: let stellarToml):
            if let federationServer = stellarToml.accountInformation.federationServer {
                let federation = Federation(federationAddress: federationServer)
                return .success(response: federation)
            } else {
                return .failure(error: .noFederationSet)
            }
        case .failure(error: let stellarTomlError):
            switch stellarTomlError {
            case .invalidDomain:
                return .failure(error: .invalidTomlDomain)
            case .invalidToml:
                return .failure(error: .invalidToml)
            }
        }
    }
    
    /// Resolves a Stellar address to its federation record (type=name query).
    ///
    /// Performs a forward lookup from a Stellar address like "alice*example.com" to the
    /// corresponding account ID and optional memo.
    ///
    /// - Parameter address: The Stellar address in the format "name*domain"
    /// - Returns: ResolveResponseEnum with account ID, memo, and other federation data, or an error
    public func resolve(address: String) async -> ResolveResponseEnum {
        guard let _ = address.firstIndex(of: "*") else {
            return .failure(error: .invalidAddress)
        }
        
        let requestPath = "?q=\(address)&type=name"
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:.horizonError(error: error))
        }
    }
    
    /// Resolves an account ID to its federation address (type=id query, reverse lookup).
    ///
    /// Performs a reverse lookup from a Stellar account ID (G...) to find the corresponding
    /// Stellar address like "alice*example.com".
    ///
    /// - Parameter account_id: The Stellar account ID (starting with G)
    /// - Returns: ResolveResponseEnum with the Stellar address, or an error
    public func resolve(account_id: String) async -> ResolveResponseEnum {
        do {
            let _ = try PublicKey(accountId: account_id)
        } catch {
            return .failure(error: .invalidAccountId)
        }
        
        let requestPath = "?q=\(account_id)&type=id"
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:.horizonError(error: error))
        }
    }
    
    /// Resolves a transaction ID to federation information (type=txid query).
    ///
    /// Used to look up the destination for a transaction that was submitted to a forwarding server.
    ///
    /// - Parameter transaction_id: The transaction hash/ID
    /// - Returns: ResolveResponseEnum with federation data, or an error
    public func resolve(transaction_id: String) async -> ResolveResponseEnum {
        let requestPath = "?q=\(transaction_id)&type=txid"
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:.horizonError(error: error))
        }
    }
    
    /// Resolves forwarding parameters for cross-network or cross-institution payments (type=forward query).
    ///
    /// Used for forwarding the payment on to a different network or different financial institution.
    /// The forwardParams of the query will vary depending on what kind of institution is the ultimate
    /// destination of the payment and what they as the forwarding anchor support.
    ///
    /// - Parameter forwardParams: Dictionary of forwarding parameters specific to the destination institution
    /// - Returns: ResolveResponseEnum with the forwarding destination, or an error
    public func resolve(forwardParams: Dictionary<String,String>) async -> ResolveResponseEnum {
        var requestPath = "?type=forward"
        
        if let pathParams = forwardParams.stringFromHttpParameters() {
            requestPath += "&\(pathParams)"
        }
        
        //print(requestPath)
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:.horizonError(error: error))
        }
    }
}
