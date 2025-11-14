//
//  EndSponsoringFutureReservesOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents an end sponsoring future reserves operation response.
/// This operation terminates the current sponsorship relationship initiated by a begin sponsoring future reserves operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class EndSponsoringFutureReservesOperationResponse: OperationResponse {

    /// Account ID of the sponsor from the begin sponsoring operation.
    public var beginSponsor:String

    /// Multiplexed account address of the sponsor (if used).
    public var beginSponsorMuxed:String?

    /// ID of the multiplexed sponsor account (if used).
    public var beginSponsorMuxedId:String?
    
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
        beginSponsorMuxedId = try values.decodeIfPresent(String.self, forKey: .beginSponsorMuxedId)
        try super.init(from: decoder)
    }
}
