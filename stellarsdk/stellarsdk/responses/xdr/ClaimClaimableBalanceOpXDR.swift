//
//  ClaimClaimableBalanceOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct ClaimClaimableBalanceOpXDR: XDRCodable {
    public let balanceID: ClaimableBalanceIDXDR
    
    public init(balanceID: ClaimableBalanceIDXDR) {
        self.balanceID = balanceID
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        balanceID = try container.decode(ClaimableBalanceIDXDR.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(balanceID)
    }
}
