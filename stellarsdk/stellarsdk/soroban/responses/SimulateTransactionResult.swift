//
//  SimulateTransactionResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SimulateTransactionResult: NSObject, Decodable {
    
    /// Array of serialized base64 strings - Per-address authorizations recorded when simulating this Host Function call.
    public var auth:[String] // SorobanAuthorizationEntryXDR, see SimulateTransactionResponse.sorobanAuth
    
    /// Serialized base64 string - return value of the Host Function call.
    public var xdr:String
    
    private enum CodingKeys: String, CodingKey {
        case auth
        case xdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        auth = try values.decode([String].self, forKey: .auth)
        xdr = try values.decode(String.self, forKey: .xdr)
    }
    
    /// Converst the return value of the Host Function call to a SCValXDR object
    public var value:SCValXDR? {
        return try? SCValXDR.fromXdr(base64: xdr)
    }
}
