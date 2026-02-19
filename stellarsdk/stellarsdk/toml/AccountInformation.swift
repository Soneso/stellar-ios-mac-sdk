//
//  AccountInformation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents account and service endpoint information from a stellar.toml file.
///
/// This class parses and provides access to the account-level configuration section
/// of a domain's stellar.toml file. It contains service endpoints for various SEPs
/// (Stellar Ecosystem Proposals), signing keys, and account identifiers.
///
/// Developers use this class to discover service URLs for operations such as:
/// - SEP-10 web authentication
/// - SEP-6 and SEP-24 transfer/deposit/withdrawal operations
/// - SEP-12 customer information transfer
/// - SEP-31 direct payments
/// - SEP-38 quotes
/// - Federation services
///
/// See also:
/// - [StellarToml] for the main stellar.toml parser
/// - [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
public final class AccountInformation: Sendable {

    private enum Keys: String {
        case version = "VERSION"
        case networkPassphrase = "NETWORK_PASSPHRASE"
        case federationServer = "FEDERATION_SERVER"
        case authServer = "AUTH_SERVER"
        case transferServer = "TRANSFER_SERVER"
        case transferServerSep24 = "TRANSFER_SERVER_SEP0024"
        case kycServer = "KYC_SERVER"
        case webAuthEndpoint = "WEB_AUTH_ENDPOINT"
        case webAuthForContractsEndpoint = "WEB_AUTH_FOR_CONTRACTS_ENDPOINT"
        case webAuthContractId = "WEB_AUTH_CONTRACT_ID"
        case signingKey = "SIGNING_KEY"
        case horizonUrl = "HORIZON_URL"
        case accounts = "ACCOUNTS"
        case uriRequestSigningKey = "URI_REQUEST_SIGNING_KEY"
        case directPaymentServer = "DIRECT_PAYMENT_SERVER"
        case anchorQuoteServer = "ANCHOR_QUOTE_SERVER"

    }
    
    /// string
    /// The version of SEP-1 your stellar.toml adheres to. This helps parsers know which fields to expect.
    public let version: String?
    
    /// string
    /// The passphrase for the specific Stellar network this infrastructure operates on
    public let networkPassphrase: String?
    
    /// uses https:
    /// The endpoint for clients to resolve stellar addresses for users on your domain via SEP-2 federation protocol
    public let federationServer: String?
    
    /// uses https:
    /// The endpoint used for SEP-3 Compliance Protocol
    public let authServer: String?
    
    /// uses https:
    /// The server used for SEP-6 Anchor/Client interoperability
    public let transferServer: String?
    
    /// uses https:
    /// The server used for SEP-24 Anchor/Client interoperability
    public let transferServerSep24: String?
    
    /// uses https:
    /// The server used for SEP-12 Anchor/Client customer info transfer
    public let kycServer: String?
    
    /// uses https:
    /// The endpoint used for SEP-10 Web Authentication
    public let webAuthEndpoint: String?

    /// uses https:
    /// The endpoint used for SEP-45 Web Authentication for Contracts
    public let webAuthForContractsEndpoint: String?

    /// string
    /// The web authentication contract ID for SEP-45 Web Authentication
    public let webAuthContractId: String?

    /// Stellar public key
    /// The signing key is used for SEP-3 Compliance Protocol (deprecated) and SEP-10 Authentication Protocol
    public let signingKey: String?
    
    /// url
    /// Location of public-facing Horizon instance (if one is offered)
    public let horizonUrl: String?
    
    /// list of G... strings
    /// A list of Stellar accounts that are controlled by this domain.
    public let accounts: [String]
    
    /// The signing key is used for SEP-7 delegated signing
    public let uriRequestSigningKey: String?
    
    /// The server used for receiving SEP-31 direct fiat-to-fiat payments. Requires SEP-12 and hence a KYC_SERVER TOML attribute.
    public let directPaymentServer: String?
    
    /// The server used for receiving SEP-38 requests.
    public let anchorQuoteServer: String?

    /// Initializes account information from a parsed TOML document.
    ///
    /// - Parameter toml: The parsed TOML document containing account configuration
    public init(fromToml toml:Toml) {
        version = toml.string(Keys.version.rawValue)
        networkPassphrase = toml.string(Keys.networkPassphrase.rawValue)
        federationServer = toml.string(Keys.federationServer.rawValue)
        authServer = toml.string(Keys.authServer.rawValue)
        transferServer = toml.string(Keys.transferServer.rawValue)
        transferServerSep24 = toml.string(Keys.transferServerSep24.rawValue)
        kycServer = toml.string(Keys.kycServer.rawValue)
        webAuthEndpoint = toml.string(Keys.webAuthEndpoint.rawValue)
        webAuthForContractsEndpoint = toml.string(Keys.webAuthForContractsEndpoint.rawValue)
        webAuthContractId = toml.string(Keys.webAuthContractId.rawValue)
        signingKey = toml.string(Keys.signingKey.rawValue)
        horizonUrl = toml.string(Keys.horizonUrl.rawValue)
        accounts = toml.array(Keys.accounts.rawValue) ?? []
        uriRequestSigningKey = toml.string(Keys.uriRequestSigningKey.rawValue)
        directPaymentServer = toml.string(Keys.directPaymentServer.rawValue)
        anchorQuoteServer = toml.string(Keys.anchorQuoteServer.rawValue)
    }
}
