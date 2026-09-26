//
//  XDRCodableExtensions.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

// Based on https://github.com/kinfoundation/StellarKit

import Foundation

/// Minimum number of bytes a schema-level XDR array element occupies.
///
/// Scalars, enum and union discriminants, optional flags and length prefixes are 4 bytes,
/// and fixed opaque data is padded to a multiple of 4.
private let minXdrElementWidth = 4

/// Validates the element count of a variable-length XDR array against the bytes left to read.
///
/// Each element occupies at least `minElementWidth` bytes, so a count above
/// `remainingBytes / minElementWidth` cannot be satisfied by the input. Checking it before
/// the caller reserves storage keeps a hostile count from sizing an allocation.
///
/// - Parameter count: Element count read from the array's length prefix
/// - Parameter minElementWidth: Minimum encoded width of one element in bytes
/// - Parameter decoder: Decoder positioned right after the length prefix
/// - Throws: StellarSDKError.xdrDecodingError if the count exceeds what the remaining bytes can hold
private func requireArrayCount(_ count: UInt32, minElementWidth: Int, decoder: XDRDecoder) throws {
    let remainingBytes = decoder.remainingBytes
    let maxCount = remainingBytes / minElementWidth
    guard UInt64(count) <= UInt64(maxCount) else {
        throw StellarSDKError.xdrDecodingError(message: "XDR array count \(count) exceeds the maximum of \(maxCount) for the \(remainingBytes) remaining bytes")
    }
}

/// Decodes an array of XDR-encodable objects from a decoder.
///
/// XDR arrays are prefixed with a 32-bit count followed by the elements. The count is
/// validated against `maxCount` and against the remaining bytes, at 4 bytes per element,
/// before storage is reserved for it.
///
/// - Parameter type: Type of elements to decode
/// - Parameter dec: Decoder to read from
/// - Parameter maxCount: Maximum number of elements the schema allows
/// - Returns: Decoded array of elements
/// - Throws: StellarSDKError.xdrDecodingError if the count exceeds `maxCount` or the remaining
///   bytes, XDRDecoder.Error if decoding an element fails
func decodeArray<T: Codable>(type:T.Type, dec:Decoder, maxCount: UInt32 = UInt32.max) throws -> [T] {
    guard let decoder = dec as? XDRDecoder else {
        throw XDRDecoder.Error.typeNotConformingToDecodable(Decoder.Type.self)
    }

    let count = try decoder.decode(UInt32.self)
    guard count <= maxCount else {
        throw StellarSDKError.xdrDecodingError(message: "Array count \(count) exceeds maximum \(maxCount)")
    }
    try requireArrayCount(count, minElementWidth: minXdrElementWidth, decoder: decoder)
    var array = [T]()
    array.reserveCapacity(Int(count))
    for _ in 0 ..< count {
        let decoded = try decoder.decode(type)
        array.append(decoded)
    }

    return array
}

/// Decodes an array where each element is XDR-optional (Int32 present flag + value).
///
/// Used for arrays of optional typedef types like `SponsorshipDescriptor`
/// (`typedef AccountID* SponsorshipDescriptor`), where each array element
/// is preceded by a 32-bit present/absent flag (RFC 4506 boolean). The flag alone
/// takes 4 bytes, so the count is validated against the remaining bytes at 4 bytes
/// per element before storage is reserved for it.
///
/// - Parameter type: The wrapped (non-optional) element type to decode
/// - Parameter dec: Decoder to read from
/// - Parameter maxCount: Maximum number of elements the schema allows
/// - Returns: Array of optional elements
/// - Throws: StellarSDKError.xdrDecodingError if the count exceeds `maxCount` or the remaining
///   bytes, XDRDecoder.Error if decoding an element fails
func decodeArrayOfOptional<T: Codable>(type: T.Type, dec: Decoder, maxCount: UInt32 = UInt32.max) throws -> [T?] {
    guard let decoder = dec as? XDRDecoder else {
        throw XDRDecoder.Error.typeNotConformingToDecodable(Decoder.Type.self)
    }

    let count = try decoder.decode(UInt32.self)
    guard count <= maxCount else {
        throw StellarSDKError.xdrDecodingError(message: "Array count \(count) exceeds maximum \(maxCount)")
    }
    try requireArrayCount(count, minElementWidth: minXdrElementWidth, decoder: decoder)
    var array = [T?]()
    array.reserveCapacity(Int(count))
    for _ in 0..<count {
        let present = try decoder.decode(Int32.self)
        if present != 0 {
            array.append(try decoder.decode(type))
        } else {
            array.append(nil)
        }
    }
    return array
}

