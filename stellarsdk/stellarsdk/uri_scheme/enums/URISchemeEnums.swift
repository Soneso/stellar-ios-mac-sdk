//
//  URISchemeEnums.swift
//  stellarsdk
//
//  Created by Soneso on 11/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used for the sing transaction parameters for URIScheme creation.
public enum SignTransactionParams {
    case xdr
    case callback
    case pubkey
    case msg
    case network_passphrase
    case origin_domain
    case signature
}

/// An enum used for the pay operation parameters for URIScheme creation.
public enum PayOperationParams {
    case destination
    case amount
    case asset_code
    case asset_issuer
    case memo
    case memo_type
    case callback
    case msg
    case network_passphrase
    case origin_domain
    case signature
}
