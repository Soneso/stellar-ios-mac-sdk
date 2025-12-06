//
//  BeginSponsoringFutureReservesOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a begin sponsoring future reserves operation response.
/// This operation initiates sponsorship of reserves for another account, allowing the sponsor to pay for the reserve requirements of ledger entries created by the sponsored account.
/// See [Stellar developer docs](https://developers.stellar.org)
public class BeginSponsoringFutureReservesOperationResponse: OperationResponse, @unchecked Sendable {

    /// Account ID being sponsored.
    public let sponsoredId:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sponsoredId = "sponsored_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sponsoredId = try values.decode(String.self, forKey: .sponsoredId)
        try super.init(from: decoder)
    }
}
