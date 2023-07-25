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
    public var parameters:[ParameterResponse]?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case function
        case parameters
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        function = try values.decode(String.self, forKey: .function)
        parameters = try values.decodeIfPresent([ParameterResponse].self, forKey: .parameters)
        try super.init(from: decoder)
    }
}

public class ParameterResponse: NSObject, Decodable {
    
    public var type:String
    public var value:String?
    public var from:String?
    public var salt:String?
    public var asset:String?
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case value
        case from
        case salt
        case asset
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try values.decode(String.self, forKey: .type)
        value = try values.decodeIfPresent(String.self, forKey: .value)
        from = try values.decodeIfPresent(String.self, forKey: .value)
        salt = try values.decodeIfPresent(String.self, forKey: .value)
        asset = try values.decodeIfPresent(String.self, forKey: .value)
        
    }
}
