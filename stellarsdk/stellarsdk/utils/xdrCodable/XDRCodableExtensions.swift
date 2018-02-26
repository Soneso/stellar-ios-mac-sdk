//
//  XDRCodableExtensions.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

// Based on https://github.com/kinfoundation/StellarKit

import Foundation

extension Array: XDRCodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        try encoder.encode(UInt32(self.count))
        for element in self {
            try (element as! Encodable).encode(to: encoder)
        }
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        guard let binaryElement = Element.self as? Decodable.Type else {
            throw XDRDecoder.Error.typeNotConformingToDecodable(Element.self)
        }
        
        let count = try decoder.decode(UInt32.self)
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
        
        let padding = Data(repeating: 0, count: 4 - count % 4)
        if (1...3).contains(padding.count) {
            try padding.xdrEncodeFixed(to: encoder)
        }
    }
    
    public func xdrEncodeFixed(to encoder: XDREncoder) throws {
        try forEach { try $0.encode(to: encoder) }
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        let bytes: [UInt8] = try Array(fromBinary: decoder)
        self.init(bytes: bytes)
        
        if bytes.count % 4 != 0 {
            _ = try (0..<(4 - bytes.count % 4)).forEach { _ in try _ = UInt8(fromBinary: decoder) }
        }
    }
    
    public init(fromBinary xdrDecoder: XDRDecoder, count: Int) throws {
        let bytes: [UInt8] = try Array(fromBinary: xdrDecoder, count: count)
        self.init(bytes: bytes)
    }
}

extension Optional: XDREncodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        guard let unwrapped = self else {
            try encoder.encode(Int32(0))
            return
        }
        
        try encoder.encode(Int32(1))
        guard let encodable = unwrapped as? XDREncodable else {
            throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: unwrapped))
        }
        try encoder.encode(encodable)
    }
}

extension UInt8: XDRCodable {}
extension Int32: XDRCodable {}
extension UInt32: XDRCodable {}
extension Int64: XDRCodable {}
extension UInt64: XDRCodable {}
extension Bool: XDRCodable {}
