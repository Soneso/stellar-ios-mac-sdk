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
        case validators = "VALIDATORS"
    }

    /// list of G... strings
    /// List of authoritative validators for organization. This can potentially be a quorum set. Names defined in NODE_NAMES can be used as well, prefixed with $.
    public let validators: [String]
    
    public init(fromToml toml:Toml) {
        validators = toml.array(Keys.validators.rawValue) ?? []
    }
    
}
