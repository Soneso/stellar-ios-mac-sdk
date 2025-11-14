//
//  SEP30Request.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Request structure for registering or updating account recovery identities.
///
/// Used when registering a new account or updating identities for an existing account
/// with a SEP-30 recovery service. Contains the list of identities that can recover the account.
public struct Sep30Request {

    /// List of identities that can authenticate to gain control of the account.
    /// Each identity can have multiple authentication methods.
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

/// Identity configuration for account recovery.
///
/// Represents a person or entity that can recover the account by authenticating
/// through one of the configured authentication methods.
public struct Sep30RequestIdentity {

    /// Role of this identity in relation to the account.
    /// Not used by the server but stored and returned to help clients identify each identity.
    /// Common values: "owner", "sender", "receiver".
    public var role:String

    /// Authentication methods that can be used to authenticate as this identity.
    /// At least one method must be provided. Authentication with any method grants full account access.
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

/// Authentication method for identity verification.
///
/// Specifies how an identity can be authenticated to recover account access.
/// Multiple methods can be configured per identity for flexibility.
public struct Sep30AuthMethod {

    /// Type of authentication method.
    /// Common values: "stellar_address" (proven via SEP-10), "phone_number" (E.164 format with leading +), "email".
    public var type:String

    /// Unique identifier for this authentication method.
    /// Format depends on type: Stellar address for stellar_address, phone number for phone_number, email address for email.
    public var value:String

    public init(type:String, value:String) {
        self.type = type
        self.value = value
    }

    public func toJson() -> [String : Any] {
        return ["type": type, "value": value]
    }
}
