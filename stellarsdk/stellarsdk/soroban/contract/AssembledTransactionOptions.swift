//
//  AssembledTransactionOptions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Configuration options for assembling and simulating Soroban smart contract transactions.
public final class AssembledTransactionOptions: Sendable {

    /// Client configuration including RPC endpoint, network, and source account.
    public let clientOptions:ClientOptions

    /// Method-specific options including fee, timeout, and simulation settings.
    public let methodOptions:MethodOptions
    
    /// Name of the contract method to call.
    public let method:String
    
    /// Arguments to pass to the method call.
    public let arguments:[SCValXDR]?
    
    /// Enable soroban server logging (helpful for debugging). Default: false.
    public let enableServerLogging:Bool
    
    /// Whether the transaction is built for reading only.
    ///
    /// An ``AssembledTransaction`` with this flag builds without loading the source account,
    /// on sequence number 0, so it simulates for any source account, also one that does not
    /// exist and one whose keypair nobody holds. It allows
    /// ``AssembledTransaction/signAuthEntries(signerKeyPair:authorizeEntryCallback:validUntilLedgerSeq:)``
    /// and refuses to sign its envelope, to submit, and to restore archived entries, each
    /// with `AssembledTransactionError.missingPrivateKey`.
    /// ``SorobanClient/forSpecEntries(specEntries:options:readOnly:)`` sets it for every
    /// transaction of a read-only client.
    public let readOnly:Bool

    /// Constructor
    ///
    /// - Parameters:
    ///   - clientOptions: Client options.
    ///   - methodOptions: Method options.
    ///   - method: Name of the contract method to call.
    ///   - arguments: Arguments to pass to the method call.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public convenience init(clientOptions: ClientOptions, methodOptions: MethodOptions, method: String, arguments: [SCValXDR]? = nil, enableServerLogging: Bool = false) {
        self.init(clientOptions: clientOptions,
                  methodOptions: methodOptions,
                  method: method,
                  arguments: arguments,
                  enableServerLogging: enableServerLogging,
                  readOnly: false)
    }

    /// Constructor that also states whether the transaction is built for reading only.
    ///
    /// - Parameters:
    ///   - clientOptions: Client options.
    ///   - methodOptions: Method options.
    ///   - method: Name of the contract method to call.
    ///   - arguments: Arguments to pass to the method call.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///   - readOnly: Whether the transaction is built for reading only; see ``readOnly``.
    ///
    public init(clientOptions: ClientOptions, methodOptions: MethodOptions, method: String, arguments: [SCValXDR]? = nil, enableServerLogging: Bool = false, readOnly: Bool) {
        self.clientOptions = clientOptions
        self.methodOptions = methodOptions
        self.method = method
        self.arguments = arguments
        self.enableServerLogging = enableServerLogging
        self.readOnly = readOnly
    }
    
}
