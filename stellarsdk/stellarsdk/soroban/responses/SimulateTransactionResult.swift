//
//  SimulateTransactionResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SimulateTransactionResult: NSObject, Decodable {
    
    public var auth:[String]? // ContractAuthXdr
    public var xdr:String?
    
    private enum CodingKeys: String, CodingKey {
        case auth
        case xdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        auth = try values.decodeIfPresent([String].self, forKey: .auth)
        xdr = try values.decodeIfPresent(String.self, forKey: .xdr)
    }
    
    public var value:SCValXDR? {
        if let xdr = xdr {
            return try? SCValXDR.fromXdr(base64: xdr)
        }
        return nil
    }
}
