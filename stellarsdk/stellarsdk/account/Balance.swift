//
//  Balance.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class Balance: NSObject, Codable {

    var balance:Decimal
    var limit:Decimal?
    var assetType:String
    var assetCode:String?
    var assetIssuer:String?
    
    enum CodingKeys: String, CodingKey {
        case balance
        case limit
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let balanceString = try values.decode(String.self, forKey: .balance) as String
        balance = Decimal(string: balanceString)!
        
        if let limit = try values.decodeIfPresent(String.self, forKey: .limit) {
            self.limit = Decimal(string: limit)!
        }
    
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(String(describing:balance), forKey: .balance)
        try container.encode(String(describing:limit), forKey: .limit)
        try container.encode(assetType, forKey: .assetType)
        try container.encode(assetCode, forKey: .assetCode)
        try container.encode(assetIssuer, forKey: .assetIssuer)
    }
    
}
