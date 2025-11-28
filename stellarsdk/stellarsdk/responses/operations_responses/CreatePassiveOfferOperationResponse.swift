//
//  CreatePassiveOfferOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a create passive operation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class CreatePassiveOfferOperationResponse: OperationResponse, @unchecked Sendable {
        
    /// Amount of the selling asset offered.
    public let amount:String

    /// Price of 1 unit of selling asset in terms of buying asset (decimal).
    public let price:String

    /// Type of asset to buy (native / alphanum4 / alphanum12).
    public let buyingAssetType:String

    /// Code of the asset to buy.
    public let buyingAssetCode:String?

    /// Issuer of the asset to buy.
    public let buyingAssetIssuer:String?

    /// Type of asset to sell (native / alphanum4 / alphanum12).
    public let sellingAssetType:String

    /// Code of the asset to sell.
    public let sellingAssetCode:String?

    /// Issuer of the asset to sell.
    public let sellingAssetIssuer:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case price
        case buyingAssetType = "buying_asset_type"
        case buyingAssetCode = "buying_asset_code"
        case buyingAssetIssuer = "buying_asset_issuer"
        case sellingAssetType = "selling_asset_type"
        case sellingAssetCode = "selling_asset_code"
        case sellingAssetIssuer = "selling_asset_issuer"
        
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        price = try values.decode(String.self, forKey: .price)
        buyingAssetType = try values.decode(String.self, forKey: .buyingAssetType)
        buyingAssetCode = try values.decodeIfPresent(String.self, forKey: .buyingAssetCode)
        buyingAssetIssuer = try values.decodeIfPresent(String.self, forKey: .buyingAssetIssuer)
        sellingAssetType = try values.decode(String.self, forKey: .sellingAssetType)
        sellingAssetCode = try values.decodeIfPresent(String.self, forKey: .sellingAssetCode)
        sellingAssetIssuer = try values.decodeIfPresent(String.self, forKey: .sellingAssetIssuer)
        
        try super.init(from: decoder)
    }
}
