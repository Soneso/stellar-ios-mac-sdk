//
//  SimulateTransactionResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SimulateTransactionResult: NSObject, Decodable {
    
    public var auth:[String]?
    public var footprint:Footprint
    public var xdr:String
    
    private enum CodingKeys: String, CodingKey {
        case auth
        case footprint
        case xdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        auth = try values.decodeIfPresent([String].self, forKey: .auth)
        let footBase64 = try values.decodeIfPresent(String.self, forKey: .footprint)
        if (footBase64 != nil && footBase64!.trim() != "") {
            footprint = try Footprint(fromBase64: footBase64!)
        } else {
            footprint = Footprint.empty()
        }
        xdr = try values.decode(String.self, forKey: .xdr)
    }
    
    public var value:SCValXDR? {
        try? SCValXDR.fromXdr(base64: xdr)
    }
}
