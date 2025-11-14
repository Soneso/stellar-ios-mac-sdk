//
//  Data+Base32.swift
//  stellarsdk
//
//  Created by Андрей Катюшин on 16.04.2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing base32 encoding and decoding for Data.
///
/// Supports both standard base32 (RFC 4648) and base32hex variants.
/// Used extensively in Stellar's StrKey encoding for account addresses and keys.
extension Data {
    /// Encodes data to a base32 string.
    ///
    /// Uses the standard base32 alphabet (A-Z, 2-7).
    ///
    /// Example:
    /// ```swift
    /// let data = Data([72, 101, 108, 108, 111])
    /// let encoded = data.base32EncodedString // "JBSWY3DP"
    /// ```
    public var base32EncodedString: String {
        return base32Encode(self)
    }

    /// Encodes data to base32 format as Data.
    ///
    /// Returns the base32-encoded string as UTF-8 data.
    ///
    /// Example:
    /// ```swift
    /// let data = Data([72, 101, 108, 108, 111])
    /// let encodedData = data.base32EncodedData
    /// ```
    public var base32EncodedData: Data {
        return base32EncodedString.dataUsingUTF8StringEncoding
    }

    /// Decodes base32-encoded data.
    ///
    /// Assumes the data contains a UTF-8 encoded base32 string.
    ///
    /// - Returns: Decoded data, or nil if decoding fails
    ///
    /// Example:
    /// ```swift
    /// let encoded = "JBSWY3DP".data(using: .utf8)!
    /// if let decoded = encoded.base32DecodedData {
    ///     // Use decoded data
    /// }
    /// ```
    public var base32DecodedData: Data? {
        return String(data: self, encoding: .utf8).flatMap(base32DecodeToData)
    }

    /// Encodes data to a base32hex string.
    ///
    /// Uses the extended hex alphabet (0-9, A-V).
    ///
    /// Example:
    /// ```swift
    /// let data = Data([72, 101, 108, 108, 111])
    /// let encoded = data.base32HexEncodedString
    /// ```
    public var base32HexEncodedString: String {
        return base32HexEncode(self)
    }

    /// Encodes data to base32hex format as Data.
    ///
    /// Returns the base32hex-encoded string as UTF-8 data.
    public var base32HexEncodedData: Data {
        return base32HexEncodedString.dataUsingUTF8StringEncoding
    }

    /// Decodes base32hex-encoded data.
    ///
    /// Assumes the data contains a UTF-8 encoded base32hex string.
    ///
    /// - Returns: Decoded data, or nil if decoding fails
    public var base32HexDecodedData: Data? {
        return String(data: self, encoding: .utf8).flatMap(base32HexDecodeToData)
    }
}
