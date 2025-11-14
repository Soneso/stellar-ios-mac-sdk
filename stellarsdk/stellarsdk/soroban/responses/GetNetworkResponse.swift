//
//  GetNetworkResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// General info about the currently configured network.
/// See: [Stellar developer docs](https://developers.stellar.org)
public class GetNetworkResponse: NSObject, Decodable {
    
    ///  (optional) - The URL of this network's "friendbot" faucet
    public var friendbotUrl:String?
    
    ///  Network passphrase configured
    public var passphrase:String
    
    /// Protocol version of the latest ledger
    public var protocolVersion:Int
    
    private enum CodingKeys: String, CodingKey {
        case friendbotUrl
        case passphrase
        case protocolVersion
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        friendbotUrl = try values.decodeIfPresent(String.self, forKey: .friendbotUrl)
        passphrase = try values.decode(String.self, forKey: .passphrase)
        protocolVersion = try values.decode(Int.self, forKey: .protocolVersion)
    }
}
