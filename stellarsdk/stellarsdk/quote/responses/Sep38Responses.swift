//
//  Sep38Responses.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Response from the GET /info endpoint of SEP-38 Quote Service.
///
/// This response provides information about the assets supported by the anchor
/// for quotes, including available delivery methods and country codes for each asset.
///
/// See [SEP-38: GET /info](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-info)
public struct Sep38InfoResponse: Decodable {

    /// Array of assets supported by the anchor for quotes.
    ///
    /// Each asset includes information about supported delivery methods and country codes.
    public var assets: [Sep38Asset]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case assets
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        assets = try values.decode([Sep38Asset].self, forKey: .assets)
    }
}

/// Response from the GET /prices endpoint of SEP-38 Quote Service.
///
/// This response provides indicative prices for buying various assets
/// using a specified sell asset. Prices are not guaranteed and are for
/// informational purposes only.
///
/// See [SEP-38: GET /prices](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-prices)
public struct Sep38PricesResponse: Decodable {

    /// Array of assets that can be purchased with their indicative prices.
    ///
    /// Each entry contains the asset identifier, price, and decimal precision.
    public var buyAssets: [Sep38BuyAsset]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case buyAssets = "buy_assets"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        buyAssets = try values.decode([Sep38BuyAsset].self, forKey: .buyAssets)
    }
}

/// Response from the POST /quote and GET /quote/:id endpoints of SEP-38 Quote Service.
///
/// This response represents a firm quote that can be executed by the client.
/// The quote is guaranteed until the expiration time and includes all exchange details
/// such as amounts, prices, and fees.
///
/// See [SEP-38: POST /quote](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#post-quote)
/// and [GET /quote/:id](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-quoteid)
public struct Sep38QuoteResponse: Decodable {

    /// Unique identifier for this quote.
    ///
    /// Used to reference this quote in subsequent API calls.
    public var id: String

    /// The timestamp when this quote expires.
    ///
    /// After this time, the quote is no longer valid and cannot be used.
    public var expiresAt: Date

    /// The total price including fees.
    ///
    /// Represented as a decimal string showing the total exchange rate.
    public var totalPrice: String

    /// The base exchange price without fees.
    ///
    /// Represented as a decimal string showing units of buy asset per unit of sell asset.
    public var price: String

    /// The asset being sold.
    ///
    /// In SEP-38 Asset Identification Format.
    public var sellAsset: String

    /// The amount of sell asset to be exchanged.
    ///
    /// Represented as a decimal string.
    public var sellAmount: String

    /// The asset being purchased.
    ///
    /// In SEP-38 Asset Identification Format.
    public var buyAsset: String

    /// The amount of buy asset to be received.
    ///
    /// Represented as a decimal string.
    public var buyAmount: String

    /// Fee structure for this quote.
    ///
    /// Contains the total fee amount, fee asset, and optional breakdown of fee components.
    public var fee: Sep38Fee
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
        case expiresAt = "expires_at"
        case totalPrice = "total_price"
        case price
        case sellAsset = "sell_asset"
        case sellAmount = "sell_amount"
        case buyAsset = "buy_asset"
        case buyAmount = "buy_amount"
        case fee
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        let expiresAtStr = try values.decode(String.self, forKey: .expiresAt)
        if let expiresAtDate = ISO8601DateFormatter.full.date(from: expiresAtStr) {
            expiresAt = expiresAtDate
        } else {
            expiresAt = try values.decode(Date.self, forKey: .expiresAt)
        }
        totalPrice = try values.decode(String.self, forKey: .totalPrice)
        price = try values.decode(String.self, forKey: .price)
        sellAsset = try values.decode(String.self, forKey: .sellAsset)
        sellAmount = try values.decode(String.self, forKey: .sellAmount)
        buyAsset = try values.decode(String.self, forKey: .buyAsset)
        buyAmount = try values.decode(String.self, forKey: .buyAmount)
        fee = try values.decode(Sep38Fee.self, forKey: .fee)
    }
}

/// Response from the GET /price endpoint of SEP-38 Quote Service.
///
/// This response provides an indicative price for an asset exchange without
/// creating a firm quote. The price is not guaranteed and is for informational
/// purposes only. To get a guaranteed quote, use POST /quote instead.
///
/// See [SEP-38: GET /price](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-price)
public struct Sep38PriceResponse: Decodable {

    /// The total price including fees.
    ///
    /// Represented as a decimal string showing the total exchange rate.
    public var totalPrice: String

    /// The base exchange price without fees.
    ///
    /// Represented as a decimal string showing units of buy asset per unit of sell asset.
    public var price: String

    /// The amount of sell asset that would be exchanged.
    ///
    /// Represented as a decimal string.
    public var sellAmount: String

    /// The amount of buy asset that would be received.
    ///
    /// Represented as a decimal string.
    public var buyAmount: String

    /// Fee structure for this indicative price.
    ///
    /// Contains the estimated fee amount, fee asset, and optional breakdown of fee components.
    public var fee: Sep38Fee
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case totalPrice = "total_price"
        case price
        case sellAmount = "sell_amount"
        case buyAmount = "buy_amount"
        case fee
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        totalPrice = try values.decode(String.self, forKey: .totalPrice)
        price = try values.decode(String.self, forKey: .price)
        sellAmount = try values.decode(String.self, forKey: .sellAmount)
        buyAmount = try values.decode(String.self, forKey: .buyAmount)
        fee = try values.decode(Sep38Fee.self, forKey: .fee)
    }
}

