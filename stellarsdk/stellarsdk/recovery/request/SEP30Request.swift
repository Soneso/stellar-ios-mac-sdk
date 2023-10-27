//
//  SEP30Request.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct Sep30Request {

    public var identities:[Sep30RequestIdentity]

    public init(identities:[Sep30RequestIdentity]) {
        self.identities = identities
    }
    
    public func toJson() -> [String : Any] {
        var identitiesJson = [[String : Any]]();
        for identity in identities {
            identitiesJson.append(identity.toJson())
        }
        return ["identities": identitiesJson]
    }
}

public struct Sep30RequestIdentity {

    public var role:String
    public var authMethods:[Sep30AuthMethod]

    
    public init(role:String, authMethods:[Sep30AuthMethod]) {
        self.role = role
        self.authMethods = authMethods
    }
    
    public func toJson() -> [String : Any] {
        var authJson = [[String : Any]]();
        for auth in authMethods {
            authJson.append(auth.toJson())
        }
        return ["role": role, "auth_methods": authJson]

    }
}

public struct Sep30AuthMethod {

    public var type:String
    public var value:String
    
    public init(type:String, value:String) {
        self.type = type
        self.value = value
    }
    
    public func toJson() -> [String : Any] {
        return ["type": type, "value": value]
    }
}