/// Encodes an array where each element is XDR-optional (Int32 present flag + value).
///
/// Used for arrays of optional typedef types like `SponsorshipDescriptor`,
/// where each array element is preceded by a 32-bit present/absent flag (RFC 4506 boolean).
///
/// - Parameter array: Array of optional elements to encode
/// - Parameter enc: Encoder to write to
/// - Throws: XDREncoder.Error if encoding fails
func encodeArrayOfOptional<T: Encodable>(_ array: [T?], enc: Encoder) throws {
    guard let encoder = enc as? XDREncoder else {
        throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: enc))
    }

    try encoder.encode(UInt32(array.count))
    for element in array {
        if let value = element {
            try encoder.encode(Int32(1))
            try value.encode(to: encoder)
        } else {
            try encoder.encode(Int32(0))
        }
    }
}

extension UnkeyedDecodingContainer {
    /// Decodes a void-only extension point that the SDK stores as a plain `Int32` field.
    ///
    /// The XDR union behind such a field has a single arm, `case 0: void`, so any other
    /// discriminant is not decodable.
    ///
    /// - Parameter typeName: Name of the type that holds the extension point, used in the error message
    /// - Returns: The discriminant, which is always 0
    /// - Throws: StellarSDKError.xdrDecodingError if the discriminant is not 0
    mutating func decodeExtensionPoint(_ typeName: String) throws -> Int32 {
        let value = try decode(Int32.self)
        guard value == 0 else {
            throw StellarSDKError.xdrDecodingError(message: "\(typeName) extension point must be 0, got \(value)")
        }
        return value
    }
}

/// Checks if a value is an Optional type.
///
/// Uses Swift reflection to determine if the instance is wrapped in Optional.
///
/// - Parameter instance: Value to check
/// - Returns: True if the value is Optional, false otherwise
func isOptional(_ instance: Any) -> Bool {
    let mirror = Mirror(reflecting: instance)
    let style = mirror.displayStyle
    return style == .optional
}

/// Unwraps an Optional value using reflection.
///
/// If the value is not Optional, returns it unchanged. If it's nil, returns nil.
/// Otherwise, returns the unwrapped value.
///
/// - Parameter any: Value to unwrap
/// - Returns: Unwrapped value, or nil if the Optional is nil
func unwrap(any:Any) -> Any? {

    let mi = Mirror(reflecting: any)
    if mi.displayStyle != .optional {
        return any
    }

    guard let first = mi.children.first else { return nil }
    let (_, some) = first
    return some

}

/// Extension making Array conform to XDRCodable when elements are XDRCodable.
///
/// Arrays in XDR are encoded with a 32-bit count prefix followed by the elements.
extension Array: XDRCodable where Element: XDRCodable {
    /// Encodes the array to XDR format.
    ///
    /// Writes the element count as UInt32 followed by each element.
    public func xdrEncode(to encoder: XDREncoder) throws {
        try encoder.encode(UInt32(self.count))
        for element in self {
            try element.encode(to: encoder)
        }
    }
    
    /// Decodes an array from XDR format.
    ///
    /// Reads the element count as UInt32 followed by the elements. This is also the byte
    /// reader behind `String` and `Data`, whose elements are single `UInt8` values; every
    /// other element type occupies at least 4 bytes. The count is validated against the
    /// remaining bytes at that minimum width before storage is reserved for it.
    ///
    /// - Throws: StellarSDKError.xdrDecodingError if the count exceeds what the remaining bytes
    ///   can hold, XDRDecoder.Error if decoding an element fails
    public init(fromBinary decoder: XDRDecoder) throws {
        let binaryElement = Element.self
        let count = try decoder.decode(UInt32.self)
        let minElementWidth = Element.self == UInt8.self ? 1 : minXdrElementWidth
        try requireArrayCount(count, minElementWidth: minElementWidth, decoder: decoder)
        self.init()
        self.reserveCapacity(Int(count))
        for _ in 0 ..< count {
            let decoded = try decoder.decode(binaryElement)
            self.append(decoded)
        }
    }
}

