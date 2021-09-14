//
//  TradePrice.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class TradePrice: Decodable {
    
    /// Numerator.
    public final let n:String
    
    /// Denominator.
    public final let d:String
    
    
    public init(numerator:String, denominator:String) {
        self.n = numerator
        self.d = denominator
    }
    
    private enum CodingKeys: String, CodingKey {
        case n
        case d
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let nInt = try? values.decodeIfPresent(Int32.self, forKey: .n) {
            n = String(nInt)
        } else {
            n = try values.decode(String.self, forKey: .n) 
        }
        if let dInt = try? values.decodeIfPresent(Int32.self, forKey: .d) {
            d = String(dInt)
        } else {
            d = try values.decode(String.self, forKey: .d)
        }
    }
}
