//
//  StellarToml.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum TomlFileError: Error {
    case invalidDomain
    case invalidToml
}

/// An enum used to diferentiate between successful and failed toml for domain responses.
public enum TomlForDomainEnum {
    case success(response: StellarToml)
    case failure(error: TomlFileError)
}

/// A closure to be called with the response from a toml for domain request.
public typealias TomlFileClosure = (_ response:TomlForDomainEnum) -> (Void)

public class StellarToml {

    public let accountInformation: AccountInformation
    public let issuerDocumentation: IssuerDocumentation
    public var pointsOfContact: [PointOfContactDocumentation]
    public var currenciesDocumentation: [CurrencyDocumentation]
    public let validatorInformation: ValidatorInformation
    
    public init(fromString string:String) throws {
        let toml = try Toml(withString: string)
        accountInformation = AccountInformation(fromToml: toml)
        
        if let documentation = toml.table("DOCUMENTATION"),
            let principals = toml.table("PRINCIPALS"),
            let currencies = toml.table("CURRENCIES"),
            let validator = toml.table("QUORUM_SET") {
            
            issuerDocumentation = IssuerDocumentation(fromToml: documentation)
            pointsOfContact = []
            for pocToml in principals.tables() {
                let poc = PointOfContactDocumentation(fromToml: pocToml)
                pointsOfContact.append(poc)
            }
            
            currenciesDocumentation = []
            for currencies in currencies.tables() {
                let currency = CurrencyDocumentation(fromToml: currencies)
                currenciesDocumentation.append(currency)
            }
            validatorInformation = ValidatorInformation(fromToml: validator)
            
        } else {
            throw TomlFileError.invalidToml
        }
        
    }
    
    public static func from(domain: String, secure: Bool = true, completion:@escaping TomlFileClosure) throws {
        guard let url = URL(string: "\(secure ? "https://" : "http://")\(domain)/.well-known/stellar.toml") else {
            completion(.failure(error: .invalidDomain))
            return
        }
        
        DispatchQueue.global().async {
            do {
                let tomlString = try String(contentsOf: url, encoding: .utf8)
                let stellarToml = try StellarToml(fromString: tomlString)
                completion(.success(response: stellarToml))
            } catch {
                completion(.failure(error: .invalidToml))
            }
        }
    }
    
}
