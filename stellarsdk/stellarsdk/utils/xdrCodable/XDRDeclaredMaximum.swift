//
//  XDRDeclaredMaximum.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.11.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

// The XDR definitions bound many variable-length values: an array to a number of elements,
// a string or an opaque value to a number of bytes. The network refuses a value above its
// bound, so the generated codecs check every bounded site when they read or write binary XDR.
//
// A string or opaque typedef is a Swift typealias of `String` or `Data` and cannot carry its
// bound, so the site that declares the value passes the maximum to the helpers below. Coding a
// bare `String` or `Data` value stays unbounded.
//
// The helpers act only when the container belongs to `XDRDecoder` or `XDREncoder`. A generated
// type coded through a Foundation coder behaves as it does without the bound, and so does a
// value written to an `XDREncoder` created without the declared maxima.

/// A coding container that reads from an `XDRDecoder`.
protocol XDRDecodingContainer {
    /// The decoder the container reads from.
    var decoder: XDRDecoder { get }
}

/// A coding container that writes to an `XDREncoder`.
protocol XDREncodingContainer {
    /// The encoder the container writes to.
    var encoder: XDREncoder { get }
}

/// The two variable-length byte forms of XDR, named as the length errors name them.
enum XDRByteSequenceKind: String {
    /// An XDR `string`: its length is its byte count, which is the UTF-8 byte count of text.
    case string
    /// Variable-length XDR `opaque` data.
    case opaque
}

/// Throws when an array to be encoded holds more elements than its XDR definition allows.
///
/// - Parameter count: Number of elements in the array
/// - Parameter maxCount: Maximum number of elements the schema allows
/// - Throws: StellarSDKError.xdrEncodingError if `count` exceeds `maxCount`
func requireEncodedArrayCount(_ count: Int, maxCount: UInt32) throws {
    guard count <= maxCount else {
        throw StellarSDKError.xdrEncodingError(message: "XDR array count \(count) exceeds the maximum of \(maxCount)")
    }
}

/// Throws when a string or opaque value to be encoded holds more bytes than its XDR definition
/// allows.
///
/// - Parameter length: Byte length of the value
/// - Parameter maxLength: Maximum byte length the schema allows
/// - Parameter kind: Whether the value is a string or opaque data, named in the error
/// - Throws: StellarSDKError.xdrEncodingError if `length` exceeds `maxLength`
func requireEncodedLength(_ length: Int, maxLength: UInt32, kind: XDRByteSequenceKind) throws {
    guard length <= maxLength else {
        throw StellarSDKError.xdrEncodingError(message: "XDR \(kind.rawValue) length \(length) exceeds the maximum of \(maxLength)")
    }
}

extension XDRDecoder {
    /// Decodes an XDR string of at most `maxLength` bytes.
    ///
    /// The bytes must be valid UTF-8 and are kept as they are, a leading byte order mark
    /// included, as `String(fromBinary:)` keeps them.
    ///
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrDecodingError if the length exceeds `maxLength` or the
    ///   remaining bytes, or for nonzero padding, XDRDecoder.Error.invalidUTF8 for invalid UTF-8,
    ///   XDRDecoder.Error.prematureEndOfData for missing padding
    func decodeString(maxLength: UInt32) throws -> String {
        return try nested {
            let utf8 = try decodeBoundedBytes(maxLength: maxLength, kind: .string)
            guard let string = String(xdrUTF8: utf8) else {
                throw XDRDecoder.Error.invalidUTF8(utf8)
            }
            try readPadding(after: utf8.count)
            return string
        }
    }

    /// Decodes variable-length opaque data of at most `maxLength` bytes.
    ///
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrDecodingError if the length exceeds `maxLength` or the
    ///   remaining bytes, or for nonzero padding, XDRDecoder.Error.prematureEndOfData for missing
    ///   padding
    func decodeOpaque(maxLength: UInt32) throws -> Data {
        return try nested { try decodeBoundedData(maxLength: maxLength, kind: .opaque) }
    }

    /// Decodes an XDR string of at most `maxLength` bytes as the bytes it holds.
    ///
    /// The bytes are not required to be UTF-8.
    ///
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrDecodingError if the length exceeds `maxLength` or the
    ///   remaining bytes, or for nonzero padding, XDRDecoder.Error.prematureEndOfData for missing
    ///   padding
    func decodeStringBytes(maxLength: UInt32) throws -> Data {
        return try nested { try decodeBoundedData(maxLength: maxLength, kind: .string) }
    }

    /// Reads a length-prefixed byte sequence and its padding.
    private func decodeBoundedData(maxLength: UInt32, kind: XDRByteSequenceKind) throws -> Data {
        let bytes = try decodeBoundedBytes(maxLength: maxLength, kind: kind)
        try readPadding(after: bytes.count)
        return Data(bytes)
    }

    /// Reads the length prefix, checks it against the declared maximum and then against the
    /// remaining bytes, and only then reads the bytes.
    private func decodeBoundedBytes(maxLength: UInt32, kind: XDRByteSequenceKind) throws -> [UInt8] {
        let length = try decode(UInt32.self)
        guard length <= maxLength else {
            throw StellarSDKError.xdrDecodingError(message: "XDR \(kind.rawValue) length \(length) exceeds the maximum of \(maxLength)")
        }
        return try [UInt8](fromBinary: self, count: Int(length))
    }
}

extension UnkeyedDecodingContainer {
    /// Decodes a string field its XDR definition bounds to `maxLength` bytes.
    ///
    /// A container that does not read XDR decodes the string unbounded.
    ///
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrDecodingError if the length exceeds `maxLength`, and the
    ///   errors `XDRDecoder.decodeString(maxLength:)` throws
    mutating func decodeString(maxLength: UInt32) throws -> String {
        guard let container = self as? XDRDecodingContainer else {
            return try decode(String.self)
        }
        return try container.decoder.decodeString(maxLength: maxLength)
    }

