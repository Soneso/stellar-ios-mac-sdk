//
//  Asset.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Asset: NSObject, Codable {
    
    public var links:Links
    public var assetType:String // The type of this asset: “credit_alphanum4”, or “credit_alphanum12”.
    public var assetCode:String // The code of this asset.
    public var assetIssuer:String // The issuer of this asset.
    public var amount:Decimal // The number of units of credit issued.
    public var numberOfAccounts:Int //The number of accounts that: 1) trust this asset and 2) where if the asset has the auth_required flag then the account is authorized to hold the asset.
    public var flags:Flags // The flags on this asset of types: auth_required and auth_revocable.
    public var pagingToken:String // A paging token suitable for use as the cursor parameter to transaction collection resources.
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case amount
        case numberOfAccounts = "num_accounts"
        case flags
        case pagingToken = "paging_token"
        
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(Links.self, forKey: .links)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decode(String.self, forKey: .assetCode)
        assetIssuer = try values.decode(String.self, forKey: .assetIssuer)
        let amountString = try values.decode(String.self, forKey: .amount) as String
        amount = Decimal(string: amountString)!
        numberOfAccounts = try values.decode(Int.self, forKey: .numberOfAccounts)
        flags = try values.decode(Flags.self, forKey: .flags)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
       
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(assetType, forKey: .assetType)
        try container.encode(assetCode, forKey: .assetCode)
        try container.encode(assetIssuer, forKey: .assetIssuer)
        try container.encode(amount, forKey: .amount)
        try container.encode(numberOfAccounts, forKey: .numberOfAccounts)
        try container.encode(flags, forKey: .flags)
        try container.encode(pagingToken, forKey: .pagingToken)
    }
}
