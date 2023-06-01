//
//  ContractEventXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum ContractEventType: Int32 {
    case system = 0
    case contract = 1
    case diagnostic = 2
}

public struct ContractEventXDR: XDRCodable {
    public var ext: ExtensionPoint
    public var hash: WrappedData32?
    public var type: Int32 //ContractEventType
    public var body: ContractEventBodyXDR
    
    public init(ext:ExtensionPoint, hash:WrappedData32? = nil, type:Int32, body:ContractEventBodyXDR) {
        self.ext = ext
        self.hash = hash
        self.type = type
        self.body = body
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        let hashPresent = try container.decode(UInt32.self)
        if hashPresent != 0 {
            self.hash = try container.decode(WrappedData32.self)
        }
        type = try container.decode(Int32.self)
        body = try container.decode(ContractEventBodyXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        if let hash = hash {
            let flag: Int32 = 1
            try container.encode(flag)
            try container.encode(hash)
        } else {
            let flag: Int32 = 0
            try container.encode(flag)
        }
        
        try container.encode(type)
        try container.encode(body)
    }
}

public struct ContractEventBodyV0XDR: XDRCodable {
    public var topics: [SCValXDR]
    public var data: SCValXDR
    
    public init(topics:[SCValXDR], data:SCValXDR) {
        self.topics = topics
        self.data = data
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        topics = try decodeArray(type: SCValXDR.self, dec: decoder)
        data = try container.decode(SCValXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(topics)
        try container.encode(data)
    }
}

public enum ContractEventBodyXDR: XDRCodable {
    case v0 (ContractEventBodyV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(Int32.self)
        
        switch type {
        default:
            let v0 = try container.decode(ContractEventBodyV0XDR.self)
            self = .v0(v0)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .v0: return 0
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .v0 (let val):
            try container.encode(val)
        }
    }
}

public struct OperationDiagnosticEventsXDR: XDRCodable {
    public var events: [DiagnosticEventXDR]
    
    public init(events: [DiagnosticEventXDR]) {
        self.events = events
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        events = try decodeArray(type: DiagnosticEventXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(events)
    }
}


public struct DiagnosticEventXDR: XDRCodable {
    public var inSuccessfulContractCall: Bool
    public var event: ContractEventXDR
    
    public init(inSuccessfulContractCall:Bool, event:ContractEventXDR) {
        self.inSuccessfulContractCall = inSuccessfulContractCall
        self.event = event
    }

    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try DiagnosticEventXDR(from: xdrDecoder)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        inSuccessfulContractCall = try container.decode(Bool.self)
        event = try container.decode(ContractEventXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(inSuccessfulContractCall)
        try container.encode(event)
    }
}
