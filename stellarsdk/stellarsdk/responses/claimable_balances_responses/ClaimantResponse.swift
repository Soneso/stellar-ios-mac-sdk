//
//  ClaimantResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class ClaimantResponse: NSObject, Decodable {
    
    public var destination:String
    public var predicate:ClaimantPredicateResponse
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case destination
        case predicate
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        destination = try values.decode(String.self, forKey: .destination)
        predicate = try values.decode(ClaimantPredicateResponse.self, forKey: .predicate)
    }
}
