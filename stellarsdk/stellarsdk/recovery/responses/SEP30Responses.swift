//
//  SEP30Responses.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct SEP30ResponseIdentity: Decodable {

    public var role: String
    public var authenticated: Bool?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case role
        case authenticated
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        role = try values.decode(String.self, forKey: .role)
        authenticated = try values.decodeIfPresent(Bool.self, forKey: .authenticated)
    }
}

public struct SEP30ResponseSigner: Decodable {

    public var key: String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case key
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
    }
}

public struct Sep30AccountResponse: Decodable {

    public var address: String
    public var identities: [SEP30ResponseIdentity]
    public var signers: [SEP30ResponseSigner]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case address
        case identities
        case signers
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        address = try values.decode(String.self, forKey: .address)
        identities = try values.decode([SEP30ResponseIdentity].self, forKey: .identities)
        signers = try values.decode([SEP30ResponseSigner].self, forKey: .signers)
    }
}

public struct Sep30AccountsResponse: Decodable {

    public var accounts: [Sep30AccountResponse]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case accounts
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accounts = try values.decode([Sep30AccountResponse].self, forKey: .accounts)
    }
}

public struct Sep30SignatureResponse: Decodable {

    public var signature: String
    public var networkPassphrase: String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case signature
        case networkPassphrase = "network_passphrase"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signature = try values.decode(String.self, forKey: .signature)
        networkPassphrase = try values.decode(String.self, forKey: .networkPassphrase)
    }
}

