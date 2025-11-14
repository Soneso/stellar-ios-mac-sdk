//
//  String+Base32.swift
//  stellarsdk
//
//  Created by Андрей Катюшин on 16.04.2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing base32 encoding and decoding for String.
///
/// Supports both standard base32 (RFC 4648) and base32hex variants.
extension String {
    /// Decodes a base32-encoded string to data.
    ///
    /// Uses the standard base32 alphabet (A-Z, 2-7).
    ///
    /// Example:
    /// ```swift
    /// let encoded = "JBSWY3DPEBLW64TMMQ======"
    /// if let data = encoded.base32DecodedData {
    ///     // Use decoded data
    /// }
    /// ```
    public var base32DecodedData: Data? {
        return base32DecodeToData(self)
    }
    
    /// Encodes the string to base32 format.
    ///
    /// Uses the standard base32 alphabet (A-Z, 2-7).
    ///
    /// Example:
    /// ```swift
    /// let text = "Hello"
    /// let encoded = text.base32EncodedString
    /// ```
    public var base32EncodedString: String {
        return utf8CString.withUnsafeBufferPointer {
            base32encode($0.baseAddress!, $0.count - 1, alphabetEncodeTable)
        }
    }

    /// Decodes a base32-encoded string to a string.
    ///
    /// - Parameter encoding: Text encoding to use (defaults to UTF-8)
    /// - Returns: Decoded string, or nil if decoding fails
    public func base32DecodedString(_ encoding: String.Encoding = .utf8) -> String? {
        return base32DecodedData.flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
    
    /// Decodes a base32hex-encoded string to data.
    ///
    /// Uses the extended hex alphabet (0-9, A-V).
    public var base32HexDecodedData: Data? {
        return base32HexDecodeToData(self)
    }
    
    /// Encodes the string to base32hex format.
    ///
    /// Uses the extended hex alphabet (0-9, A-V).
    public var base32HexEncodedString: String {
        return utf8CString.withUnsafeBufferPointer {
            base32encode($0.baseAddress!, $0.count - 1, extendedHexAlphabetEncodeTable)
        }
    }

    /// Decodes a base32hex-encoded string to a string.
    ///
    /// - Parameter encoding: Text encoding to use (defaults to UTF-8)
    /// - Returns: Decoded string, or nil if decoding fails
    public func base32HexDecodedString(_ encoding: String.Encoding = .utf8) -> String? {
        return base32HexDecodedData.flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
}
