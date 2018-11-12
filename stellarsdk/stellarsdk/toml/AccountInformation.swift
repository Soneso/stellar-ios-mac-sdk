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
        case federationServer = "FEDERATION_SERVER"
        case authServer = "AUTH_SERVER"
        case transferServer = "TRANSFER_SERVER"
        case webAuthEndpoint = "WEB_AUTH_ENDPOINT"
        case signingKey = "SIGNING_KEY"
        case nodeNames = "NODE_NAMES"
        case accounts = "ACCOUNTS"
        case ourValidators = "OUR_VALIDATORS"
        case assetValidator = "ASSET_VALIDATOR"
        case desiredBaseFee = "DESIRED_BASE_FEE"
        case desiredMaxTxPerLedger = "DESIRED_MAX_TX_PER_LEDGER"
        case knownPeers = "KNOWN_PEERS"
        case history = "HISTORY"
        case uriRequestSigningKey = "URI_REQUEST_SIGNING_KEY"
    }
    
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
    /// The endpoint used for SEP-10 Web Authentication
    public let webAuthEndpoint: String?
    
    /// Stellar public key
    /// The signing key is used for the compliance protocol
    public let signingKey: String?
    
    /// list of "G... name" strings
    /// convenience mapping of common names to node IDs. You can use these common names in sections below instead of the less friendly nodeID. This is provided mainly to be compatible with the stellar-core.cfg
    public let nodeNames: [String]
    
    /// list of G... strings
    /// A list of Stellar accounts that are controlled by this domain. Names defined in NODE_NAMES can be used as well, prefixed with $.
    public let accounts: [String]
    
    /// list of G... strings
    /// A list of validator public keys that are declared to be used by this domain for validating ledgers. They are authorized signers for the domain. Names defined in NODE_NAMES can be used as well, prefixed with $.
    public let ourValidators: [String]
    
    /// G... string
    /// The validator through which the issuer pledges to honor redemption transactions, and which therefore maintains the authoritative ownership records for assets issued by this organization. Specified as a public key G... or NODE_NAME prefixed with $. This field may also contain a list of validators. In this case, transactions must be processed by all listed validators. In the event that this field specifies multiple validators and they do not all agree, then the authoritative ownership records will be the last ledger number on which all validators agree.
    public let assetValidator: String?
    
    /// Your preference for the Stellar network base fee, expressed in stroops
    public let desiredBaseFee: Int?
    
    /// Your preference for max number of transactions per ledger close
    public let desiredMaxTxPerLedger: Int?
    
    /// list of strings
    /// List of known Stellar core servers, listed from most to least trusted if known. Can be IP:port, IPv6:port, or domain:port with the :port optional.
    public let knownPeers: [String]
    
    /// list of URL strings
    /// List of history archives maintained by this domain
    public let history: [String]
    
    /// URI request signing key
    public let uriRequestSigningKey: String?
    
    public init(fromToml toml:Toml) {
        federationServer = toml.string(Keys.federationServer.rawValue)
        authServer = toml.string(Keys.authServer.rawValue)
        transferServer = toml.string(Keys.transferServer.rawValue)
        webAuthEndpoint = toml.string(Keys.webAuthEndpoint.rawValue)
        signingKey = toml.string(Keys.signingKey.rawValue)
        nodeNames = toml.array(Keys.nodeNames.rawValue) ?? []
        accounts = toml.array(Keys.accounts.rawValue) ?? []
        ourValidators = toml.array(Keys.ourValidators.rawValue) ?? []
        assetValidator = toml.string(Keys.assetValidator.rawValue)
        desiredBaseFee = toml.int(Keys.desiredBaseFee.rawValue)
        desiredMaxTxPerLedger = toml.int(Keys.desiredMaxTxPerLedger.rawValue)
        knownPeers = toml.array(Keys.knownPeers.rawValue) ?? []
        history = toml.array(Keys.history.rawValue) ?? []
        uriRequestSigningKey = toml.string(Keys.uriRequestSigningKey.rawValue)
    }
    
}
