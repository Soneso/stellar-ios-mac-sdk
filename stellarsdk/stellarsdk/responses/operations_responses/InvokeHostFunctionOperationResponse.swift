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
    public var footprint:String

    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case function
        case parameters
        case footprint
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        function = try values.decode(String.self, forKey: .function)
        parameters = try values.decodeIfPresent([ParameterResponse].self, forKey: .parameters)
        footprint = try values.decode(String.self, forKey: .footprint)
        
        try super.init(from: decoder)
    }
}


public class ParameterResponse: NSObject, Decodable {
    
    public var value:String
    public var type:String
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case value
        case type
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decode(String.self, forKey: .value)
        type = try values.decode(String.self, forKey: .value)
        
    }
}
