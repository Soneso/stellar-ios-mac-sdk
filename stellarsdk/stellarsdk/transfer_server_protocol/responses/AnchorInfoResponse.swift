//
//  AnchorInfoResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Response returned by the GET /info endpoint describing anchor capabilities.
///
/// This response provides information about which assets the anchor supports for deposits
/// and withdrawals, along with fee structures, transaction limits, and required fields.
/// It is the first endpoint wallets should call to understand what operations are supported.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
public struct AnchorInfoResponse: Decodable {

    /// Information about assets available for deposit, keyed by asset code.
    public var deposit: [String:DepositAsset]?

    /// Information about assets available for deposit with exchange, keyed by asset code.
    public var depositExchange: [String:DepositExchangeAsset]?

    /// Information about assets available for withdrawal, keyed by asset code.
    public var withdraw: [String:WithdrawAsset]?

    /// Information about assets available for withdrawal with exchange, keyed by asset code.
    public var withdrawExchange: [String:WithdrawExchangeAsset]?

    /// Information about the GET /transactions endpoint support.
    public var transactions: AnchorTransactionsInfo?

    /// Information about the GET /transaction endpoint support.
    public var transaction: AnchorTransactionInfo?

    /// Information about the GET /fee endpoint support.
    public var fee: AnchorFeeInfo?

    /// Feature flags indicating additional anchor capabilities.
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

/// Information about an asset available for deposit operations via SEP-6.
///
/// Provides details about deposit capabilities including fee structure, transaction limits,
/// authentication requirements, and any required fields for deposit transactions.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
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

/// Information about an asset available for deposit operations with exchange via SEP-6.
///
/// Similar to DepositAsset but used when deposits support on-chain asset exchange.
/// Allows users to deposit one off-chain asset and receive a different on-chain Stellar asset.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
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

/// Information about an asset available for withdrawal operations via SEP-6.
///
/// Provides details about withdrawal capabilities including fee structure, transaction limits,
/// authentication requirements, and supported withdrawal types with their required fields.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
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

/// Information about an asset available for withdrawal operations with exchange via SEP-6.
///
/// Similar to WithdrawAsset but used when withdrawals support on-chain asset exchange.
/// Allows users to exchange one on-chain Stellar asset and withdraw a different off-chain asset.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
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

/// Describes a field that must be provided by the user for deposit or withdrawal operations.
///
/// Used to specify required or optional fields for deposit and withdrawal requests.
/// Anchors should use SEP-9 financial account fields where possible but can define custom fields.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
public struct AnchorField: Decodable {

    /// Human-readable description explaining what this field is for.
    public var description: String?
    /// Indicates whether this field is optional for the user to provide.
    public var optional: Bool?
    /// List of allowed values for this field, if constrained to specific options.
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

/// Describes a specific withdrawal type supported by the anchor.
///
/// Each withdrawal method (e.g., bank account, crypto address, mobile money) can have different
/// field requirements. This structure specifies which fields are needed for a particular withdrawal type.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
public struct WithdrawType: Decodable {

    /// Additional fields required for this withdrawal type, keyed by field name.
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

/// Information about the anchor's GET /transactions endpoint availability and requirements.
///
/// Indicates whether the endpoint for retrieving multiple transaction records is supported
/// and if authentication is required to access it.
///
/// See [SEP-6 Transaction History](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct AnchorTransactionsInfo: Decodable {

    /// Indicates whether the GET /transactions endpoint is supported by the anchor.
    public var enabled: Bool
    /// Indicates whether authentication is required to access the transactions endpoint.
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

/// Information about the anchor's GET /transaction endpoint availability and requirements.
///
/// Indicates whether the endpoint for retrieving a single transaction record by ID is supported
/// and if authentication is required to access it.
///
/// See [SEP-6 Single Transaction](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#single-historical-transaction)
public struct AnchorTransactionInfo: Decodable {

    /// Indicates whether the GET /transaction endpoint is supported by the anchor.
    public var enabled: Bool
    /// Indicates whether authentication is required to access the transaction endpoint.
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

/// Information about the anchor's GET /fee endpoint availability and requirements.
///
/// Indicates whether the endpoint for querying detailed fee information is supported
/// and if authentication is required to access it.
///
/// See [SEP-6 Fee](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#fee)
public struct AnchorFeeInfo: Decodable {

    /// Indicates whether the GET /fee endpoint is supported by the anchor.
    public var enabled: Bool
    /// Indicates whether authentication is required to access the fee endpoint.
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

/// Feature flags indicating additional capabilities supported by the anchor.
///
/// These flags communicate optional features that the anchor has implemented beyond the basic
/// SEP-6 requirements, such as account creation and claimable balance support.
///
/// See [SEP-6 Info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)
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
