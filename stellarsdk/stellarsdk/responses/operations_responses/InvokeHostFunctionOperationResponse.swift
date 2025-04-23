//
//  InvokeHostFunctionOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class InvokeHostFunctionOperationResponse: OperationResponse {
    
    public var function:String
    public var address:String
    public var salt:String
    public var parameters:[ParameterResponse]?
    public var assetBalanceChanges:[AssetBalanceChange]?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case function
        case address
        case salt
        case parameters
        case assetBalanceChanges = "asset_balance_changes"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        function = try values.decode(String.self, forKey: .function)
        address = try values.decode(String.self, forKey: .address)
        salt = try values.decode(String.self, forKey: .salt)
        parameters = try values.decodeIfPresent([ParameterResponse].self, forKey: .parameters)
        assetBalanceChanges = try values.decodeIfPresent([AssetBalanceChange].self, forKey: .assetBalanceChanges)
        try super.init(from: decoder)
    }
}

public class ParameterResponse: NSObject, Decodable {
    
    public var type:String
    public var value:String
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try values.decode(String.self, forKey: .type)
        value = try values.decode(String.self, forKey: .value)
        
    }
}

public class AssetBalanceChange: NSObject, Decodable {
    
    public var assetType:String
    public var assetCode:String?
    public var assetIssuer:String?
    public var type:String
    public var from:String?
    public var to:String
    public var amount:String
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case type
        case from
        case to
        case amount
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        type = try values.decode(String.self, forKey: .type)
        from = try values.decodeIfPresent(String.self, forKey: .from)
        to = try values.decode(String.self, forKey: .to)
        amount = try values.decode(String.self, forKey: .amount)
    }
}
