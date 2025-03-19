//
//  AnchorInfoResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AnchorInfoResponse: Decodable {

    public var deposit: [String:DepositAsset]?
    public var depositExchange: [String:DepositExchangeAsset]?
    public var withdraw: [String:WithdrawAsset]?
    public var withdrawExchange: [String:WithdrawExchangeAsset]?
    public var transactions: AnchorTransactionsInfo?
    public var transaction: AnchorTransactionInfo?
    public var fee: AnchorFeeInfo?
    public var features: AnchorFeatureFlags?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case deposit = "deposit"
        case depositExchange = "deposit-exchange"
        case withdraw = "withdraw"
        case withdrawExchange = "withdraw-exchange"
        case transactions = "transactions"
        case transaction = "transaction"
        case fee = "fee"
        case features
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        deposit = try values.decodeIfPresent([String:DepositAsset].self, forKey: .deposit)
        depositExchange = try values.decodeIfPresent([String:DepositExchangeAsset].self, forKey: .depositExchange)
        withdraw = try values.decodeIfPresent([String:WithdrawAsset].self, forKey: .withdraw)
        withdrawExchange = try values.decodeIfPresent([String:WithdrawExchangeAsset].self, forKey: .withdrawExchange)
        transactions = try values.decodeIfPresent(AnchorTransactionsInfo.self, forKey: .transactions)
        transaction = try values.decodeIfPresent(AnchorTransactionInfo.self, forKey: .transaction)
        fee = try values.decodeIfPresent(AnchorFeeInfo.self, forKey: .fee)
        features = try values.decodeIfPresent(AnchorFeatureFlags.self, forKey: .features)
    }
    
}

public struct DepositAsset: Decodable {
    
    /// true if SEP-6 deposit for this asset is supported
    public var enabled: Bool
    
    /// Optional. true if client must be authenticated before accessing the deposit endpoint for this asset. false if not specified.
    public var authenticationRequired: Bool?
    
    /// Optional fixed (flat) fee for deposit, in units of the Stellar asset.  Nil if there is no fee or the fee schedule is complex.
    public var feeFixed: Double?
    
    /// Optional percentage fee for deposit, in percentage points of the Stellar asset. Nil if there is no fee or the fee schedule is complex.
    public var feePercent: Double?
    
    /// Optional minimum amount. No limit if not specified.
    public var minAmount:Double?
    
    /// Optional maximum amount. No limit if not specified.
    public var maxAmount:Double?
    
    /// (Deprecated) Accepting personally identifiable information through request parameters is a security risk due to web server request logging. KYC information should be supplied to the Anchor via SEP-12).
    public var fields: [String:AnchorField]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case authenticationRequired = "authentication_required"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case fields = "fields"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let enabledOpt = try values.decodeIfPresent(Bool.self, forKey: .enabled) {
            enabled = enabledOpt
        } else {
            enabled = false;
        }
        
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
        feeFixed = try values.decodeIfPresent(Double.self, forKey: .feeFixed)
        feePercent = try values.decodeIfPresent(Double.self, forKey: .feePercent)
        minAmount = try values.decodeIfPresent(Double.self, forKey: .minAmount)
        maxAmount = try values.decodeIfPresent(Double.self, forKey: .maxAmount)
        fields = try values.decodeIfPresent([String:AnchorField].self, forKey: .fields)
    }
}

public struct DepositExchangeAsset: Decodable {
    
    /// true if SEP-6 deposit for this asset is supported
    public var enabled: Bool
    
    /// Optional. true if client must be authenticated before accessing the deposit endpoint for this asset. false if not specified.
    public var authenticationRequired: Bool?
    
    /// (Deprecated) Accepting personally identifiable information through request parameters is a security risk due to web server request logging. KYC information should be supplied to the Anchor via SEP-12).
    public var fields: [String:AnchorField]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled
        case authenticationRequired = "authentication_required"
        case fields
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let enabledOpt = try values.decodeIfPresent(Bool.self, forKey: .enabled) {
            enabled = enabledOpt
        } else {
            enabled = false;
        }
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
        fields = try values.decodeIfPresent([String:AnchorField].self, forKey: .fields)
    }
}

public struct WithdrawAsset: Decodable {
    
    /// true if SEP-6 withdrawal for this asset is supported
    public var enabled: Bool
    
    /// Optional. true if client must be authenticated before accessing  the withdraw endpoint for this asset. false if not specified.
    public var authenticationRequired: Bool?
    
    /// Optional fixed (flat) fee for withdraw, in units of the Stellar asset. Nil if there is no fee or the fee schedule is complex.
    public var feeFixed: Double?
    
    /// Optional percentage fee for withdraw, in percentage points of the Stellar asset. Null if there is no fee or the fee schedule is complex.
    public var feePercent: Double?
    
