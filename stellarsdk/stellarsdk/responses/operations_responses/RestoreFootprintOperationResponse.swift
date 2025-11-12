//
//  RestoreFootprintOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents a restore footprint operation response.
/// This Soroban operation restores archived ledger entries specified in the transaction's footprint, making them accessible again.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#restore-footprint "Restore Footprint Operation")
public class RestoreFootprintOperationResponse: OperationResponse {
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
