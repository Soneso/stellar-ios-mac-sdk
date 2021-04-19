//
//  ClawbackClaimableBalanceOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public struct ClawbackClaimableBalanceOpXDR: XDRCodable {
    public let claimableBalanceID: ClaimableBalanceIDXDR
    
    public init(claimableBalanceID: ClaimableBalanceIDXDR) {
        self.claimableBalanceID = claimableBalanceID
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        claimableBalanceID = try container.decode(ClaimableBalanceIDXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(claimableBalanceID)
    }
}
