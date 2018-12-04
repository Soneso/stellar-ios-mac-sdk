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

public class Federation: NSObject {
    
    public var federationAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(federationAddress:String) {
        self.federationAddress = federationAddress
        self.serviceHelper = ServiceHelper(baseURL: federationAddress)
    }
    
    /// Resolves a given stellar address
    public static func resolve(stellarAddress:String, secure:Bool = true, completion:@escaping ResolveClosure) {
        let components = stellarAddress.components(separatedBy: "*")
        guard components.count == 2 else {
            completion(.failure(error: .invalidAddress))
            return
        }
        let domain = components[1]
        Federation.forDomain(domain:domain, secure:secure) { (response) -> (Void) in
            switch response {
            case .success(let federation):
                federation.resolve(address: stellarAddress, completion: completion)
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Creates a Federation instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
    public static func forDomain(domain:String, secure:Bool = true, completion:@escaping FederationClosure) {
    
        DispatchQueue.global().async {
            do {
                try StellarToml.from(domain: domain, secure: secure) { (result) -> (Void) in
                    switch result {
                    case .success(response: let stellarToml):
                        if let federationServer = stellarToml.accountInformation.federationServer {
                            let federation = Federation(federationAddress: federationServer)
                            completion(.success(response: federation))
                        } else {
                            completion(.failure(error: .noFederationSet))
                        }
                    case .failure(error: let stellarTomlError):
                        switch stellarTomlError {
                        case .invalidDomain:
                            completion(.failure(error: .invalidTomlDomain))
                        case .invalidToml:
                            completion(.failure(error: .invalidToml))
                        }
                    }
                }
            } catch {
                completion(.failure(error: .invalidToml))
            }
        }
    }
    
    /// Resolves the given address to federation record if the user was found for a given Stellar address.
    public func resolve(address: String, completion:@escaping ResolveClosure) {
        guard let _ = address.index(of: "*") else {
            completion(.failure(error: .invalidAddress))
            return
        }
        
        let requestPath = "?q=\(address)&type=name"
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error:.horizonError(error: error)))
            }
        }
    }
    
    /// Resolves the given account id to federation address if the user was found for a given Stellar address.
    public func resolve(account_id: String, completion:@escaping ResolveClosure) {
        do {
            let _ = try PublicKey(accountId: account_id)
        } catch {
            completion(.failure(error: .invalidAccountId))
            return
        }
        
        let requestPath = "?q=\(account_id)&type=id"
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error:.horizonError(error: error)))
            }
        }
    }
    
    /// Resolves the given transaction id to federation address if the user was found for a given Stellar address.
    public func resolve(transaction_id: String, completion:@escaping ResolveClosure) {
        let requestPath = "?q=\(transaction_id)&type=txid"
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(ResolveAddressResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error:.horizonError(error: error)))
            }
        }
    }
    
}
