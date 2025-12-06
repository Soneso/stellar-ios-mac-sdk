//
//  ManageSellOfferOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a manage sell offer operation response.
/// This operation creates, updates, or deletes a sell offer on the Stellar DEX, specifying the amount to sell rather than the amount to buy.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ManageSellOfferOperationResponse: ManageOfferOperationResponse, @unchecked Sendable {
    /**
     Initializer - creates a new instance by decoding from the given decoder.

     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
