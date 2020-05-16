//
//  OperationXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct OperationXDR: XDRCodable {
    public var sourceAccount: MuxedAccountXDR?
    public let body: OperationBodyXDR
    
    @available(*, deprecated, message: "use init(sourceAccount: MuxedAccountXDR?, body: OperationBodyXDR) instead")
    public init(sourceAccount: PublicKey?, body: OperationBodyXDR) {
        var mux:MuxedAccountXDR? = nil
        if let sa = sourceAccount {
            mux = MuxedAccountXDR.ed25519(sa.bytes)
        }
        self.init(sourceAccount: mux, body: body)
    }
    
    public init(sourceAccount: MuxedAccountXDR?, body: OperationBodyXDR) {
        self.sourceAccount = sourceAccount
        self.body = body
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try decodeArray(type: MuxedAccountXDR.self, dec: decoder).first
        body = try container.decode(OperationBodyXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        if sourceAccount != nil {
            try container.encode([sourceAccount])
        }
        else {
            try container.encode([MuxedAccountXDR]())
        }
        
        try container.encode(body)
    }
}
