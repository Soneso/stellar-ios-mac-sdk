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
        let sRegex = "(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-).)+[a-zA-Z]{2,63}.?$)"
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

        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }
    
    /// Converts a hexadecimal string to WrappedData32.
    ///
    /// Removes leading zeros and converts the hex string to 32-byte wrapped data.
    /// Used for Soroban contract data encoding.
    ///
    /// - Returns: WrappedData32 representation of the hex string
    func wrappedData32FromHex() -> WrappedData32 {
        var hex = self
        // remove leading zeros
        while hex.hasPrefix("00") && hex.count >= 66 {
            hex = String(hex.dropFirst(2))
        }
        var data = Data()
        while(hex.count > 0) {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            var ch: UInt64 = 0
            Scanner(string: c).scanHexInt64(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return WrappedData32(data)
    }
}
