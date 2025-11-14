//
//  ValidatorInformation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents validator node information from a stellar.toml file.
///
/// This class parses and provides access to the VALIDATORS section of a domain's
/// stellar.toml file. It contains information about Stellar validator nodes operated
/// by the organization, including connection details and history archive locations.
///
/// Validator information is essential for network participants who need to configure
/// their nodes to connect to trusted validators. This includes the validator's public
/// key, network address, and the location of its history archive for catchup operations.
///
/// Developers use this class when building node configuration tools, validator
/// explorers, or applications that need to discover and connect to trusted validators
/// on the Stellar network.
///
/// See also:
/// - [StellarToml] for the main stellar.toml parser
/// - [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
/// - [Stellar developer docs](https://developers.stellar.org)
public class ValidatorInformation {

    private enum Keys: String {
        case alias = "ALIAS"
        case displayName = "DISPLAY_NAME"
        case publicKey = "PUBLIC_KEY"
        case host = "HOST"
        case history = "HISTORY"
    }
    
    /// string
    /// A name for display in stellar-core configs that conforms to ^[a-z0-9-]{2,16}$
    public var alias: String?
    
    /// string
    /// A human-readable name for display in quorum explorers and other interfaces
    public var displayName: String?
    
    /// G... string
    /// The Stellar account associated with the node
    public var publicKey: String?
    
    /// G... string
    /// The IP:port or domain:port peers can use to connect to the node
    public var host: String?
    
    /// uri
    /// The location of the history archive published by this validator
    public var history: String?

    /// Initializes validator information from a parsed TOML document.
    ///
    /// - Parameter toml: The parsed TOML document containing validator configuration
    public init(fromToml toml:Toml) {
        alias = toml.string(Keys.alias.rawValue)
        displayName = toml.string(Keys.displayName.rawValue)
        publicKey = toml.string(Keys.publicKey.rawValue)
        host = toml.string(Keys.host.rawValue)
        history = toml.string(Keys.history.rawValue)
    }
}
