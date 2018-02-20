//
//  XDRCodableExtensions.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension Array: XDRCodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        try encoder.encode(Int32(self.count))
        for element in self {
            try (element as! Encodable).encode(to: encoder)
        }
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        guard let binaryElement = Element.self as? Decodable.Type else {
            throw XDRDecoder.Error.typeNotConformingToDecodable(Element.self)
        }
        
        let count = try decoder.decode(Int32.self)
        self.init()
        self.reserveCapacity(Int(count))
        for _ in 0 ..< count {
            let decoded = try binaryElement.init(from: decoder)
            self.append(decoded as! Element)
        }
    }
}

extension String: XDRCodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        try Array(self.utf8).xdrEncode(to: encoder)
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        let utf8: [UInt8] = try Array(fromBinary: decoder)
        if let str = String(bytes: utf8, encoding: .utf8) {
            self = str
        } else {
            throw XDRDecoder.Error.invalidUTF8(utf8)
        }
    }
}

extension FixedWidthInteger where Self: XDREncodable {
    public func xdrEncode(to encoder: XDREncoder) {
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: XDRDecodable {
    public init(fromBinary xdrDecoder: XDRDecoder) throws {
        var v = Self.init()
        try xdrDecoder.read(into: &v)
        self.init(bigEndian: v)
    }
}

extension Data: XDRCodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        try encoder.encode(map { $0 })
    }
    
    public func xdrEncodeFixed(to encoder: XDREncoder) throws {
        try forEach { try $0.encode(to: encoder) }
    }
    
    public init(fromBinary xdrDecoder: XDRDecoder) throws {
        let bytes: [UInt8] = try Array(fromBinary: xdrDecoder)
        self.init(bytes: bytes)
    }
    
    public init(fromBinary xdrDecoder: XDRDecoder, count: Int) throws {
        let bytes: [UInt8] = try Array(fromBinary: xdrDecoder, count: count)
        self.init(bytes: bytes)
    }
}

extension Optional: XDREncodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        switch self {
        case .some(let a):
            try encoder.encode(Int32(1))
            guard let encodable = a as? XDREncodable else {
                throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: a))
            }
            try encoder.encode(encodable)
        case nil:
            try encoder.encode(Int32(0))
        }
    }
}
extension UInt8: XDRCodable {}
extension Int32: XDRCodable {}
extension Int: XDRCodable {}
extension UInt32: XDRCodable {}
extension Int64: XDRCodable {}
extension UInt64: XDRCodable {}
extension Bool: XDRCodable {}

