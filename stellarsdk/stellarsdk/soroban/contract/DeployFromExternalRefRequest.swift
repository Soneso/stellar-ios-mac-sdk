//
//  DeployFromExternalRefRequest.swift
//  stellarsdk
//
//  Created by Soneso on 19.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Request parameters for deploying a Soroban smart contract instance from a
/// CAP-85 external reference (protocol >= 28).
///
/// The executable is not a wasm hash: it names an owner contract and a tag, and
/// the owner holds a persistent contract data entry under that tag whose value
/// is the 32-byte hash of an already uploaded wasm. The created instance runs
/// that code. Nothing is installed as part of the deployment; the owner
/// contract already holds the tag entry.
///
/// See also:
/// - [SorobanClient.deployFromExternalRef] for the deployment method that uses this request
/// - [DeployRequest] for deploying from an installed wasm hash
public final class DeployFromExternalRefRequest: Sendable {

    /// The URL of the RPC instance that will be used to deploy the contract.
    public let rpcUrl:String

    /// The Stellar network this contract is to be deployed
    public let network:Network

    /// Keypair of the Stellar account that will send this transaction. The keypair must contain the private key for signing.
    public let sourceAccountKeyPair:KeyPair

    /// The contract holding the executable tag entry the new instance runs ("C..." strkey or the 64 character hex of the 32 byte id).
    public let executableOwner:String

    /// The tag the owner holds the executable entry under; matched byte for byte.
    /// An executable tag is an XDR string and may carry arbitrary bytes, so the
    /// canonical representation is `Data`; for a text tag use the `tag: String`
    /// initializer, which stores the tag as the UTF-8 bytes of the text.
    public let tag:Data

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
    ///   - executableOwner: The contract holding the executable tag entry ("C..." strkey or the 64 character hex of the 32 byte id).
    ///   - tag: The tag the owner holds the executable entry under; matched byte for byte.
    ///   - constructorArgs: Constructor/Initialization Args for the contract's `__constructor` method.
    ///   - salt: Salt used to generate the contract's ID. Default: random.
    ///   - methodOptions: Method options used to fine tune the transaction.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public init(rpcUrl: String, network: Network, sourceAccountKeyPair: KeyPair, executableOwner: String, tag: Data, constructorArgs: [SCValXDR]? = nil, salt: WrappedData32? = nil, methodOptions: MethodOptions = MethodOptions(), enableServerLogging: Bool) {
        self.rpcUrl = rpcUrl
        self.network = network
        self.sourceAccountKeyPair = sourceAccountKeyPair
        self.executableOwner = executableOwner
        self.tag = tag
        self.constructorArgs = constructorArgs
        self.salt = salt
        self.methodOptions = methodOptions
        self.enableServerLogging = enableServerLogging
    }

    /// Constructor for a text tag. Stores `tag` as the UTF-8 bytes of the given
    /// text; the entry is still matched byte for byte against those bytes.
    ///
    /// - Parameters:
    ///   - rpcUrl: The URL of the RPC instance that will be used to deploy the contract.
    ///   - network: The Stellar network this contract is to be deployed.
    ///   - sourceAccountKeyPair: Keypair of the Stellar account that will send this transaction. The keypair must contain the private key for signing.
    ///   - executableOwner: The contract holding the executable tag entry ("C..." strkey or the 64 character hex of the 32 byte id).
    ///   - tag: The tag the owner holds the executable entry under, stored as its UTF-8 bytes.
    ///   - constructorArgs: Constructor/Initialization Args for the contract's `__constructor` method.
    ///   - salt: Salt used to generate the contract's ID. Default: random.
    ///   - methodOptions: Method options used to fine tune the transaction.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public convenience init(rpcUrl: String, network: Network, sourceAccountKeyPair: KeyPair, executableOwner: String, tag: String, constructorArgs: [SCValXDR]? = nil, salt: WrappedData32? = nil, methodOptions: MethodOptions = MethodOptions(), enableServerLogging: Bool) {
        self.init(rpcUrl: rpcUrl,
                  network: network,
                  sourceAccountKeyPair: sourceAccountKeyPair,
                  executableOwner: executableOwner,
                  tag: Data(tag.utf8),
                  constructorArgs: constructorArgs,
                  salt: salt,
                  methodOptions: methodOptions,
                  enableServerLogging: enableServerLogging)
    }
}
