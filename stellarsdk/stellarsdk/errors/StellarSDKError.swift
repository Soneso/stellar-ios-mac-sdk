//
//  StellarSDKError.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 14.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// General errors that can occur during Stellar SDK operations.
public enum StellarSDKError: Error, Sendable {
    /// An invalid argument was provided to an SDK function.
    case invalidArgument(message: String)
    /// XDR decoding failed when parsing binary Stellar protocol data.
    case xdrDecodingError(message: String)
    /// XDR encoding failed when serializing data to binary Stellar protocol format.
    case xdrEncodingError(message: String)
    /// Data encoding failed during transformation or serialization.
    case encodingError(message: String)
    /// Data decoding failed during parsing or deserialization.
    case decodingError(message: String)
}