/// Fee information for a SEP-38 quote or price.
///
/// This structure contains the total fee amount and optionally a detailed
/// breakdown of individual fee components. The fee is always denominated
/// in a specific asset.
public struct Sep38Fee: Decodable {

    /// The total fee amount.
    ///
    /// Represented as a decimal string in the fee asset's units.
    public var total: String

    /// The asset in which the fee is denominated.
    ///
    /// In SEP-38 Asset Identification Format.
    public var asset: String

    /// Optional breakdown of the fee into individual components.
    ///
    /// Each component describes a specific fee charge with its name, amount, and optional description.
    public var details: [Sep38FeeDetails]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case total
        case asset
        case details
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        total = try values.decode(String.self, forKey: .total)
        asset = try values.decode(String.self, forKey: .asset)
        details = try values.decodeIfPresent([Sep38FeeDetails].self, forKey: .details)
    }
}

/// Detailed information about a specific fee component.
///
/// This structure describes an individual fee charge that contributes to
/// the total fee amount in a quote or price.
public struct Sep38FeeDetails: Decodable {

    /// The name of this fee component.
    ///
    /// Example: "Service fee", "Network fee", "Processing fee"
    public var name: String

    /// The amount of this fee component.
    ///
    /// Represented as a decimal string in the fee asset's units.
    public var amount: String

    /// Optional human-readable description of this fee component.
    ///
    /// Provides additional context about what this fee covers.
    public var description: String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
        case amount
        case description
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        amount = try values.decode(String.self, forKey: .amount)
        description = try values.decodeIfPresent(String.self, forKey: .description)
    }
}

/// Delivery method for selling an asset to the anchor.
///
/// This structure describes a method by which the client can deliver
/// the sell asset to the anchor. Available methods depend on the asset
/// and are returned by the GET /info endpoint.
public struct Sep38SellDeliveryMethod: Decodable {

    /// The identifier for this delivery method.
    ///
    /// Example: "bank_transfer", "cash", "wire"
    public var name: String

    /// Human-readable description of this delivery method.
    ///
    /// Explains how the client should deliver the asset using this method.
    public var description: String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
        case description
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        description = try values.decode(String.self, forKey: .description)
    }
}

/// Delivery method for receiving an asset from the anchor.
///
/// This structure describes a method by which the anchor can deliver
/// the buy asset to the client. Available methods depend on the asset
/// and are returned by the GET /info endpoint.
public struct Sep38BuyDeliveryMethod: Decodable {

    /// The identifier for this delivery method.
    ///
    /// Example: "bank_transfer", "cash", "wire"
    public var name: String

    /// Human-readable description of this delivery method.
    ///
    /// Explains how the anchor will deliver the asset using this method.
    public var description: String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
        case description
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        description = try values.decode(String.self, forKey: .description)
    }
}

/// Asset information from the SEP-38 GET /info endpoint.
///
/// This structure describes an asset supported by the anchor for quotes,
/// including the available delivery methods and supported country codes
/// for the asset.
public struct Sep38Asset: Decodable {

    /// The asset identifier in SEP-38 Asset Identification Format.
    ///
    /// Example: "stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5"
    /// or "iso4217:BRL"
    public var asset: String

    /// Available methods for delivering this asset to the anchor when selling.
    ///
    /// Optional field that is present only if the asset can be sold to the anchor.
    public var sellDeliveryMethods: [Sep38SellDeliveryMethod]?

    /// Available methods for receiving this asset from the anchor when buying.
    ///
    /// Optional field that is present only if the asset can be bought from the anchor.
    public var buyDeliveryMethods: [Sep38BuyDeliveryMethod]?

    /// ISO 3166-1 alpha-3 country codes where this asset is available.
    ///
    /// Optional field indicating geographic restrictions for this asset.
    public var countryCodes: [String]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case asset
        case sellDeliveryMethods = "sell_delivery_methods"
        case buyDeliveryMethods = "buy_delivery_methods"
        case countryCodes = "country_codes"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        asset = try values.decode(String.self, forKey: .asset)
        sellDeliveryMethods = try values.decodeIfPresent([Sep38SellDeliveryMethod].self, forKey: .sellDeliveryMethods)
        buyDeliveryMethods = try values.decodeIfPresent([Sep38BuyDeliveryMethod].self, forKey: .buyDeliveryMethods)
        countryCodes = try values.decodeIfPresent([String].self, forKey: .countryCodes)
    }
}

/// Asset information with price from the SEP-38 GET /prices endpoint.
///
/// This structure represents an asset that can be purchased along with
/// its indicative price and decimal precision. The price is not guaranteed
/// and is for informational purposes only.
public struct Sep38BuyAsset: Decodable {

    /// The asset identifier in SEP-38 Asset Identification Format.
    ///
    /// Example: "stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5"
    public var asset: String

    /// The indicative price for this asset.
    ///
    /// Represented as a decimal string showing units of this asset per unit of the sell asset.
    public var price: String

    /// The number of decimal places for this asset.
    ///
    /// Used for proper formatting and precision when displaying amounts.
    public var decimals: Int
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case asset
        case price
        case decimals
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        asset = try values.decode(String.self, forKey: .asset)
        price = try values.decode(String.self, forKey: .price)
        decimals = try values.decode(Int.self, forKey: .decimals)
    }
}
