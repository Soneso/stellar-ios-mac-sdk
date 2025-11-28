//
//  CreatePassiveSellOfferOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a create passive sell offer operation response.
/// This operation creates a passive offer to sell an asset on the Stellar DEX that will only execute at or above a specified price. Passive offers will not immediately take existing offers.
/// See [Stellar developer docs](https://developers.stellar.org)
public class CreatePassiveSellOfferOperationResponse: CreatePassiveOfferOperationResponse, @unchecked Sendable {
    /**
     Initializer - creates a new instance by decoding from the given decoder.

     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
