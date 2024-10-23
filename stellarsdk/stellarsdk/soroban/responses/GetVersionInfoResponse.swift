//
//  GetVersionInfoResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public class GetVersionInfoResponse: NSObject, Decodable {
    
    /// The version of the RPC server.s
    public var version:String
    
    /// The commit hash of the RPC server.
    public var commitHash:String
    
    /// The build timestamp of the RPC server.
    public var buildTimeStamp:String
    
    /// The version of the Captive Core.
    public var captiveCoreVersion:String
    
    /// The protocol version.
    public var protocolVersion:Int
    
    private enum CodingKeys: String, CodingKey {
        case version
        case commitHash = "commitHash"
        case buildTimeStamp = "buildTimestamp"
        case captiveCoreVersion = "captiveCoreVersion"
        case protocolVersion = "protocolVersion"
        
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(String.self, forKey: .version)
        commitHash = try values.decode(String.self, forKey: .commitHash)
        buildTimeStamp = try values.decode(String.self, forKey: .buildTimeStamp)
        captiveCoreVersion = try values.decode(String.self, forKey: .captiveCoreVersion)
        protocolVersion = try values.decode(Int.self, forKey: .protocolVersion)
    }
}
