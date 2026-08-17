//
//  String+Encoding.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 21/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing encoding utilities for String.
public extension String {
    var urlPathEncoded: String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/&=;+")
        return self.addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }

    var urlQueryValueEncoded: String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        return self.addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }

    /// URL-encodes the string for use in query parameters.
    ///
    /// Encodes characters that are not allowed in URL query parameters and keys.
    ///
    /// Example:
    /// ```swift
    /// let param = "Hello World & More"
    /// let encoded = param.urlEncoded // "Hello%20World%20%26%20More"
    /// ```
    var urlEncoded: String? {
        var allowedQueryParamAndKey = NSMutableCharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey)
    }
    
    /// URL-decodes the string by removing percent encoding.
    ///
    /// Example:
    /// ```swift
    /// let encoded = "Hello%20World"
    /// let decoded = encoded.urlDecoded // "Hello World"
    /// ```
    var urlDecoded: String? {
        return self.removingPercentEncoding
    }

    /// Validates if the string is a fully qualified domain name (FQDN).
    ///
    /// - Returns: True if the string matches FQDN format, false otherwise
    var isFullyQualifiedDomainName: Bool {
        let sRegex = "(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\\.)+[a-zA-Z]{2,63}\\.?$)"
        return NSPredicate(format: "SELF MATCHES[c] %@", sRegex).evaluate(with: self)
    }
    
    /// Extended encoding types beyond standard String.Encoding.
    enum ExtendedEncoding {
        /// Hexadecimal encoding (converts hex string to binary data).
        case hexadecimal
    }

    /// Converts the string to data using extended encoding types.
    ///
    /// For hexadecimal encoding, converts a hex string (with optional "0x" prefix) to binary data.
    ///
    /// - Parameter encoding: Extended encoding type to use
    /// - Returns: Converted data, or nil if conversion fails
    ///
    /// Example:
    /// ```swift
    /// let hex = "0x1234abcd"
    /// let data = hex.data(using: .hexadecimal)
    /// ```
    func data(using encoding:ExtendedEncoding) -> Data? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else { return nil }

        var newData = Data(capacity: hexStr.count/2)

        var currentIndex = hexStr.startIndex
        while currentIndex < hexStr.endIndex {
            // Safely get the next index for the second hex digit
            guard let nextIndex = hexStr.index(currentIndex, offsetBy: 1, limitedBy: hexStr.endIndex),
                  nextIndex < hexStr.endIndex else {
                return nil
            }

            let byteEndIndex = hexStr.index(after: nextIndex)
            let byteRange = currentIndex..<byteEndIndex
            guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
            newData.append(byte)

            currentIndex = byteEndIndex
        }
        return newData
    }
    
    /// Reads the hexadecimal spelling of a 32 byte id.
    ///
    /// The string must hold exactly the 64 hexadecimal characters those 32 bytes are wide,
    /// with no "0x" prefix. A string of any other width spells an id of another size, and a
    /// character outside the hexadecimal alphabet spells no byte at all; both are refused,
    /// because a 32 byte id derived from them would name a ledger entry the caller never wrote.
    ///
    /// - Parameter idKind: the name the id goes by in the error message, e.g. "contract id"
    /// - Returns: the 32 bytes the string spells
    /// - Throws: StellarSDKError.invalidArgument if the string is not exactly 64 hexadecimal
    /// characters
    func wrappedData32FromHex(idKind: String) throws -> WrappedData32 {
        let size = StellarProtocolConstants.SHA256_HASH_SIZE
        guard self.count == size * 2 else {
            throw StellarSDKError.invalidArgument(message: "invalid \(idKind) length \(self.count), must be \(size * 2) hex characters")
        }
        // UInt8(_:radix:) reads a signed pair like "+1" as a byte, so the alphabet is
        // checked directly rather than left to the pair parser.
        guard self.allSatisfy({ $0.isASCII && $0.isHexDigit }),
              let data = self.data(using: .hexadecimal), data.count == size else {
            throw StellarSDKError.invalidArgument(message: "invalid \(idKind), not a hex string \(self)")
        }
        return WrappedData32(data)
    }
}
