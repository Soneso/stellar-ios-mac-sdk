//
//  ClientOptions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Configuration options for SorobanClient instances.
///
/// ClientOptions specifies the connection parameters and authentication details
/// needed to interact with a deployed smart contract.
///
/// Required configuration:
/// - Source account keypair (public key required, private key needed for signing)
/// - Contract ID (the address of the deployed contract)
/// - Network selection (testnet, mainnet, or custom)
/// - RPC URL (endpoint for Soroban RPC server)
///
/// Example:
/// ```swift
/// let clientOptions = ClientOptions(
///     sourceAccountKeyPair: sourceKeyPair,
///     contractId: "CCONTRACT123...",
///     network: Network.testnet,
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     enableServerLogging: false
/// )
///
/// let client = try await SorobanClient.forClientOptions(options: clientOptions)
/// ```
///
/// See also:
/// - [SorobanClient.forClientOptions] for creating client instances
/// - [MethodOptions] for transaction-specific settings
public final class ClientOptions: Sendable {

    /// Keypair of the Stellar account that will send this transaction. If restore is set to true, and restore is needed, the keypair must contain the private key (secret seed) otherwise the public key is sufficient.
    public let sourceAccountKeyPair:KeyPair

    /// The address of the contract the client will interact with.
    public let contractId:String

    /// The Stellar network this contract is deployed
    public let network:Network

    /// The URL of the RPC instance that will be used to interact with this contract.
    public let rpcUrl:String
    
    /// Enable soroban server logging (helpful for debugging). Default: false.
    public let enableServerLogging:Bool

    /// Optional URL session handed to every ``SorobanServer`` created from these
    /// options. Defaults to ``URLSession/shared`` when nil; see
    /// ``SorobanServer/init(endpoint:urlSession:)``. The SDK does not
    /// invalidate an injected session.
    public let urlSession:URLSession?

    /// Constructor
    ///
    /// - Parameters:
    ///   - sourceAccountKeyPair: Keypair of the Stellar account that will send this transaction. If restore is set to true, and restore is needed, the keypair must contain the private key (secret seed) otherwise the public key is sufficient.
    ///   - contractId: The address of the contract the client will interact with.
    ///   - network: The Stellar network this contract is deployed
    ///   - rpcUrl: The URL of the RPC instance that will be used to interact with this contract.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///   - urlSession: Optional URL session used for every RPC request. Defaults to ``URLSession/shared`` when nil; see ``SorobanServer/init(endpoint:urlSession:)``.
    ///
    public init(sourceAccountKeyPair: KeyPair, contractId: String, network: Network, rpcUrl: String, enableServerLogging: Bool = false, urlSession: URLSession? = nil) {
        self.sourceAccountKeyPair = sourceAccountKeyPair
        self.contractId = contractId
        self.network = network
        self.rpcUrl = rpcUrl
        self.enableServerLogging = enableServerLogging
        self.urlSession = urlSession
    }
    
}
