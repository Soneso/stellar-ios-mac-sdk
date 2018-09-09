//
//  CustomerInformationStatus.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct CustomerInformationStatus: Decodable {

    /// Always set to customer_info_status
    public var type:String
    
    /// Status of customer information processing. One of: pending, denied
    public var status:String
    
    /// (optional) A URL the user can visit if they want more information about their account / status.
    public var moreInfoUrl:String?
    
    /// (optional) Estimated number of seconds until the deposit status will update.
    public var eta:Int?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case status = "status"
        case moreInfoUrl = "more_info_url"
        case eta = "eta"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        status = try values.decode(String.self, forKey: .status)
        moreInfoUrl = try values.decodeIfPresent(String.self, forKey: .moreInfoUrl)
        eta = try values.decodeIfPresent(Int.self, forKey: .eta)
    }
    
}
