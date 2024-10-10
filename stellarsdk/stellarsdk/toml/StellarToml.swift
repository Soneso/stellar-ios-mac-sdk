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

public enum TomlCurrencyLoadError: Error {
    case invalidUrl
    case invalidToml
}

/// An enum used to diferentiate between successful and failed toml for domain responses.
public enum TomlForDomainEnum {
    case success(response: StellarToml)
    case failure(error: TomlFileError)
}

/// An enum used to diferentiate between successful and failed toml for domain responses.
public enum TomlCurrencyFromUrlEnum {
    case success(response: CurrencyDocumentation)
    case failure(error: TomlCurrencyLoadError)
}

/// A closure to be called with the response from a toml for domain request.
public typealias TomlFileClosure = (_ response:TomlForDomainEnum) -> (Void)

/// A closure to be called with the response from a linked currency in a toml request.
/// Alternately to specifying a currency in its content, stellar.toml can link out to a separate TOML file for the currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
public typealias TomlCurrencyFromUrlClosure = (_ response:TomlCurrencyFromUrlEnum) -> (Void)

/// see: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md
/// Supported version: 2.5.0
public class StellarToml {

    public var accountInformation: AccountInformation
    public var issuerDocumentation: IssuerDocumentation
    public var pointsOfContact: [PointOfContactDocumentation] = []
    public var currenciesDocumentation: [CurrencyDocumentation] = []
    public var validatorsInformation: [ValidatorInformation] = []
    
    /**
        Parse the string `fromString`

        - Parameter fromString: A string with TOML document

        - Throws: `TomlFileError.invalidToml` if the string is invalid
    */
    public init(fromString string:String) throws {
        var parsedToml:Toml? = nil
        do {
            parsedToml = try Toml(withString: string)
        } catch {
            throw TomlFileError.invalidToml
        }
        let toml = parsedToml!
        accountInformation = AccountInformation(fromToml: toml)
        
        if let documentation = toml.table("DOCUMENTATION"){
            issuerDocumentation = IssuerDocumentation(fromToml: documentation)
        } else {
            throw TomlFileError.invalidToml
        }

        if let principals = toml.table("PRINCIPALS") {
            pointsOfContact = []
            for pocToml in principals.tables() {
                let poc = PointOfContactDocumentation(fromToml: pocToml)
                pointsOfContact.append(poc)
            }
        }
        if let currencies = toml.table("CURRENCIES") {
            currenciesDocumentation = []
            for currencies in currencies.tables() {
                let currency = CurrencyDocumentation(fromToml: currencies)
                currenciesDocumentation.append(currency)
            }
        }
        
        if let validators = toml.table("VALIDATORS") {
            validatorsInformation = []
            for validatorToml in validators.tables() {
                let validator = ValidatorInformation(fromToml: validatorToml)
                validatorsInformation.append(validator)
            }
        }
        
    }
    
    @available(*, renamed: "from(domain:secure:)")
    public static func from(domain: String, secure: Bool = true, completion:@escaping TomlFileClosure) {
        Task {
            let result = await from(domain: domain, secure: secure)
            completion(result)
        }
    }
    
    
    public static func from(domain: String, secure: Bool = true) async -> TomlForDomainEnum {
        guard let url = URL(string: "\(secure ? "https://" : "http://")\(domain)/.well-known/stellar.toml") else {
            return .failure(error: .invalidDomain)
        }
        
        do {
            let tomlString = try String(contentsOf: url, encoding: .utf8)
            let stellarToml = try StellarToml(fromString: tomlString)
            return .success(response: stellarToml)
        } catch {
            return .failure(error: .invalidToml)
        }
    }
    
    /// Alternately to specifying a currency in its content, stellar.toml can link out to a separate TOML file for the currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
    @available(*, renamed: "currencyFrom(url:)")
    public static func currencyFrom(url: String, completion:@escaping TomlCurrencyFromUrlClosure) {
        Task {
            let result = await currencyFrom(url: url)
            completion(result)
        }
    }
    
    /// Alternately to specifying a currency in its content, stellar.toml can link out to a separate TOML file for the currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
    public static func currencyFrom(url: String) async -> TomlCurrencyFromUrlEnum {
        guard let url1 = URL(string:url) else {
            return .failure(error: .invalidUrl)
        }
        
        do {
            let tomlString = try String(contentsOf: url1, encoding: .utf8)
            let toml = try Toml(withString: tomlString)
            let currency = CurrencyDocumentation(fromToml: toml)
            return .success(response: currency)
        } catch {
            return .failure(error: .invalidToml)
        }
    }
}
