//
//  DataTypes.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

private func decodeData(from decoder: XDRDecoder, capacity: Int) throws -> Data {
    var d = Data(capacity: capacity)
    
    for _ in 0 ..< capacity {
        let decoded = try UInt8.init(from: decoder)
        d.append(decoded)
    }
    
    return d
}

public protocol WrappedData: XDRCodable, Equatable {
    static var capacity: Int { get }
    
    var wrapped: Data { get set }
    
    func xdrEncode(to encoder: XDREncoder) throws
    
    init()
    init(fromBinary decoder: XDRDecoder) throws
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

public struct WrappedData32: WrappedData, Equatable {
    public static let capacity: Int = 32
    
    public var wrapped: Data
    
    public init() {
        wrapped = Data()
    }
}

public struct WrappedData4: WrappedData {
    public static let capacity: Int = 4
    
    public var wrapped: Data
    
    public init() {
        wrapped = Data()
    }
}

public struct WrappedData12: WrappedData {
    public static let capacity: Int = 12
    
    public var wrapped: Data
    
    public init() {
        wrapped = Data()
    }
}
