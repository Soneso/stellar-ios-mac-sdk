//
//  InstallRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public class InstallRequest {
    
    /// The URL of the RPC instance that will be used to install the contract.
    public let rpcUrl:String
    
    /// The Stellar network this contract is to be installed to.
    public let network:Network
    
    /// Keypair of the Stellar account that will send this transaction. The keypair must contain the private key for signing.
    public let sourceAccountKeyPair:KeyPair
        
    /// The contract code wasm bytes to install.
    public let wasmBytes:Data
    
    /// Enable soroban server logging (helpful for debugging). Default: false.
    public let enableServerLogging:Bool
    
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - rpcUrl: The URL of the RPC instance that will be used to install the contract.
    ///   - network: The Stellar network this contract is to be installed to.
    ///   - sourceAccountKeyPair: Keypair of the Stellar account that will send this transaction. The keypair must contain the private key for signing.
    ///   - wasmBytes: The contract code wasm bytes to install.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public init(rpcUrl: String, network: Network, sourceAccountKeyPair: KeyPair, wasmBytes: Data, enableServerLogging: Bool) {
        self.rpcUrl = rpcUrl
        self.network = network
        self.sourceAccountKeyPair = sourceAccountKeyPair
        self.wasmBytes = wasmBytes
        self.enableServerLogging = enableServerLogging
    }
    
}
