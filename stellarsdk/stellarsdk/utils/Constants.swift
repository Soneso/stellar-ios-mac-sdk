//
//  Constants.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// String constants for asset types used in Horizon API responses and requests.
///
/// These constants represent the different asset types supported by the Stellar network
/// and are used when parsing or constructing API requests and responses.
///
/// See: [Stellar developer docs](https://developers.stellar.org) for more information.
public struct AssetTypeAsString: Sendable {
    /// Native asset type (XLM).
    public static let NATIVE = "native"

    /// Asset type for assets with codes 1-4 characters long.
    public static let CREDIT_ALPHANUM4 = "credit_alphanum4"

    /// Asset type for assets with codes 5-12 characters long.
    public static let CREDIT_ALPHANUM12 = "credit_alphanum12"

    /// Asset type for liquidity pool shares.
    public static let POOL_SHARE = "liquidity_pool_shares"

}

/// String constants for effect types used in Horizon API responses.
///
/// Effects represent specific changes that occur on the Stellar network as a result of operations.
/// These constants are used when parsing effect responses from the Horizon server.
///
/// See: [Stellar developer docs](https://developers.stellar.org) for more information.
public struct EffectTypeAsString: Sendable {
    /// Effect when a new account is created on the network.
    public static let ACCOUNT_CREATED = "account_created"

    /// Effect when an account is removed from the network.
    public static let ACCOUNT_REMOVED = "account_removed"

    /// Effect when an account receives a payment or asset.
    public static let ACCOUNT_CREDITED = "account_credited"

    /// Effect when an account sends a payment or asset.
    public static let ACCOUNT_DEBITED = "account_debited"

    /// Effect when account thresholds are modified.
    public static let ACCOUNT_THRESHOLDS_UPDATED = "account_thresholds_updated"

    /// Effect when an account's home domain is changed.
    public static let ACCOUNT_HOME_DOMAIN_UPDATED = "account_home_domain_updated"

    /// Effect when account flags are modified.
    public static let ACCOUNT_FLAGS_UPDATED = "account_flags_updated"

    /// Effect when a new signer is added to an account.
    public static let SIGNER_CREATED = "signer_created"

    /// Effect when a signer is removed from an account.
    public static let SIGNER_REMOVED = "signer_removed"

    /// Effect when a signer's weight is modified.
    public static let SIGNER_UPDATED = "signer_updated"

    /// Effect when a new trustline is established.
    public static let TRUSTLINE_CREATED = "trustline_created"

    /// Effect when a trustline is removed.
    public static let TRUSTLINE_REMOVED = "trustline_removed"

    /// Effect when trustline properties are modified.
    public static let TRUSTLINE_UPDATED = "trustline_updated"

    /// Effect when a trustline is authorized by the asset issuer.
    public static let TRUSTLINE_AUTHORIZED = "trustline_authorized"

    /// Effect when a trustline authorization is revoked by the asset issuer.
    public static let TRUSTLINE_DEAUTHORIZED = "trustline_deauthorized"

    /// Effect when a new offer is created on the DEX.
    public static let OFFER_CREATED = "offer_created"

    /// Effect when an offer is removed from the DEX.
    public static let OFFER_REMOVED = "offer_removed"

    /// Effect when an offer is modified on the DEX.
    public static let OFFER_UPDATED = "offer_updated"

    /// Effect when a trade is executed on the DEX.
    public static let TRADE = "trade"

    /// Effect when account data is set or modified.
    public static let MANAGE_DATA = "manage_data"

    /// Effect when an account's sequence number is bumped.
    public static let BUMP_SEQUENCE = "bump_sequence"

}

/// String constants for memo types used in transactions.
///
/// Memos are optional attachments to transactions that can be used to include additional
/// information or identification.
///
/// See: [Stellar developer docs](https://developers.stellar.org) for more information.
public struct MemoTypeAsString: Sendable {
    /// No memo attached to the transaction.
    public static let NONE = "none"

    /// Text memo up to 28 bytes.
    public static let TEXT = "text"

    /// 64-bit unsigned integer memo.
    public static let ID = "id"

    /// 32-byte hash memo.
    public static let HASH = "hash"

    /// 32-byte hash memo for returning payments.
    public static let RETURN = "return"

}

