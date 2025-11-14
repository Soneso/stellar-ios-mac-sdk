//
//  Federation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 22/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed resolve address responses.
public enum ResolveResponseEnum {
    case success(response: ResolveAddressResponse)
    case failure(error: FederationError)
}

/// An enum used to diferentiate between successful and failed federation for domain responses.
public enum FederationForDomainEnum {
    case success(response: Federation)
    case failure(error: FederationError)
}

/// A closure to be called with the response from a resolve address request.
public typealias ResolveClosure = (_ response:ResolveResponseEnum) -> (Void)

/// A closure to be called with the response from a federation for domain request.
public typealias FederationClosure = (_ response:FederationForDomainEnum) -> (Void)

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
    
    public var federationAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(federationAddress:String) {
        self.federationAddress = federationAddress
        self.serviceHelper = ServiceHelper(baseURL: federationAddress)
    }
    
    /// Resolves a given stellar address
    @available(*, renamed: "resolve(stellarAddress:secure:)")
    public static func resolve(stellarAddress:String, secure:Bool = true, completion:@escaping ResolveClosure) {
        Task {
            let result = await resolve(stellarAddress: stellarAddress, secure: secure)
            completion(result)
        }
    }
    
    /// Resolves a given stellar address
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
    @available(*, renamed: "forDomain(domain:secure:)")
    public static func forDomain(domain:String, secure:Bool = true, completion:@escaping FederationClosure) {
        Task {
            let result = await forDomain(domain: domain, secure: secure)
            completion(result)
        }
    }
    
    /// Creates a Federation instance based on information from the stellar.toml file for a given domain.
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
    
    /// Resolves the given address to federation record if the user was found for a given Stellar address.
    @available(*, renamed: "resolve(address:)")
    public func resolve(address: String, completion:@escaping ResolveClosure) {
        Task {
            let result = await resolve(address: address)
            completion(result)
        }
    }
    
    /// Resolves the given address to federation record if the user was found for a given Stellar address.
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
    
    /// Resolves the given account id to federation address if the user was found for a given Stellar address.
    @available(*, renamed: "resolve(account_id:)")
    public func resolve(account_id: String, completion:@escaping ResolveClosure) {
        Task {
            let result = await resolve(account_id: account_id)
            completion(result)
        }
    }
    
    /// Resolves the given account id to federation address if the user was found for a given Stellar address.
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
    
    /// Resolves the given transaction id to federation address if the user was found for a given Stellar address.
    @available(*, renamed: "resolve(transaction_id:)")
    public func resolve(transaction_id: String, completion:@escaping ResolveClosure) {
        Task {
            let result = await resolve(transaction_id: transaction_id)
            completion(result)
        }
    }
    
    /// Resolves the given transaction id to federation address if the user was found for a given Stellar address.
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
    
    /// Used for forwarding the payment on to a different network or different financial institution.
    /// The forwardParams of the query will vary depending on what kind of institution is the ultimate destination of the payment and what they as the forwarding anchor support.
    @available(*, renamed: "resolve(forwardParams:)")
    public func resolve(forwardParams: Dictionary<String,String>, completion:@escaping ResolveClosure) {
        Task {
            let result = await resolve(forwardParams: forwardParams)
            completion(result)
        }
    }
    
    /// Used for forwarding the payment on to a different network or different financial institution.
    /// The forwardParams of the query will vary depending on what kind of institution is the ultimate destination of the payment and what they as the forwarding anchor support.
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
