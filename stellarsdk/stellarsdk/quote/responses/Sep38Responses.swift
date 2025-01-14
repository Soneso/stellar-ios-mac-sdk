//
//  Sep38Responses.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public struct Sep38InfoResponse: Decodable {

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

public struct Sep38PricesResponse: Decodable {

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

public struct Sep38QuoteResponse: Decodable {

    public var id: String
    public var expiresAt: Date
    public var totalPrice: String
    public var price: String
    public var sellAsset: String
    public var sellAmount: String
    public var buyAsset: String
    public var buyAmount: String
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

public struct Sep38PriceResponse: Decodable {

    public var totalPrice: String
    public var price: String
    public var sellAmount: String
    public var buyAmount: String
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

public struct Sep38Fee: Decodable {

    public var total: String
    public var asset: String
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

public struct Sep38FeeDetails: Decodable {

    public var name: String
    public var amount: String
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

public struct Sep38SellDeliveryMethod: Decodable {

    public var name: String
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

public struct Sep38BuyDeliveryMethod: Decodable {

    public var name: String
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

public struct Sep38Asset: Decodable {

    public var asset: String
    public var sellDeliveryMethods: [Sep38SellDeliveryMethod]?
    public var buyDeliveryMethods: [Sep38BuyDeliveryMethod]?
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

public struct Sep38BuyAsset: Decodable {

    public var asset: String
    public var price: String
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
