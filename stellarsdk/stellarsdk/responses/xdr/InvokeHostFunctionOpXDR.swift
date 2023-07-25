//
//  InvokeHostFunctionOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct UploadContractWasmArgsXDR: XDRCodable {
    public let code: Data
    
    public init(code:Data) {
        self.code = code
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        code = try container.decode(Data.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(code)
    }
}

public struct FromEd25519PublicKeyXDR: XDRCodable {
    public let key: WrappedData32
    public let signature: Data
    public let salt: WrappedData32
    
    public init(key: WrappedData32,signature:Data, salt:WrappedData32) {
        self.key = key
        self.signature = signature
        self.salt = salt
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        key = try container.decode(WrappedData32.self)
        signature = try container.decode(Data.self)
        salt = try container.decode(WrappedData32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(signature)
        try container.encode(salt)
    }
}

public struct InvokeHostFunctionOpXDR: XDRCodable {
    public var hostFunction: HostFunctionXDR
    public var auth: [SorobanAuthorizationEntryXDR]
    
    public init(hostFunction: HostFunctionXDR, auth: [SorobanAuthorizationEntryXDR]) {
        self.hostFunction = hostFunction
        self.auth = auth
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hostFunction = try container.decode(HostFunctionXDR.self)
        auth = try decodeArray(type: SorobanAuthorizationEntryXDR.self, dec: decoder)
        
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hostFunction)
        try container.encode(auth)
    }
}