/// Extension making String conform to XDRCodable.
///
/// Strings in XDR are encoded as variable-length byte arrays with padding to 4-byte boundaries.
extension String: XDRCodable {
    /// Encodes the string to XDR format.
    ///
    /// Converts to UTF-8 bytes and encodes as a variable-length array.
    public func xdrEncode(to encoder: XDREncoder) throws {
        guard let data = self.data(using: .utf8) else {
            throw XDREncoder.Error.notUTF8Encodable(self)
        }
        
        try data.xdrEncode(to: encoder)
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        let utf8: [UInt8] = try Array(fromBinary: decoder)
        if let str = String(bytes: utf8, encoding: .utf8) {
            self = str
        } else {
            throw XDRDecoder.Error.invalidUTF8(utf8)
        }
        
        if utf8.count % 4 != 0 {
            _ = try (0..<(4 - utf8.count % 4)).forEach { _ in try _ = UInt8(fromBinary: decoder) }
        }
    }
}

/// Extension making FixedWidthInteger types XDR-encodable.
///
/// Integers in XDR are encoded in big-endian byte order.
extension FixedWidthInteger where Self: XDREncodable {
    /// Encodes the integer to XDR format in big-endian byte order.
    public func xdrEncode(to encoder: XDREncoder) {
        encoder.appendBytes(of: self.bigEndian)
    }
}

/// Extension making FixedWidthInteger types XDR-decodable.
extension FixedWidthInteger where Self: XDRDecodable {
    /// Decodes an integer from XDR format (big-endian byte order).
    public init(fromBinary xdrDecoder: XDRDecoder) throws {
        var v = Self.init()
        try xdrDecoder.read(into: &v)
        self.init(bigEndian: v)
    }
}

/// Extension making Data conform to XDRCodable.
///
/// Data in XDR is encoded as a variable-length byte array with padding to 4-byte boundaries.
extension Data: XDRCodable {
    /// Encodes data to XDR format with automatic padding.
    ///
    /// Encodes the byte count followed by the bytes, padded to a 4-byte boundary.
    public func xdrEncode(to encoder: XDREncoder) throws {
        try encoder.encode(map { $0 })
        
        let padding = Data(repeating: 0, count: 4 - count % 4)
        if (1...3).contains(padding.count) {
            try padding.xdrEncodeFixed(to: encoder)
        }
    }
    
    /// Encodes data to XDR format without length prefix (fixed-size encoding).
    ///
    /// Used for fixed-size byte arrays where the length is known in advance.
    public func xdrEncodeFixed(to encoder: XDREncoder) throws {
        try forEach { try $0.encode(to: encoder) }
    }

    /// Decodes variable-length data from XDR format.
    ///
    /// Reads the byte count, then the bytes, consuming any padding bytes.
    public init(fromBinary decoder: XDRDecoder) throws {
        let bytes: [UInt8] = try Array(fromBinary: decoder)
        self.init(bytes)
        
        if bytes.count % 4 != 0 {
            _ = try (0..<(4 - bytes.count % 4)).forEach { _ in try _ = UInt8(fromBinary: decoder) }
        }
    }
    
    /// Decodes fixed-size data from XDR format.
    ///
    /// Reads exactly the specified number of bytes without a length prefix.
    ///
    /// - Parameter xdrDecoder: Decoder to read from
    /// - Parameter count: Number of bytes to read
    public init(fromBinary xdrDecoder: XDRDecoder, count: Int) throws {
        let bytes: [UInt8] = try Array(fromBinary: xdrDecoder, count: count)
        self.init(bytes)
    }
}

/// Extension making Optional types XDR-encodable.
///
/// Optionals in XDR are encoded as a 32-bit boolean flag (0 or 1) followed by the value if present.
extension Optional: XDREncodable where Wrapped: XDRCodable {
    /// Encodes an optional value to XDR format.
    ///
    /// Writes 0 if nil, or 1 followed by the wrapped value if present.
    public func xdrEncode(to encoder: XDREncoder) throws {
        guard let unwrapped = self else {
            try encoder.encode(UInt32(0))
            return
        }
        
        try encoder.encode(UInt32(1))
        try encoder.encode(unwrapped)
    }
}

extension UInt8: XDRCodable {}
extension Int32: XDRCodable {}
extension UInt32: XDRCodable {}
extension Int64: XDRCodable {}
extension UInt64: XDRCodable {}
extension Bool: XDRCodable {}
