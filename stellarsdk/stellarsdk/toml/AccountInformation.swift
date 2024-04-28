//
//  AccountInformation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class AccountInformation {

    private enum Keys: String {
        case version = "VERSION"
        case networkPassphrase = "NETWORK_PASSPHRASE"
        case federationServer = "FEDERATION_SERVER"
        case authServer = "AUTH_SERVER"
        case transferServer = "TRANSFER_SERVER"
        case transferServerSep24 = "TRANSFER_SERVER_SEP0024"
        case kycServer = "KYC_SERVER"
        case webAuthEndpoint = "WEB_AUTH_ENDPOINT"
        case signingKey = "SIGNING_KEY"
        case horizonUrl = "HORIZON_URL"
        case accounts = "ACCOUNTS"
        case uriRequestSigningKey = "URI_REQUEST_SIGNING_KEY"
        case directPaymentServer = "DIRECT_PAYMENT_SERVER"
        case anchorQuoteServer = "ANCHOR_QUOTE_SERVER"
        
    }
    
    /// string
    /// The version of SEP-1 your stellar.toml adheres to. This helps parsers know which fields to expect.
    public var version: String?
    
    /// string
    /// The passphrase for the specific Stellar network this infrastructure operates on
    public var networkPassphrase: String?
    
    /// uses https:
    /// The endpoint for clients to resolve stellar addresses for users on your domain via SEP-2 federation protocol
    public var federationServer: String?
    
    /// uses https:
    /// The endpoint used for SEP-3 Compliance Protocol
    public var authServer: String?
    
    /// uses https:
    /// The server used for SEP-6 Anchor/Client interoperability
    public var transferServer: String?
    
    /// uses https:
    /// The server used for SEP-24 Anchor/Client interoperability
    public var transferServerSep24: String?
    
    /// uses https:
    /// The server used for SEP-12 Anchor/Client customer info transfer
    public var kycServer: String?
    
    /// uses https:
    /// The endpoint used for SEP-10 Web Authentication
    public var webAuthEndpoint: String?
    
    /// Stellar public key
    /// The signing key is used for SEP-3 Compliance Protocol (deprecated) and SEP-10 Authentication Protocol
    public var signingKey: String?
    
    /// url
    /// Location of public-facing Horizon instance (if one is offered)
    public var horizonUrl: String?
    
    /// list of G... strings
    /// A list of Stellar accounts that are controlled by this domain.
    public var accounts: [String]
    
    /// The signing key is used for SEP-7 delegated signing
    public var uriRequestSigningKey: String?
    
    /// The server used for receiving SEP-31 direct fiat-to-fiat payments. Requires SEP-12 and hence a KYC_SERVER TOML attribute.
    public var directPaymentServer: String?
    
    /// The server used for receiving SEP-38 requests.
    public var anchorQuoteServer: String?
    
    public init(fromToml toml:Toml) {
        version = toml.string(Keys.version.rawValue)
        networkPassphrase = toml.string(Keys.networkPassphrase.rawValue)
        federationServer = toml.string(Keys.federationServer.rawValue)
        authServer = toml.string(Keys.authServer.rawValue)
        transferServer = toml.string(Keys.transferServer.rawValue)
        transferServerSep24 = toml.string(Keys.transferServerSep24.rawValue)
        kycServer = toml.string(Keys.kycServer.rawValue)
        webAuthEndpoint = toml.string(Keys.webAuthEndpoint.rawValue)
        signingKey = toml.string(Keys.signingKey.rawValue)
        horizonUrl = toml.string(Keys.horizonUrl.rawValue)
        accounts = toml.array(Keys.accounts.rawValue) ?? []
        uriRequestSigningKey = toml.string(Keys.uriRequestSigningKey.rawValue)
        directPaymentServer = toml.string(Keys.directPaymentServer.rawValue)
        anchorQuoteServer = toml.string(Keys.anchorQuoteServer.rawValue)
    }
}
