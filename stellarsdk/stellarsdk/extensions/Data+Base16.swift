//
//  Data+Base16.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/19/18.
//  Copyright © 2018 Soneso. All rights reserved.
//
//  DEPRECATED: This file is deprecated. Use Data+B16.swift instead.
//  - hexEncodedString() -> use base16EncodedString() from Data+B16.swift
//  - HexEncodingOptions.upperCase -> use Base16EncodingOptions.uppercase
//
//  Data+B16.swift provides both encoding and decoding functionality,
//  while this file only provides encoding.
//

import Foundation

/// Extension providing hexadecimal (base16) encoding for Data.
/// - Note: This extension is deprecated. Use `base16EncodedString()` from Data+B16.swift instead.
extension Data {

    /// Options for hexadecimal encoding.
    /// - Note: Deprecated. Use `Base16EncodingOptions` from Data+B16.swift instead.
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        /// Use uppercase letters (A-F) instead of lowercase (a-f).
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    /// Encodes data to a hexadecimal string.
    ///
    /// - Parameter options: Encoding options (e.g., uppercase)
    /// - Returns: Hexadecimal string representation
    ///
    /// Example:
    /// ```swift
    /// let data = Data([0x12, 0x34, 0xAB, 0xCD])
    /// let hex = data.hexEncodedString() // "1234abcd"
    /// let hexUpper = data.hexEncodedString(options: .upperCase) // "1234ABCD"
    /// ```
    ///
    /// - Note: Deprecated. Use `base16EncodedString()` from Data+B16.swift instead.
    @available(*, deprecated, message: "Use base16EncodedString() from Data+B16.swift instead")
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let hexDigits = Array((options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * count)
        for byte in self {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
    }
}
