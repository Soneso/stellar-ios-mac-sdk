//
//  URISchemeErrors.swift
//  stellarsdk
//
//  Created by Soneso on 10/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors thrown by the uri scheme
public enum URISchemeErrors: Sendable {
    /// The signature provided in the URI is invalid or cannot be verified.
    case invalidSignature
    /// The origin domain format is invalid or not a fully qualified domain name.
    case invalidOriginDomain
    /// The required origin_domain parameter is missing from the URI.
    case missingOriginDomain
    /// The required signature parameter is missing from the URI.
    case missingSignature
    /// The domain specified in the TOML file is invalid.
    case invalidTomlDomain
    /// The stellar.toml file is malformed or cannot be parsed.
    case invalidToml
    /// The URI_REQUEST_SIGNING_KEY field is missing from the stellar.toml file.
    case tomlSignatureMissing
}
