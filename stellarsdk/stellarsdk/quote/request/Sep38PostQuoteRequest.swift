//
//  Sep38PostQuoteRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public struct Sep38PostQuoteRequest {

    public var context:String
    public var sellAsset:String
    public var buyAsset:String
    public var sellAmount:String?
    public var buyAmount:String?
    public var expireAfter:Date?
    public var sellDeliveryMethod:String?
    public var buyDeliveryMethod:String?
    public var countryCode:String?

    
    public init(context:String, sellAsset:String, buyAsset:String) {
        self.context = context
        self.sellAsset = sellAsset
        self.buyAsset = buyAsset
    }
    
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
