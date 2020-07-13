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
    
    /// Stellar public key
    /// The signing key is used for the compliance protocol
    public let signingKey: String?
    
    /// url
    /// Location of public-facing Horizon instance (if one is offered)
    public let horizonUrl: String?
    
    /// list of G... strings
    /// A list of Stellar accounts that are controlled by this domain. Names defined in NODE_NAMES can be used as well, prefixed with $.
    public let accounts: [String]
    
    
    /// URI request signing key
    public let uriRequestSigningKey: String?
    
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
    }
}
