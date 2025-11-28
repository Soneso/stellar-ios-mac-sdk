//
//  Sep38PostQuoteRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Request model for creating a firm quote via SEP-38.
///
/// This structure represents a POST request to the `/quote` endpoint, which
/// creates a firm quote that can be executed by the client. Either `sellAmount`
/// or `buyAmount` must be specified, but not both.
///
/// See [SEP-38: Quote Service](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)
public struct Sep38PostQuoteRequest: Sendable {

    /// The context in which the quote is being requested.
    ///
    /// Valid values are "sep6" for SEP-6 transfers or "sep31" for SEP-31 payments.
    public var context:String

    /// The asset the client wants to sell.
    ///
    /// The value must be in SEP-38 Asset Identification Format.
    /// Example: "stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5"
    public var sellAsset:String

    /// The asset the client wants to buy.
    ///
    /// The value must be in SEP-38 Asset Identification Format.
    /// Example: "iso4217:BRL"
    public var buyAsset:String

    /// The amount of sell asset the client wants to exchange.
    ///
    /// Must be provided if `buyAmount` is not provided. Mutually exclusive with `buyAmount`.
    public var sellAmount:String?

    /// The amount of buy asset the client wants to receive.
    ///
    /// Must be provided if `sellAmount` is not provided. Mutually exclusive with `sellAmount`.
    public var buyAmount:String?

    /// The timestamp after which the quote should expire.
    ///
    /// If not provided, the anchor will use its default expiration time.
    public var expireAfter:Date?

    /// The method by which the client will deliver the sell asset to the anchor.
    ///
    /// Must be a valid delivery method for the sell asset as returned by the GET /info endpoint.
    public var sellDeliveryMethod:String?

    /// The method by which the anchor will deliver the buy asset to the client.
    ///
    /// Must be a valid delivery method for the buy asset as returned by the GET /info endpoint.
    public var buyDeliveryMethod:String?

    /// The ISO 3166-1 alpha-3 country code of the client.
    ///
    /// Used to determine available delivery methods and pricing. Must be one of the values
    /// specified in the asset's country_codes array from the GET /info endpoint.
    public var countryCode:String?

    /// Creates a new quote request with required parameters.
    ///
    /// - Parameters:
    ///   - context: The context for the quote ("sep6" or "sep31")
    ///   - sellAsset: The asset to sell in SEP-38 format
    ///   - buyAsset: The asset to buy in SEP-38 format
    public init(context:String, sellAsset:String, buyAsset:String) {
        self.context = context
        self.sellAsset = sellAsset
        self.buyAsset = buyAsset
    }

    /// Converts the request to a JSON dictionary for API submission.
    ///
    /// Transforms the Swift property names to the snake_case format expected by the SEP-38 API.
    /// Optional properties are only included if they have values.
    ///
    /// - Returns: Dictionary representation suitable for HTTP request body
    public func toJson() -> [String : Any] {
        var result = [String : Any]();
        result["context"] = context;
        result["sell_asset"] = sellAsset;
        result["buy_asset"] = buyAsset;
        
        if let value = sellAmount {
            result["sell_amount"] = value;
        }
        if let value = buyAmount {
            result["buy_amount"] = value;
        }
        if let value = expireAfter {
            result["expire_after"] = DateFormatter.iso8601.string(from: value);
        }
        if let value = sellDeliveryMethod {
            result["sell_delivery_method"] = value;
        }
        if let value = buyDeliveryMethod {
            result["buy_delivery_method"] = value;
        }
        if let value = countryCode {
            result["country_code"] = value;
        }
        return result

    }
}
