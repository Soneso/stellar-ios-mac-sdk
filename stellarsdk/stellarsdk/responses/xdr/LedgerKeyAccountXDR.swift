//
//  LedgerKeyAccountXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerKeyAccountXDR: XDRCodable, Sendable {
    public let accountID: PublicKey

    public init(accountID: PublicKey) {
        self.accountID = accountID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
    }
}
