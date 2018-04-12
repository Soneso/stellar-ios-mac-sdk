//
//  XDRCodableExtensions.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

// Based on https://github.com/kinfoundation/StellarKit

import Foundation

func decodeArray<T: Codable>(type:T.Type, dec:Decoder) throws -> [T] {
    guard let decoder = dec as? XDRDecoder else {
        throw XDRDecoder.Error.typeNotConformingToDecodable(Decoder.Type.self)
    }
    
    let count = try decoder.decode(UInt32.self)
    var array = [T]()
    for _ in 0 ..< count {
        let decoded = try type.init(from: decoder)
        array.append(decoded)
    }
    
    return array
}

func isOptional(_ instance: Any) -> Bool {
    let mirror = Mirror(reflecting: instance)
    let style = mirror.displayStyle
    return style == .optional
}

func unwrap(any:Any) -> Any? {
    
    let mi = Mirror(reflecting: any)
    if mi.displayStyle != .optional {
        return any
    }
    
    if mi.children.count == 0 { return nil }
    let (_, some) = mi.children.first!
    return some
    
}

extension Array: XDRCodable where Element: XDRCodable {
    public func xdrEncode(to encoder: XDREncoder) throws {
        try encoder.encode(UInt32(self.count))
        for element in self {
            try element.encode(to: encoder)
        }
    }
    
    public init(fromBinary decoder: XDRDecoder) throws {
        let binaryElement = Element.self
        let count = try decoder.decode(UInt32.self)
        self.init()
        self.reserveCapacity(Int(count))
        for _ in 0 ..< count {
            let decoded = try binaryElement.init(from: decoder)
            self.append(decoded)
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

extension Optional: XDREncodable where Wrapped: XDRCodable {
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
