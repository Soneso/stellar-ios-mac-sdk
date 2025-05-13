//
//  DeployRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public class DeployRequest {
    
    /// The URL of the RPC instance that will be used to deploy the contract.
    public let rpcUrl:String
    
    /// The Stellar network this contract is to be deployed
    public let network:Network
    
    /// Keypair of the Stellar account that will send this transaction. The keypair must contain the private key for signing.
    public let sourceAccountKeyPair:KeyPair
        
    /// The hash of the Wasm blob (in hex string format), which must already be installed on-chain.
    public let wasmHash:String
    
    /// Constructor/Initialization Args for the contract's `__constructor` method.
    public let constructorArgs:[SCValXDR]?
    
    /// Salt used to generate the contract's ID. Default: random.
    public let salt:WrappedData32?
    
    /// Method options used to fine tune the transaction.
    public let methodOptions:MethodOptions
    
    /// Enable soroban server logging (helpful for debugging). Default: false.
    public let enableServerLogging:Bool
    
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - rpcUrl: The URL of the RPC instance that will be used to deploy the contract.
    ///   - network: The Stellar network this contract is to be deployed.
    ///   - sourceAccountKeyPair: Keypair of the Stellar account that will send this transaction. The keypair must contain the private key for signing.
    ///   - wasmHash: The hash of the Wasm blob (in hex string format), which must already be installed on-chain.
    ///   - constructorArgs: Constructor/Initialization Args for the contract's `__constructor` method.
    ///   - salt: Salt used to generate the contract's ID. Default: random.
    ///   - methodOptions: Method options used to fine tune the transaction.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public init(rpcUrl: String, network: Network, sourceAccountKeyPair: KeyPair, wasmHash: String, constructorArgs: [SCValXDR]? = nil, salt: WrappedData32? = nil, methodOptions: MethodOptions = MethodOptions(), enableServerLogging: Bool) {
        self.rpcUrl = rpcUrl
        self.network = network
        self.sourceAccountKeyPair = sourceAccountKeyPair
        self.wasmHash = wasmHash
        self.constructorArgs = constructorArgs
        self.salt = salt
        self.methodOptions = methodOptions
        self.enableServerLogging = enableServerLogging
    }
}
