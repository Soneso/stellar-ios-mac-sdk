//
//  CryptographicConstants.swift
//  stellarsdk
//
//  Created on 30.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Cryptographic constants used throughout the SDK.
/// These values define parameters for checksum algorithms, bit operations,
/// and other low-level cryptographic functions.
public struct CryptographicConstants: Sendable {

    // MARK: - CRC-16-CCITT-XModem Algorithm

    /// Polynomial value for CRC-16-CCITT-XModem algorithm (0x1021)
    /// This is the divisor used in the CRC calculation for StrKey checksums
    /// Reference: https://en.wikipedia.org/wiki/Cyclic_redundancy_check
    public static let CRC16_POLYNOMIAL: UInt16 = 0x1021

    /// High bit mask for CRC-16 (0x8000)
    /// Used to detect when the most significant bit is set during CRC calculation
    /// Reference: https://en.wikipedia.org/wiki/Cyclic_redundancy_check
    public static let CRC16_HIGH_BIT_MASK: UInt16 = 0x8000

    /// Initial CRC-16 value (0x0000)
    /// The starting value for CRC-16-CCITT-XModem calculation
    /// Reference: https://en.wikipedia.org/wiki/Cyclic_redundancy_check
    public static let CRC16_INITIAL: UInt16 = 0x0000

    /// Size of CRC-16 checksum in bytes (2 bytes)
    /// The CRC-16 checksum is appended to StrKey encoded data
    /// Reference: [Stellar developer docs](https://developers.stellar.org)
    public static let CRC16_SIZE = 2

    /// Number of iterations per byte in CRC-16 calculation (8 iterations)
    /// Each byte requires processing all 8 bits
    /// Reference: https://en.wikipedia.org/wiki/Cyclic_redundancy_check
    public static let CRC16_ITERATIONS = 8

    // MARK: - Bit Operations

    /// Byte mask for bit operations (0xFF)
    /// Used to mask values to a single byte (0-255 range)
    public static let BYTE_MASK: UInt32 = 0xFF

    /// Number of bits per byte (8 bits)
    /// Standard constant for bit-level operations
    public static let BITS_PER_BYTE = 8
}
