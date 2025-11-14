//
//  URISchemeEnums.swift
//  stellarsdk
//
//  Created by Soneso on 11/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used for the sign transaction parameters for URIScheme creation.
public enum SignTransactionParams {
    /// The base64-encoded transaction envelope XDR to be signed.
    case xdr
    /// Fields to be replaced in the XDR using Txrep (SEP-0011) representation.
    case replace
    /// URL callback to receive the signed transaction XDR.
    case callback
    /// Public key of the account that will sign the transaction.
    case pubkey
    /// A SEP-0007 request that spawned or triggered the creation of this request.
    case chain
    /// Additional information to show the user in their wallet.
    case msg
    /// Network passphrase for networks other than the public Stellar network.
    case network_passphrase
    /// Fully qualified domain name specifying the originating domain of the URI request.
    case origin_domain
    /// Signature of the hash of the URI request for verification.
    case signature
}

/// An enum used for the pay operation parameters for URIScheme creation.
public enum PayOperationParams {
    /// Valid account ID or payment address that will receive the payment.
    case destination
    /// Amount that the destination will receive.
    case amount
    /// Asset code that the destination will receive (XLM if not present).
    case asset_code
    /// Account ID of the asset issuer (XLM if not present).
    case asset_issuer
    /// Memo to be included in the payment or path payment operation.
    case memo
    /// Type of memo: MEMO_TEXT, MEMO_ID, MEMO_HASH, or MEMO_RETURN.
    case memo_type
    /// URL callback to receive the transaction XDR after signing.
    case callback
    /// Additional information to show the user in their wallet.
    case msg
    /// Network passphrase for networks other than the public Stellar network.
    case network_passphrase
    /// Fully qualified domain name specifying the originating domain of the URI request.
    case origin_domain
    /// Signature of the hash of the URI request for verification.
    case signature
}
