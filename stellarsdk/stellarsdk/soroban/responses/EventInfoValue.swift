//
//  EventInfoValue.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Part of the getEvents request
/// See: https://soroban.stellar.org/api/methods/getEvents
public class EventInfoValue: NSObject, Decodable {
    
    /// The emitted body value of the event (serialized in a base64 string - XdrSCVal).
    public var xdr:String
    
    private enum CodingKeys: String, CodingKey {
        case xdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        xdr = try values.decode(String.self, forKey: .xdr)
    }
    
    public var value:SCValXDR? {
        try? SCValXDR.fromXdr(base64: xdr)
    }
}
