//
//  ValidatorInformation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

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
    
    public init(fromToml toml:Toml) {
        alias = toml.string(Keys.alias.rawValue)
        displayName = toml.string(Keys.displayName.rawValue)
        publicKey = toml.string(Keys.publicKey.rawValue)
        host = toml.string(Keys.host.rawValue)
        history = toml.string(Keys.history.rawValue)
    }
}
