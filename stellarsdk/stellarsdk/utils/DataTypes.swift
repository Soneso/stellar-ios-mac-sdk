//
//  DataTypes.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Decodes fixed-size binary data from an XDR decoder.
///
/// Reads exactly the specified number of bytes from the decoder.
///
/// - Parameter decoder: XDR decoder to read from
/// - Parameter capacity: Number of bytes to read
/// - Returns: Decoded data
/// - Throws: XDRDecoder.Error if decoding fails
private func decodeData(from decoder: XDRDecoder, capacity: Int) throws -> Data {
    var d = Data(capacity: capacity)
    
    for _ in 0 ..< capacity {
        let decoded = try UInt8.init(from: decoder)
        d.append(decoded)
    }
    
    return d
}

/// Protocol for fixed-size binary data wrappers used in XDR encoding.
///
/// WrappedData provides a type-safe way to handle fixed-size byte arrays in Stellar's
/// XDR protocol. Common sizes include 4, 12, and 32 bytes for various key types and hashes.
public protocol WrappedData: XDRCodable, Equatable {
    /// Fixed capacity in bytes for this data type.
    static var capacity: Int { get }

    /// The underlying binary data.
    var wrapped: Data { get set }

    /// Encodes the data to XDR format.
    func xdrEncode(to encoder: XDREncoder) throws

    /// Creates an empty instance.
    init()

    /// Decodes from XDR format.
    init(fromBinary decoder: XDRDecoder) throws

    /// Creates an instance from data, padding to capacity if necessary.
    init(_ data: Data)
}

extension WrappedData {
    public func xdrEncode(to encoder: XDREncoder) throws {
        try wrapped.forEach { try $0.encode(to: encoder) }
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        self.init()
        wrapped = try decodeData(from: decoder, capacity: Self.capacity)
    }
    
    public init(_ data: Data) {
        self.init()
        
        if data.count >= Self.capacity {
            self.wrapped = data
        }
        else {
            var d = data
            d.append(Data(count: Self.capacity - data.count))
            self.wrapped = d
        }
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped == rhs.wrapped
    }
}

/// Fixed-size 32-byte data wrapper.
///
/// Used for 256-bit hashes, public keys, and other 32-byte values in Stellar protocol.
/// Examples: SHA-256 hashes, Ed25519 public keys, transaction hashes.
public struct WrappedData32: WrappedData, Equatable {
    public static let capacity: Int = 32

    public var wrapped: Data

    public init() {
        wrapped = Data()
    }
}

/// Fixed-size 4-byte data wrapper.
///
/// Used for short binary identifiers and fixed-size fields in Stellar protocol.
public struct WrappedData4: WrappedData {
    public static let capacity: Int = 4

    public var wrapped: Data

    public init() {
        wrapped = Data()
    }
}

/// Fixed-size 12-byte data wrapper.
///
/// Used for 12-character asset codes and other 12-byte values in Stellar protocol.
public struct WrappedData12: WrappedData {
    public static let capacity: Int = 12

    public var wrapped: Data

    public init() {
        wrapped = Data()
    }
}
