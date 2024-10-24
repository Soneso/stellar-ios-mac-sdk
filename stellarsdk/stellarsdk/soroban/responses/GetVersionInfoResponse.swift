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
        case commitHashP21 = "commit_hash"
        case buildTimeStampP21 = "build_time_stamp"
        case captiveCoreVersionP21 = "captive_core_version"
        case protocolVersionP21 = "protocol_version"
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(String.self, forKey: .version)
        
        var commitHashVal = try values.decodeIfPresent(String.self, forKey: .commitHash)
        if (commitHashVal == nil) {
            commitHash = try values.decode(String.self, forKey: .commitHashP21) // protocol version < 22
        } else {
            commitHash = commitHashVal!
        }
        
        var buildTimeStampVal = try values.decodeIfPresent(String.self, forKey: .buildTimeStamp)
        if (buildTimeStampVal == nil) {
            buildTimeStamp = try values.decode(String.self, forKey: .buildTimeStampP21) // protocol version < 22
        } else {
            buildTimeStamp = buildTimeStampVal!
        }
        
        var captiveCoreVersionVal = try values.decodeIfPresent(String.self, forKey: .captiveCoreVersion)
        if (captiveCoreVersionVal == nil) {
            captiveCoreVersion = try values.decode(String.self, forKey: .captiveCoreVersionP21) // protocol version < 22
        } else {
            captiveCoreVersion = captiveCoreVersionVal!
        }
        
        var protocolVersionVal = try values.decodeIfPresent(Int.self, forKey: .protocolVersion)
        if (protocolVersionVal == nil) {
            protocolVersion = try values.decode(Int.self, forKey: .protocolVersionP21) // protocol version < 22
        } else {
            protocolVersion = protocolVersionVal!
        }
    }
}
