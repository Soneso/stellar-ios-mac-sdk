//
//  StellarToml.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when loading a stellar.toml file from a domain.
public enum TomlFileError: Error {
    /// The provided domain is invalid or cannot be used to construct a valid URL.
    case invalidDomain
    /// The stellar.toml file could not be parsed or contains invalid TOML syntax.
    case invalidToml
}

/// Errors that can occur when loading a linked currency TOML file from a URL.
///
/// Per SEP-0001, a stellar.toml can link to separate TOML files for individual currencies
/// using toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
public enum TomlCurrencyLoadError: Error {
    /// The provided URL string is invalid or cannot be parsed.
    case invalidUrl
    /// The currency TOML file could not be parsed or contains invalid TOML syntax.
    case invalidToml
}

/// An enum used to diferentiate between successful and failed toml for domain responses.
public enum TomlForDomainEnum {
    /// Successfully loaded and parsed stellar.toml file from the domain.
    case success(response: StellarToml)
    /// Failed to load or parse the stellar.toml file from the domain.
    case failure(error: TomlFileError)
}

/// An enum used to diferentiate between successful and failed toml for domain responses.
public enum TomlCurrencyFromUrlEnum {
    /// Successfully loaded and parsed currency TOML from the linked URL per SEP-0001.
    case success(response: CurrencyDocumentation)
    /// Failed to load or parse the currency TOML from the linked URL.
    case failure(error: TomlCurrencyLoadError)
}

/// A closure to be called with the response from a toml for domain request.
public typealias TomlFileClosure = (_ response:TomlForDomainEnum) -> (Void)

/// A closure to be called with the response from a linked currency in a toml request.
/// Alternately to specifying a currency in its content, stellar.toml can link out to a separate TOML file for the currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
public typealias TomlCurrencyFromUrlClosure = (_ response:TomlCurrencyFromUrlEnum) -> (Void)

/// Implements SEP-0001 - stellar.toml Discovery and Configuration.
///
/// This class parses and provides access to a domain's stellar.toml file, which contains
/// configuration and metadata about a Stellar integration. The stellar.toml file enables
/// automatic discovery of services, validator nodes, asset information, and contact details.
///
/// SEP-0001 is foundational for the Stellar ecosystem, allowing wallets and applications
/// to discover anchor services, validator information, and asset metadata from a domain.
///
/// ## Typical Usage
///
/// ```swift
/// // Fetch stellar.toml from a domain
/// let result = await StellarToml.from(domain: "testanchor.stellar.org")
///
/// switch result {
/// case .success(let toml):
///     // Access account information
///     if let webAuthEndpoint = toml.accountInformation.webAuthEndpoint {
///         print("SEP-10 endpoint: \(webAuthEndpoint)")
///     }
///
///     // Access supported currencies
///     for currency in toml.currenciesDocumentation {
///         print("Asset: \(currency.code ?? ""), Issuer: \(currency.issuer ?? "")")
///     }
///
///     // Access transfer server
///     if let transferServer = toml.accountInformation.transferServer {
///         print("SEP-6 server: \(transferServer)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// ## Available Information
///
/// - **Account Information**: Service endpoints (SEP-6, SEP-10, SEP-12, SEP-24, SEP-31, SEP-38)
/// - **Issuer Documentation**: Organization details, contact information
/// - **Currencies**: Supported assets with metadata and regulatory info
/// - **Validators**: Validator node information for network operators
/// - **Points of Contact**: Key personnel and support contacts
///
/// See also:
/// - [SEP-0001 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
/// - Supported version: 2.7.0
public class StellarToml {

    /// Service endpoints and signing keys from the stellar.toml ACCOUNT section.
    public var accountInformation: AccountInformation
    /// Organization and issuer metadata from the stellar.toml DOCUMENTATION section.
    public var issuerDocumentation: IssuerDocumentation
    /// Key personnel and support contact information from the stellar.toml PRINCIPALS section.
    public var pointsOfContact: [PointOfContactDocumentation] = []
    /// Supported asset definitions and metadata from the stellar.toml CURRENCIES section.
    public var currenciesDocumentation: [CurrencyDocumentation] = []
    /// Validator node configuration and history archives from the stellar.toml VALIDATORS section.
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
    
    /// Loads stellar.toml from a domain using callback-based completion (deprecated).
    @available(*, renamed: "from(domain:secure:)")
    public static func from(domain: String, secure: Bool = true, completion:@escaping TomlFileClosure) {
        Task {
            let result = await from(domain: domain, secure: secure)
            completion(result)
        }
    }

    /// Loads and parses stellar.toml file from a domain per SEP-0001.
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
