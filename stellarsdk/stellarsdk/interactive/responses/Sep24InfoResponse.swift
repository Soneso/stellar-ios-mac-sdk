import Foundation

public struct Sep24InfoResponse: Decodable {

    public var depositAssets: [String:Sep24DepositAsset]?
    public var withdrawAssets: [String:Sep24WithdrawAsset]?
    public var feeEndpointInfo: Sep24FeeEndpointInfo?
    public var featureFlags: Sep24FeatureFlags?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case deposit = "deposit"
        case withdraw = "withdraw"
        case fee = "fee"
        case features = "features"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        depositAssets = try values.decodeIfPresent([String:Sep24DepositAsset].self, forKey: .deposit)
        withdrawAssets = try values.decodeIfPresent([String:Sep24WithdrawAsset].self, forKey: .withdraw)
        feeEndpointInfo = try values.decodeIfPresent(Sep24FeeEndpointInfo.self, forKey: .fee)
        featureFlags = try values.decodeIfPresent(Sep24FeatureFlags.self, forKey: .features)
    }
}

public struct Sep24DepositAsset: Decodable {
    
    /// true if deposit for this asset is supported
    public var enabled: Bool
    
    /// Optional minimum amount. No limit if not specified.
    public var minAmount:Double?
    
    /// Optional maximum amount. No limit if not specified.
    public var maxAmount:Double?
    
    /// Optional fixed (base) fee for deposit. In units of the deposited asset. This is in addition to any fee_percent. Omitted if there is no fee or the fee schedule is complex.
    public var feeFixed: Double?
    
    /// Optional percentage fee for deposit. In percentage points. This is in addition to any fee_fixed. Omitted if there is no fee or the fee schedule is complex.
    public var feePercent: Double?

    /// Optional minimum fee in units of the deposited asset.
    public var feeMinimum: Double?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case feeMinimum = "fee_minimum"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
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


public struct Sep24WithdrawAsset: Decodable {
    
    /// true if withdrawal for this asset is supported
    public var enabled: Bool
    
    /// Optional minimum amount. No limit if not specified.
    public var minAmount:Double?
    
    /// Optional maximum amount. No limit if not specified.
    public var maxAmount:Double?
    
    /// Optional fixed (base) fee for withdraw. In units of the withdrawn asset. This is in addition to any fee_percent.
    public var feeFixed: Double?
    
    /// Optional percentage fee for withdraw in percentage points. This is in addition to any fee_fixed.
    public var feePercent: Double?

    /// Optional minimum fee in units of the withdrawn asset.
    public var feeMinimum: Double?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case feeMinimum = "fee_minimum"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
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

public struct Sep24FeeEndpointInfo: Decodable {
    
    /// true if the endpoint is available.
    public var enabled: Bool
    
    /// true if client must be authenticated before accessing the fee endpoint.
    public var authenticationRequired: Bool = false
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case enabled = "enabled"
        case authenticationRequired = "authentication_required"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        if let authRequired = try values.decodeIfPresent(Bool.self, forKey: .authenticationRequired) {
            authenticationRequired = authRequired
        }
    }
}

public struct Sep24FeatureFlags: Decodable {
    
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