    /// Optional minimum amount. No limit if not specified.
    public var minAmount:Double?
    
    /// Optional maximum amount. No limit if not specified.
    public var maxAmount:Double?
    
    /// A field with each type of withdrawal supported for that asset as a key.
    /// Each type can specify a fields object explaining what fields
    /// are needed and what they do. Anchors are encouraged to use SEP-9
    /// financial account fields, but can also define custom fields if necessary.
    /// If a fields object is not specified, the wallet should assume that no
    /// extra fields are needed for that type of withdrawal. In the case that
    /// the Anchor requires additional fields for a withdrawal, it should set the
    /// transaction status to pending_customer_info_update. The wallet can query
    /// the /transaction endpoint to get the fields needed to complete the
    /// transaction in required_customer_info_updates and then use SEP-12 to
    /// collect the information from the user.
    public var types: [String:WithdrawType]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case authenticationRequired = "authentication_required"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case types = "types"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let enabledOpt = try values.decodeIfPresent(Bool.self, forKey: .enabled) {
            enabled = enabledOpt
        } else {
            enabled = false;
        }
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
        feeFixed = try values.decodeIfPresent(Double.self, forKey: .feeFixed)
        feePercent = try values.decodeIfPresent(Double.self, forKey: .feePercent)
        minAmount = try values.decodeIfPresent(Double.self, forKey: .minAmount)
        maxAmount = try values.decodeIfPresent(Double.self, forKey: .maxAmount)
        types = try values.decodeIfPresent([String:WithdrawType].self, forKey: .types)
    }
}

public struct WithdrawExchangeAsset: Decodable {
    /// true if SEP-6 withdrawal for this asset is supported
    public var enabled: Bool
    
    /// Optional. true if client must be authenticated before accessing the withdraw endpoint for this asset. false if not specified.
    public var authenticationRequired: Bool?

    /// A field with each type of withdrawal supported for that asset as a key.
    /// Each type can specify a fields object explaining what fields
    /// are needed and what they do. Anchors are encouraged to use SEP-9
    /// financial account fields, but can also define custom fields if necessary.
    /// If a fields object is not specified, the wallet should assume that no
    /// extra fields are needed for that type of withdrawal. In the case that
    /// the Anchor requires additional fields for a withdrawal, it should set the
    /// transaction status to pending_customer_info_update. The wallet can query
    /// the /transaction endpoint to get the fields needed to complete the
    /// transaction in required_customer_info_updates and then use SEP-12 to
    /// collect the information from the user.
    public var types: [String:WithdrawType]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case authenticationRequired = "authentication_required"
        case types = "types"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let enabledOpt = try values.decodeIfPresent(Bool.self, forKey: .enabled) {
            enabled = enabledOpt
        } else {
            enabled = false;
        }
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
        types = try values.decodeIfPresent([String:WithdrawType].self, forKey: .types)
    }
}

public struct AnchorField: Decodable {
    
    public var description: String?
    public var optional: Bool?
    public var choices: [String]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case description = "description"
        case optional = "optional"
        case choices = "choices"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        optional = try values.decodeIfPresent(Bool.self, forKey: .optional)
        choices = try values.decodeIfPresent([String].self, forKey: .choices)
    }
}

public struct WithdrawType: Decodable {
    
    public var fields: [String:AnchorField]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case fields = "fields"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fields = try values.decodeIfPresent([String:AnchorField].self, forKey: .fields)
    }
}

public struct AnchorTransactionsInfo: Decodable {
    
    public var enabled: Bool
    public var authenticationRequired:Bool?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled
        case authenticationRequired = "authentication_required"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
    }
}

public struct AnchorTransactionInfo: Decodable {
    
    public var enabled: Bool
    public var authenticationRequired:Bool?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled
        case authenticationRequired = "authentication_required"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
    }
}

public struct AnchorFeeInfo: Decodable {
    
    public var enabled: Bool
    public var authenticationRequired:Bool?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled
        case authenticationRequired = "authentication_required"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired)
    }
}

public struct AnchorFeatureFlags: Decodable {
    
    /// Whether or not the anchor supports creating accounts for users requesting deposits. Defaults to true.
    public var accountCreation: Bool = true
    
    /// Whether or not the anchor supports sending deposit funds as claimable balances. This is relevant for users of Stellar accounts without a trustline to the requested asset. Defaults to false.
    public var claimableBalances: Bool = false
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case accountCreation = "account_creation"
        case claimableBalances = "claimable_balances"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let enabled = try values.decodeIfPresent(Bool.self, forKey: .accountCreation) {
            accountCreation = enabled
        }
        if let enabled = try values.decodeIfPresent(Bool.self, forKey: .claimableBalances) {
            claimableBalances = enabled
        }
    }
}
