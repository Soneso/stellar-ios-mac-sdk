//
//  EndSponsoringFutureReservesOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class EndSponsoringFutureReservesOperationResponse: OperationResponse {
    
    public var beginSponsor:String
    public var beginSponsorMuxed:String?
    public var beginSponsorMuxedId:Int?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case beginSponsor = "begin_sponsor"
        case beginSponsorMuxed = "begin_sponsor_muxed"
        case beginSponsorMuxedId = "begin_sponsor_muxed_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        beginSponsor = try values.decode(String.self, forKey: .beginSponsor)
        beginSponsorMuxed = try values.decodeIfPresent(String.self, forKey: .beginSponsorMuxed)
        beginSponsorMuxedId = try values.decodeIfPresent(Int.self, forKey: .beginSponsorMuxedId)
        try super.init(from: decoder)
    }
}
