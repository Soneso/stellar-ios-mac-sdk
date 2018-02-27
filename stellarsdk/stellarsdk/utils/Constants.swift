//
//  Constants.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AssetTypeAsString
{
    public static let NATIVE = "native"
    public static let CREDIT_ALPHANUM4 = "credit_alphanum4"
    public static let CREDIT_ALPHANUM12 = "credit_alphanum12"
    
}

public struct EffectTypeAsString
{
    public static let ACCOUNT_CREATED = "account_created"
    public static let ACCOUNT_REMOVED = "account_removed"
    public static let ACCOUNT_CREDITED = "account_credited"
    public static let ACCOUNT_DEBITED = "account_debited"
    public static let ACCOUNT_THRESHOLDS_UPDATED = "account_thresholds_updated"
    public static let ACCOUNT_HOME_DOMAIN_UPDATED = "account_home_domain_updated"
    public static let ACCOUNT_FLAGS_UPDATED = "account_flags_updated"
    public static let SIGNER_CREATED = "signer_created"
    public static let SIGNER_REMOVED = "signer_removed"
    public static let SIGNER_UPDATED = "signer_updated"
    public static let TRUSTLINE_CREATED = "trustline_created"
    public static let TRUSTLINE_REMOVED = "trustline_removed"
    public static let TRUSTLINE_UPDATED = "trustline_updated"
    public static let TRUSTLINE_AUTHORIZED = "trustline_authorized"
    public static let TRUSTLINE_DEAUTHORIZED = "trustline_deauthorized"
    public static let OFFER_CREATED = "offer_created"
    public static let OFFER_REMOVED = "offer_removed"
    public static let OFFER_UPDATED = "offer_updated"
    public static let TRADE = "trade"
    
}

public struct MemoTypeAsString
{
    public static let NONE = "none"
    public static let TEXT = "text"
    public static let ID = "id"
    public static let HASH = "hash"
    public static let RETURN = "return"
    
}

