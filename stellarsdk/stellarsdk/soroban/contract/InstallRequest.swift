//
//  InstallRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Request parameters for installing (uploading) contract WebAssembly code.
///
/// Installing a contract uploads the compiled WASM bytecode to the Stellar network,
/// making it available for deployment. The same WASM code can be used to deploy
/// multiple contract instances.
///
/// Required parameters:
/// - Source account keypair (with private key for signing)
/// - Contract WASM bytecode
/// - Network and RPC endpoint
///
/// Example:
/// ```swift
/// // Load contract WASM file
/// let wasmBytes = try Data(contentsOf: contractWasmUrl)
///
/// let installRequest = InstallRequest(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     network: Network.testnet,
///     sourceAccountKeyPair: sourceKeyPair,
///     wasmBytes: wasmBytes,
///     enableServerLogging: false
/// )
///
/// let wasmHash = try await SorobanClient.install(installRequest: installRequest)
/// print("Installed with hash: \(wasmHash)")
/// ```
///
/// See also:
/// - [SorobanClient.install] for installing contracts
/// - [DeployRequest] for deploying contract instances
public final class InstallRequest: Sendable {
    
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
