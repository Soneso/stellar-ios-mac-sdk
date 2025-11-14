//
//  String+Base64.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing base64 encoding and decoding for String.
extension String {

    /// Encodes the string to base64 format.
    ///
    /// Converts the string to UTF-8 data and then encodes it as a base64 string.
    ///
    /// - Returns: Base64-encoded string, or nil if encoding fails
    ///
    /// Example:
    /// ```swift
    /// let text = "Hello, Stellar!"
    /// let encoded = text.base64Encoded()
    /// ```
    public func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    /// Decodes a base64-encoded string.
    ///
    /// Decodes the base64 string to data and then converts it to a UTF-8 string.
    ///
    /// - Returns: Decoded string, or nil if decoding fails
    ///
    /// Example:
    /// ```swift
    /// let encoded = "SGVsbG8sIFN0ZWxsYXIh"
    /// let decoded = encoded.base64Decoded() // "Hello, Stellar!"
    /// ```
    public func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