    /// Decodes a variable-length opaque field its XDR definition bounds to `maxLength` bytes.
    ///
    /// A container that does not read XDR decodes the data unbounded.
    ///
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrDecodingError if the length exceeds `maxLength`, and the
    ///   errors `XDRDecoder.decodeOpaque(maxLength:)` throws
    mutating func decodeOpaque(maxLength: UInt32) throws -> Data {
        guard let container = self as? XDRDecodingContainer else {
            return try decode(Data.self)
        }
        return try container.decoder.decodeOpaque(maxLength: maxLength)
    }

    /// Decodes a string field its XDR definition bounds to `maxLength` bytes as the bytes it
    /// holds.
    ///
    /// A container that does not read XDR decodes the data unbounded.
    ///
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrDecodingError if the length exceeds `maxLength`, and the
    ///   errors `XDRDecoder.decodeStringBytes(maxLength:)` throws
    mutating func decodeStringBytes(maxLength: UInt32) throws -> Data {
        guard let container = self as? XDRDecodingContainer else {
            return try decode(Data.self)
        }
        return try container.decoder.decodeStringBytes(maxLength: maxLength)
    }
}

extension UnkeyedEncodingContainer {
    /// Whether the container writes to an `XDREncoder` that applies the declared maxima.
    private var appliesDeclaredMaxima: Bool {
        return (self as? XDREncodingContainer)?.encoder.enforcesDeclaredMaxima ?? false
    }

    /// Encodes a variable-length array its XDR definition bounds to `maxCount` elements.
    ///
    /// A container that does not apply the declared maxima encodes the array unbounded.
    ///
    /// - Parameter value: The array to encode
    /// - Parameter maxCount: Maximum number of elements the schema allows
    /// - Throws: StellarSDKError.xdrEncodingError if the array holds more than `maxCount`
    ///   elements, and the errors encoding an element throws
    mutating func encodeArray<T: Encodable>(_ value: [T], maxCount: UInt32) throws {
        if appliesDeclaredMaxima {
            try requireEncodedArrayCount(value.count, maxCount: maxCount)
        }
        try encode(value)
    }

    /// Encodes an array of strings, each bounded to `maxLength` bytes of UTF-8 and the array to
    /// `maxCount` elements.
    ///
    /// A container that does not apply the declared maxima encodes the array unbounded.
    ///
    /// - Parameter value: The array to encode
    /// - Parameter maxCount: Maximum number of elements the schema allows
    /// - Parameter maxLength: Maximum byte length the schema allows for each element
    /// - Throws: StellarSDKError.xdrEncodingError if the array or an element exceeds its maximum
    mutating func encodeStringArray(_ value: [String], maxCount: UInt32 = UInt32.max, maxLength: UInt32) throws {
        if appliesDeclaredMaxima {
            try requireEncodedArrayCount(value.count, maxCount: maxCount)
            for element in value {
                try requireEncodedLength(element.utf8.count, maxLength: maxLength, kind: .string)
            }
        }
        try encode(value)
    }

    /// Encodes an array of opaque values, each bounded to `maxLength` bytes and the array to
    /// `maxCount` elements.
    ///
    /// A container that does not apply the declared maxima encodes the array unbounded.
    ///
    /// - Parameter value: The array to encode
    /// - Parameter maxCount: Maximum number of elements the schema allows
    /// - Parameter maxLength: Maximum byte length the schema allows for each element
    /// - Throws: StellarSDKError.xdrEncodingError if the array or an element exceeds its maximum
    mutating func encodeOpaqueArray(_ value: [Data], maxCount: UInt32 = UInt32.max, maxLength: UInt32) throws {
        if appliesDeclaredMaxima {
            try requireEncodedArrayCount(value.count, maxCount: maxCount)
            for element in value {
                try requireEncodedLength(element.count, maxLength: maxLength, kind: .opaque)
            }
        }
        try encode(value)
    }

    /// Encodes a string its XDR definition bounds to `maxLength` bytes of UTF-8.
    ///
    /// A container that does not apply the declared maxima encodes the string unbounded.
    ///
    /// - Parameter value: The string to encode
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrEncodingError if the UTF-8 form exceeds `maxLength` bytes
    mutating func encodeString(_ value: String, maxLength: UInt32) throws {
        if appliesDeclaredMaxima {
            try requireEncodedLength(value.utf8.count, maxLength: maxLength, kind: .string)
        }
        try encode(value)
    }

    /// Encodes variable-length opaque data its XDR definition bounds to `maxLength` bytes.
    ///
    /// A container that does not apply the declared maxima encodes the data unbounded.
    ///
    /// - Parameter value: The data to encode
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrEncodingError if the data exceeds `maxLength` bytes
    mutating func encodeOpaque(_ value: Data, maxLength: UInt32) throws {
        if appliesDeclaredMaxima {
            try requireEncodedLength(value.count, maxLength: maxLength, kind: .opaque)
        }
        try encode(value)
    }

    /// Encodes the bytes of a string its XDR definition bounds to `maxLength` bytes.
    ///
    /// A container that does not apply the declared maxima encodes the data unbounded.
    ///
    /// - Parameter value: The bytes of the string
    /// - Parameter maxLength: Maximum byte length the schema allows
    /// - Throws: StellarSDKError.xdrEncodingError if the bytes exceed `maxLength`
    mutating func encodeStringBytes(_ value: Data, maxLength: UInt32) throws {
        if appliesDeclaredMaxima {
            try requireEncodedLength(value.count, maxLength: maxLength, kind: .string)
        }
        try encode(value)
    }
}
