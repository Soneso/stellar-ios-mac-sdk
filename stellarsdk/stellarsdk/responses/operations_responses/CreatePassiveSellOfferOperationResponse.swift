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
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#create-passive-sell-offer "Create Passive Sell Offer Operation")
public class CreatePassiveSellOfferOperationResponse: CreatePassiveOfferOperationResponse {
    /**
     Initializer - creates a new instance by decoding from the given decoder.

     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
