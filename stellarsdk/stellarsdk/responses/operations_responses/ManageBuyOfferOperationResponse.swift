//
//  ManageBuyOfferOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a manage buy offer operation response.
/// This operation creates, updates, or deletes a buy offer on the Stellar DEX, specifying the amount to buy rather than the amount to sell.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#manage-buy-offer "Manage Buy Offer Operation")
public class ManageBuyOfferOperationResponse: ManageOfferOperationResponse {
    /**
     Initializer - creates a new instance by decoding from the given decoder.

     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
