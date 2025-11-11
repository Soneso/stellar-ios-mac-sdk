//
//  Base58Encode.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/02/11.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

import Foundation

/// Provides Base58 encoding functionality.
///
/// Base58 is a binary-to-text encoding scheme used to represent binary data in an
/// ASCII string format. Unlike Base64, it omits similar-looking characters (0, O, I, l)
/// to reduce user errors when manually entering or copying encoded data.
///
/// Base58 is commonly used in cryptocurrency applications for encoding addresses and keys.
/// The alphabet used is: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
///
/// Note: Stellar primarily uses Base32 (strkey format) for account IDs and secret seeds,
/// but Base58 encoding is included for compatibility with other systems and standards.
public struct Base58 {
    private static let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    /// Encodes binary data to a Base58 string.
    ///
    /// Converts the input bytes to a Base58-encoded string using the Bitcoin Base58 alphabet.
    /// Leading zero bytes are preserved as '1' characters in the output.
    ///
    /// - Parameter bytes: The binary data to encode
    ///
    /// - Returns: A Base58-encoded string representation
    ///
    /// Example:
    /// ```swift
    /// let data = Data([0x00, 0x01, 0x02, 0x03])
    /// let encoded = Base58.encode(data)
    /// ```
    public static func encode(_ bytes: Data) -> String {
        var bytes = bytes
        var zerosCount = 0
        var length = 0
        
        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }
        
        bytes.removeFirst(zerosCount)
        
        let size = bytes.count * 138 / 100 + 1
        
        var base58: [UInt8] = Array(repeating: 0, count: size)
        for b in bytes {
            var carry = Int(b)
            var i = 0
            
            for j in 0...base58.count-1 where carry != 0 || i < length {
                carry += 256 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }
            
            assert(carry == 0)
            
            length = i
        }
        
        // skip leading zeros
        var zerosToRemove = 0
        var str = ""
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)
        
        while 0 < zerosCount {
            str = "\(str)1"
            zerosCount -= 1
        }
        
        for b in base58 {
            str = "\(str)\(alphabet[String.Index(encodedOffset: Int(b))])"
        }
        
        return str
    }
}
