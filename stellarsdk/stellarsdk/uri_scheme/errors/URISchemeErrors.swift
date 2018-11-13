//
//  URISchemeErrors.swift
//  stellarsdk
//
//  Created by Soneso on 10/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors thrown by the uri scheme
public enum URISchemeErrors {
    case invalidSignature
    case invalidOriginDomain
    case missingOriginDomain
    case missingSignature
    case originDomainSignatureMismatch
    case invalidTomlDomain
    case invalidToml
    case tomlSignatureMissing
}
