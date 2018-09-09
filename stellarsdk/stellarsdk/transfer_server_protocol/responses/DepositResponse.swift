//
//  DepositResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DepositResponse: Decodable {

    /// Instructions for how to deposit the asset. In the case of cryptocurrency it is just an address to which the deposit should be sent.
    public var how:String
    
    /// (optional) Estimate of how long the deposit will take to credit in seconds.
    public var eta:Int?
    
    /// (optional) Minimum amount of an asset that a user can deposit.
    public var minAmount:Double?
    
    /// (optional) Maximum amount of asset that a user can deposit.
    public var maxAmount:Double?
    
    /// (optional) Fixed fee (if any). In units of the deposited asset.
    public var feeFixed:Double?
    
    /// (optional) Percentage fee (if any). In units of percentage points.
    public var feePercent:Double?
    
    /// (optional) Any additional data needed as an input for this deposit, example: Bank Name
    public var extraInfo:[String:Any]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case how = "how"
        case eta = "eta"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case extraInfo = "extra_info"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        how = try values.decode(String.self, forKey: .how)
        eta = try values.decodeIfPresent(Int.self, forKey: .eta)
        minAmount = try values.decodeIfPresent(Double.self, forKey: .minAmount)
        maxAmount = try values.decodeIfPresent(Double.self, forKey: .maxAmount)
        feeFixed = try values.decodeIfPresent(Double.self, forKey: .feeFixed)
        feePercent = try values.decodeIfPresent(Double.self, forKey: .feePercent)
        extraInfo = try values.decodeIfPresent([String:Any].self, forKey: .extraInfo)
    }
    
}
