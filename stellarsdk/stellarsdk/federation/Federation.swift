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
    
    /// Creates a Federation instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
    public static func forDomain(domain:String, completion:@escaping FederationClosure) {
        let federationAddressKey = "FEDERATION_SERVER"
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            completion(.failure(error: .invalidDomain))
            return
        }
        
        DispatchQueue.global().async {
            do {
                let tomlString = try String(contentsOf: url, encoding: .utf8)
                let toml = try Toml(withString: tomlString)
                if let federationAddress = toml.string(federationAddressKey) {
                    let federation = Federation(federationAddress: federationAddress)
                    completion(.success(response: federation))
                } else {
                    completion(.failure(error: .noFederationSet))
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
        
        let requestPath = "/federation?q=\(address)&type=name"
        
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
        
        let requestPath = "/federation?q=\(account_id)&type=id"
        
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
        let requestPath = "/federation?q=\(transaction_id)&type=txid"
        
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
