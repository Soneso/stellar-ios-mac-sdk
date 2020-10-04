//
//  BeginSponsoringFutureReservesOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct BeginSponsoringFutureReservesOpXDR: XDRCodable {
    public let sponsoredId: PublicKey
    
    public init(sponsoredId: PublicKey) {
        self.sponsoredId = sponsoredId
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sponsoredId = try container.decode(PublicKey.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sponsoredId)
    }
}
