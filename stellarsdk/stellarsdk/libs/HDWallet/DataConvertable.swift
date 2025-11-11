//
//  DataConvertable.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/02/11.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

import Foundation

/// Protocol for types that can be converted to Data and appended using the + operator.
///
/// This protocol enables convenient syntax for building binary data structures by allowing
/// primitive types like UInt8 and UInt32 to be directly appended to Data objects using
/// the + and += operators.
///
/// Used internally in BIP-32 key derivation to construct binary messages for HMAC operations.
///
/// Example:
/// ```swift
/// var data = Data()
/// data += UInt8(0)        // Append single byte
/// data += UInt32(12345)   // Append 4-byte integer
/// ```
protocol DataConvertable {
    /// Appends the value to the data.
    ///
    /// - Parameter lhs: The data to append to
    /// - Parameter rhs: The value to append
    ///
    /// - Returns: New Data with the value appended
    static func +(lhs: Data, rhs: Self) -> Data

    /// Appends the value to the data in-place.
    ///
    /// - Parameter lhs: The data to append to (modified in-place)
    /// - Parameter rhs: The value to append
    static func +=(lhs: inout Data, rhs: Self)
}

extension DataConvertable {
    static func +(lhs: Data, rhs: Self) -> Data {
        var value = rhs
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        return lhs + data
    }

    static func +=(lhs: inout Data, rhs: Self) {
        lhs = lhs + rhs
    }
}

extension UInt8: DataConvertable {}
extension UInt32: DataConvertable {}

