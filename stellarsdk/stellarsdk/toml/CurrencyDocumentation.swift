//
//  CurrencyDocumentation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class CurrencyDocumentation {

    private enum Keys: String {
        case code = "code"
        case codeTemplate = "code_template"
        case issuer = "issuer"
        case toml = "toml"
        case status = "status"
        case displayDecimals = "display_decimals"
        case name = "name"
        case desc = "desc"
        case conditions = "conditions"
        case image = "image"
        case fixedNumber = "fixed_number"
        case maxNumber = "max_number"
        case isUnlimited = "is_unlimited"
        case isAssetAnchored = "is_asset_anchored"
        case anchorAssetType = "anchor_asset_type"
        case anchorAsset = "anchor_asset"
        case redemptionInstructions = "redemption_instructions"
        case collateralAddresses = "collateral_addresses"
        case collateralAddressMessages = "collateral_address_messages"
        case collateralAddressSignatures = "collateral_address_signatures"
        case regulated = "regulated"
        case approvalServer = "approval_server"
        case approvalCriteria = "approval_criteria"
    }

    /// string (<= 12 char)
    /// Token code
    public var code: String?
    
    /// string (<= 12 char)
    /// A pattern with ? as a single character wildcard. Allows a [[CURRENCIES]] entry to apply to multiple assets that share the same info. An example is futures, where the only difference between issues is the date of the contract. E.g. CORN???????? to match codes such as CORN20180604.
    public var codeTemplate: String?
    
    /// G... string
    /// Token issuer Stellar public key
    public var issuer: String?
    
    /// Alternately, stellar.toml can link out to a separate TOML file for each currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
    public var toml: String?
    
    /// Status of token. One of live, dead, test, or private. Allows issuer to mark whether token is dead/for testing/for private use or is live and should be listed in live exchanges.
    public var status: String?
    
    /// int (0 to 7)
    /// Preference for number of decimals to show when a client displays currency balance
    public var displayDecimals: Int?
    
    /// string (<= 20 char)
    /// A short name for the token
    public var name: String?
    
    /// Description of token and what it represents
    public var desc: String?
    
    /// Conditions on token
    public var conditions: String?
    
    /// URL to image representing token
    public var image: String?
    
    /// Fixed number of tokens, if the number of tokens issued will never change
    public var fixedNumber: Int?
    
    /// Max number of tokens, if there will never be more than max_number tokens
    public var maxNumber: Int?
    
    /// The number of tokens is dilutable at the issuer's discretion
    public var isUnlimited: Bool?
    
    /// true if token can be redeemed for underlying asset, otherwise false
    public var isAssetAnchored: Bool?
    
    /// Type of asset anchored. Can be fiat, crypto, nft, stock, bond, commodity, realestate, or other.
    public var anchorAssetType: String?
    
    /// If anchored token, asset that token is anchored to. E.g. USD, BTC, SBUX, Address of real-estate investment property.
    public var anchorAsset: String?
    
    /// If anchored token, these are instructions to redeem the underlying asset from tokens.
    public var redemptionInstructions: String?
    
    /// list of crypto address strings
    /// If this is an anchored crypto token, list of one or more public addresses that hold the assets for which you are issuing tokens.
    public var collateralAddresses: [String]
    
    /// list of message strings
    /// Messages stating that funds in the collateral_addresses list are reserved to back the issued asset. See below for details.
    public var collateralAddressMessages: [String]
    
    /// list of signature strings
    /// These prove you control the collateral_addresses. For each address you list, sign the entry in collateral_address_messages with the address's private key and add the resulting string to this list as a base64-encoded raw signature.
    public var collateralAddressSignatures: [String]
    
    /// indicates whether or not this is a sep0008 regulated asset. If missing, false is assumed.
    public var regulated: Bool?
    
    /// url of a sep0008 compliant approval service that signs validated transactions.
    public var approvalServer: String?
    
    /// a human readable string that explains the issuer's requirements for approving transactions.
    public var approvalCriteria: String?
    
    public init(fromToml toml:Toml) {
        code = toml.string(Keys.code.rawValue)
        codeTemplate = toml.string(Keys.codeTemplate.rawValue)
        issuer = toml.string(Keys.issuer.rawValue)
        self.toml = toml.string(Keys.toml.rawValue)
        status = toml.string(Keys.status.rawValue)
        displayDecimals = toml.int(Keys.displayDecimals.rawValue)
        name = toml.string(Keys.name.rawValue)
        desc = toml.string(Keys.desc.rawValue)
        conditions = toml.string(Keys.conditions.rawValue)
        image = toml.string(Keys.image.rawValue)
        fixedNumber = toml.int(Keys.fixedNumber.rawValue)
        maxNumber = toml.int(Keys.maxNumber.rawValue)
        isUnlimited = toml.bool(Keys.isUnlimited.rawValue)
        isAssetAnchored = toml.bool(Keys.isAssetAnchored.rawValue)
        anchorAssetType = toml.string(Keys.anchorAssetType.rawValue)
        anchorAsset = toml.string(Keys.anchorAsset.rawValue)
        redemptionInstructions = toml.string(Keys.redemptionInstructions.rawValue)
        collateralAddresses = toml.array(Keys.collateralAddresses.rawValue) ?? []
        collateralAddressMessages = toml.array(Keys.collateralAddressMessages.rawValue) ?? []
        collateralAddressSignatures = toml.array(Keys.collateralAddressSignatures.rawValue) ?? []
        regulated = toml.bool(Keys.regulated.rawValue)
        approvalServer = toml.string(Keys.approvalServer.rawValue)
        approvalCriteria = toml.string(Keys.approvalCriteria.rawValue)
    }
    
}
