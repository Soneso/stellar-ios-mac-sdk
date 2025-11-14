//
//  AssembledTransactionOptions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Configuration options for assembling and simulating Soroban smart contract transactions.
public class AssembledTransactionOptions {

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
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - clientOptions: Client options.
    ///   - methodOptions: Method options.
    ///   - method: Name of the contract method to call.
    ///   - arguments: Arguments to pass to the method call.
    ///   - enableServerLogging: Enable soroban server logging (helpful for debugging). Default: false.
    ///
    public init(clientOptions: ClientOptions, methodOptions: MethodOptions, method: String, arguments: [SCValXDR]? = nil, enableServerLogging: Bool = false) {
        self.clientOptions = clientOptions
        self.methodOptions = methodOptions
        self.method = method
        self.arguments = arguments
        self.enableServerLogging = enableServerLogging
    }
    
}
