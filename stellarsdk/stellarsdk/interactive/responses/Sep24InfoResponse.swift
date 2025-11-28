import Foundation

/// Response containing information about an anchor's supported assets and features.
///
/// This response is returned from the /info endpoint and provides clients with details
/// about which assets are supported for deposits and withdrawals, along with fee information
/// and supported features.
///
/// See also:
/// - [InteractiveService.getInfo] for the method that returns this response
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24InfoResponse: Decodable , Sendable {

    /// Dictionary of assets supported for deposit, keyed by asset code.
    public let depositAssets: [String:Sep24DepositAsset]?

    /// Dictionary of assets supported for withdrawal, keyed by asset code.
    public let withdrawAssets: [String:Sep24WithdrawAsset]?

    /// Information about the fee endpoint if available.
    public let feeEndpointInfo: Sep24FeeEndpointInfo?

    /// Feature flags indicating which optional features are supported.
    public let featureFlags: Sep24FeatureFlags?

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case deposit = "deposit"
        case withdraw = "withdraw"
        case fee = "fee"
        case features = "features"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        depositAssets = try values.decodeIfPresent([String:Sep24DepositAsset].self, forKey: .deposit)
        withdrawAssets = try values.decodeIfPresent([String:Sep24WithdrawAsset].self, forKey: .withdraw)
        feeEndpointInfo = try values.decodeIfPresent(Sep24FeeEndpointInfo.self, forKey: .fee)
        featureFlags = try values.decodeIfPresent(Sep24FeatureFlags.self, forKey: .features)
    }
}

/// Information about a deposit asset supported by an anchor.
///
/// Contains details about deposit capabilities, limits, and fees for a specific asset.
public struct Sep24DepositAsset: Decodable , Sendable {

    /// True if deposit for this asset is supported.
    public let enabled: Bool

    /// Minimum deposit amount. No limit if not specified.
    public let minAmount:Double?

    /// Maximum deposit amount. No limit if not specified.
    public let maxAmount:Double?

    /// Fixed (base) fee for deposit. In units of the deposited asset. This is in addition to any fee_percent. Omitted if there is no fee or the fee schedule is complex.
    public let feeFixed: Double?

    /// Percentage fee for deposit. In percentage points. This is in addition to any fee_fixed. Omitted if there is no fee or the fee schedule is complex.
    public let feePercent: Double?

    /// Minimum fee in units of the deposited asset.
    public let feeMinimum: Double?

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case feeMinimum = "fee_minimum"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        minAmount = try values.decodeIfPresent(Double.self, forKey: .minAmount)
        maxAmount = try values.decodeIfPresent(Double.self, forKey: .maxAmount)
        feeFixed = try values.decodeIfPresent(Double.self, forKey: .feeFixed)
        feePercent = try values.decodeIfPresent(Double.self, forKey: .feePercent)
        feeMinimum = try values.decodeIfPresent(Double.self, forKey: .feeMinimum)
    }
}

/// Information about a withdrawal asset supported by an anchor.
///
/// Contains details about withdrawal capabilities, limits, and fees for a specific asset.
public struct Sep24WithdrawAsset: Decodable , Sendable {

    /// True if withdrawal for this asset is supported.
    public let enabled: Bool

    /// Minimum withdrawal amount. No limit if not specified.
    public let minAmount:Double?

    /// Maximum withdrawal amount. No limit if not specified.
    public let maxAmount:Double?

    /// Fixed (base) fee for withdraw. In units of the withdrawn asset. This is in addition to any fee_percent.
    public let feeFixed: Double?

    /// Percentage fee for withdraw in percentage points. This is in addition to any fee_fixed.
    public let feePercent: Double?

    /// Minimum fee in units of the withdrawn asset.
    public let feeMinimum: Double?

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case feeMinimum = "fee_minimum"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        minAmount = try values.decodeIfPresent(Double.self, forKey: .minAmount)
        maxAmount = try values.decodeIfPresent(Double.self, forKey: .maxAmount)
        feeFixed = try values.decodeIfPresent(Double.self, forKey: .feeFixed)
        feePercent = try values.decodeIfPresent(Double.self, forKey: .feePercent)
        feeMinimum = try values.decodeIfPresent(Double.self, forKey: .feeMinimum)
    }
}

/// Information about the availability and requirements of the fee endpoint.
///
/// Indicates whether the fee endpoint is available and if authentication is required.
public struct Sep24FeeEndpointInfo: Decodable , Sendable {

    /// True if the endpoint is available.
    public let enabled: Bool

    /// True if client must be authenticated before accessing the fee endpoint.
    public let authenticationRequired: Bool

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case authenticationRequired = "authentication_required"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        authenticationRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired) ?? false
    }
}

/// Feature flags indicating which optional SEP-0024 features are supported by the anchor.
///
/// These flags inform clients about advanced capabilities like account creation and claimable balances.
public struct Sep24FeatureFlags: Decodable , Sendable {

    /// Whether or not the anchor supports creating accounts for users requesting deposits. Defaults to true.
    public let accountCreation: Bool

    /// Whether or not the anchor supports sending deposit funds as claimable balances. This is relevant for users of Stellar accounts without a trustline to the requested asset. Defaults to false.
    public let claimableBalances: Bool

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case accountCreation = "account_creation"
        case claimableBalances = "claimable_balances"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accountCreation = try values.decodeIfPresent(Bool.self, forKey: .accountCreation) ?? true
        claimableBalances = try values.decodeIfPresent(Bool.self, forKey: .claimableBalances) ?? false
    }
}
