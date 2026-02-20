//
//  StellarToml.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when loading a stellar.toml file from a domain.
public enum TomlFileError: Error, Sendable {
    /// The provided domain is invalid or cannot be used to construct a valid URL.
    case invalidDomain
    /// The stellar.toml file could not be parsed or contains invalid TOML syntax.
    case invalidToml
}

/// Errors that can occur when loading a linked currency TOML file from a URL.
///
/// Per SEP-0001, a stellar.toml can link to separate TOML files for individual currencies
/// using toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
public enum TomlCurrencyLoadError: Error, Sendable {
    /// The provided URL string is invalid or cannot be parsed.
    case invalidUrl
    /// The currency TOML file could not be parsed or contains invalid TOML syntax.
    case invalidToml
}

/// Result type for stellar.toml loading operations.
public enum TomlForDomainEnum: Sendable {
    /// Successfully loaded and parsed stellar.toml file from the domain.
    case success(response: StellarToml)
    /// Failed to load or parse the stellar.toml file from the domain.
    case failure(error: TomlFileError)
}

/// Result type for currency TOML loading operations.
public enum TomlCurrencyFromUrlEnum: Sendable {
    /// Successfully loaded and parsed currency TOML from the linked URL per SEP-0001.
    case success(response: CurrencyDocumentation)
    /// Failed to load or parse the currency TOML from the linked URL.
    case failure(error: TomlCurrencyLoadError)
}

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
public final class StellarToml: Sendable {

    /// Service endpoints and signing keys from the stellar.toml ACCOUNT section.
    public let accountInformation: AccountInformation
    /// Organization and issuer metadata from the stellar.toml DOCUMENTATION section.
    public let issuerDocumentation: IssuerDocumentation
    /// Key personnel and support contact information from the stellar.toml PRINCIPALS section.
    public let pointsOfContact: [PointOfContactDocumentation]
    /// Supported asset definitions and metadata from the stellar.toml CURRENCIES section.
    public let currenciesDocumentation: [CurrencyDocumentation]
    /// Validator node configuration and history archives from the stellar.toml VALIDATORS section.
    public let validatorsInformation: [ValidatorInformation]

    /// Creates a StellarToml instance by parsing a TOML string.
    ///
    /// - Parameter string: A string containing the stellar.toml content
    /// - Throws: `TomlFileError.invalidToml` if the string is invalid or cannot be parsed
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
            var pocs = [PointOfContactDocumentation]()
            for pocToml in principals.tables() {
                pocs.append(PointOfContactDocumentation(fromToml: pocToml))
            }
            pointsOfContact = pocs
        } else {
            pointsOfContact = []
        }
        if let currencies = toml.table("CURRENCIES") {
            var docs = [CurrencyDocumentation]()
            for currencies in currencies.tables() {
                docs.append(CurrencyDocumentation(fromToml: currencies))
            }
            currenciesDocumentation = docs
        } else {
            currenciesDocumentation = []
        }

        if let validators = toml.table("VALIDATORS") {
            var vals = [ValidatorInformation]()
            for validatorToml in validators.tables() {
                vals.append(ValidatorInformation(fromToml: validatorToml))
            }
            validatorsInformation = vals
        } else {
            validatorsInformation = []
        }

    }
    
    /// Loads and parses stellar.toml file from a domain per SEP-0001.
    ///
    /// Fetches the stellar.toml file from `https://{domain}/.well-known/stellar.toml`
    /// (or `http://` if secure is false) and parses its contents.
    ///
    /// - Parameter domain: The domain without scheme (e.g., "example.com")
    /// - Parameter secure: If true, uses HTTPS to fetch stellar.toml (default: true)
    /// - Returns: TomlForDomainEnum with the parsed StellarToml or an error
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
    
    /// Loads currency information from a linked TOML file URL.
    ///
    /// Per SEP-0001, a stellar.toml can link to separate TOML files for individual currencies
    /// by specifying `toml="https://DOMAIN/.well-known/CURRENCY.toml"` as the currency's only field.
    ///
    /// - Parameter url: The complete URL to the currency TOML file
    /// - Returns: TomlCurrencyFromUrlEnum with the parsed CurrencyDocumentation or an error
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
