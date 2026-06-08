//
//  Data+Base64URL.swift
//  stellarsdk
//
//  Copyright © Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur during Base64URL encoding or decoding.
public enum Base64URLEncodingError: Error, Sendable {
    /// The input string cannot be decoded as Base64URL.
    case invalidInput(String)
}

/// Extension providing Base64URL (RFC 4648 §5) encoding and decoding for `Data`.
///
/// Base64URL uses the URL-safe alphabet: `-` instead of `+` and `_` instead of `/`.
/// Output is unpadded (no trailing `=` characters). The decoder accepts both padded and
/// unpadded input, normalising by re-padding to a multiple of four before delegating to the
/// platform Base64 decoder.
///
/// Example:
/// ```swift
/// let data = Data([0xFB, 0xFF])
/// let encoded = data.base64URLEncodedString() // "-_8"
/// let decoded = try Data(base64URLEncoded: "-_8") // Data([0xFB, 0xFF])
/// ```
public extension Data {

    /// Returns a Base64URL-encoded string (RFC 4648 §5, no padding).
    func base64URLEncodedString() -> String {
        let standard = base64EncodedString()
        var result = ""
        result.reserveCapacity(standard.count)
        for character in standard {
            switch character {
            case "+":
                result.append("-")
            case "/":
                result.append("_")
            case "=":
                continue
            default:
                result.append(character)
            }
        }
        return result
    }

    /// Creates data from a Base64URL-encoded string.
    ///
    /// Accepts input with or without trailing `=` padding. Re-pads internally and delegates
    /// to the platform Base64 decoder.
    ///
    /// - Parameter string: Base64URL-encoded string (with or without `=` padding).
    /// - Throws: `Base64URLEncodingError.invalidInput` when the string is not valid Base64URL.
    init(base64URLEncoded string: String) throws {
        var standard = ""
        standard.reserveCapacity(string.count + 2)
        for character in string {
            switch character {
            case "-":
                standard.append("+")
            case "_":
                standard.append("/")
            default:
                standard.append(character)
            }
        }
        let remainder = standard.count % 4
        switch remainder {
        case 0:
            break
        case 2:
            standard.append("==")
        case 3:
            standard.append("=")
        default:
            // A remainder of 1 is never produced by a well-formed encoder; let the platform
            // decoder surface the invalid input rather than fabricating padding.
            break
        }
        guard let decoded = Data(base64Encoded: standard) else {
            throw Base64URLEncodingError.invalidInput(string)
        }
        self = decoded
    }
}
