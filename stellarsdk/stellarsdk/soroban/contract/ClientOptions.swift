//
//  ClientOptions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public class ClientOptions {
    
    /// Keypair of the Stellar account that will send this transaction. If restore is set to true, and restore is needed, the keypair must contain the private key (secret seed) otherwise the public key is sufficient.
    public var sourceAccountKeyPair:KeyPair
    
    /// The address of the contract the client will interact with.
    public var contractId:String
    
    /// The Stellar network this contract is deployed
    public var network:Network
    
    /// The URL of the RPC instance that will be used to interact with this contract.
    public var rpcUrl:String
    
    /// Enable soroban server logging (helpful for debugging). Default: false.
    public let enableServerLogging:Bool
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - sourceAccountKeyPair: Keypair of the Stellar account that will send this transaction. If restore is set to true, and restore is needed, the keypair must contain the private key (secret seed) otherwise the public key is sufficient.
    ///   - contractId: The address of the contract the client will interact with.
    ///   - network: The Stellar network this contract is deployed
    ///   - rpcUrl: The URL of the RPC instance that will be used to interact with this contract.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public init(sourceAccountKeyPair: KeyPair, contractId: String, network: Network, rpcUrl: String, enableServerLogging: Bool = false) {
        self.sourceAccountKeyPair = sourceAccountKeyPair
        self.contractId = contractId
        self.network = network
        self.rpcUrl = rpcUrl
        self.enableServerLogging = enableServerLogging
    }
    
}
