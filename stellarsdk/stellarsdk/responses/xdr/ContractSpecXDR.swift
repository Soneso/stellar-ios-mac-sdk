//
//  ContractSpecXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCSpecType: Int32 {
    case val = 0
    case bool = 1
    case void = 2
    case error = 3
    case u32 = 4
    case i32 = 5
    case u64 = 6
    case i64 = 7
    case timepoint = 8
    case duration = 9
    case u128 = 10
    case i128 = 11
    case u256 = 12
    case i256 = 13
    case bytes = 14
    case string = 16
    case symbol = 17
    case address = 19
    case muxedAddress = 20
    
    // Types with parameters
    case option = 1000
    case result = 1001
    case vec = 1002
    case map = 1004
    case tuple = 1005
    case bytesN = 1006
    
    // User defined types.
    case udt = 2000
}

public struct SCSpecTypeOptionXDR: XDRCodable, Sendable {
    public let valueType: SCSpecTypeDefXDR
    
    public init(valueType:SCSpecTypeDefXDR) {
        self.valueType = valueType
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        valueType = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(valueType)
    }
}

public struct SCSpecTypeResultXDR: XDRCodable, Sendable {
    public let okType: SCSpecTypeDefXDR
    public let errorType: SCSpecTypeDefXDR
    
    public init(okType:SCSpecTypeDefXDR, errorType:SCSpecTypeDefXDR) {
        self.okType = okType
        self.errorType = errorType
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        okType = try container.decode(SCSpecTypeDefXDR.self)
        errorType = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(okType)
        try container.encode(errorType)
    }
}

public struct SCSpecTypeVecXDR: XDRCodable, Sendable {
    public let elementType: SCSpecTypeDefXDR
    
    public init(elementType:SCSpecTypeDefXDR) {
        self.elementType = elementType
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        elementType = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(elementType)
    }
}

public struct SCSpecTypeMapXDR: XDRCodable, Sendable {
    public let keyType: SCSpecTypeDefXDR
    public let valueType: SCSpecTypeDefXDR
    
    public init(keyType:SCSpecTypeDefXDR, valueType:SCSpecTypeDefXDR) {
        self.keyType = keyType
        self.valueType = valueType
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        keyType = try container.decode(SCSpecTypeDefXDR.self)
        valueType = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(keyType)
        try container.encode(valueType)
    }
}

public struct SCSpecTypeBytesNXDR: XDRCodable, Sendable {
    public let n: UInt32
    
    public init(n:UInt32) {
        self.n = n
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        n = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(n)
    }
}


public struct SCSpecTypeTupleXDR: XDRCodable, Sendable {
    public let valueTypes: [SCSpecTypeDefXDR]
    
    public init(valueTypes:[SCSpecTypeDefXDR]) {
        self.valueTypes = valueTypes
    }

    public init(from decoder: Decoder) throws {
        //var container = try decoder.unkeyedContainer()
        valueTypes = try decodeArray(type: SCSpecTypeDefXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(valueTypes)
    }
}

public struct SCSpecTypeUDTXDR: XDRCodable, Sendable {
    public let name: String
    
    public init(name:String) {
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        name = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(name)
    }
}

public indirect enum SCSpecTypeDefXDR: XDRCodable, Sendable {

    case val
    case bool
    case void
    case error
    case u32
    case i32
    case u64
    case i64
    case timepoint
    case duration
    case u128
    case i128
    case u256
    case i256
    case bytes
    case string
    case symbol
    case address
    case muxedAddress
    case option(SCSpecTypeOptionXDR)
    case result(SCSpecTypeResultXDR)
    case vec(SCSpecTypeVecXDR)
    case map(SCSpecTypeMapXDR)
    case tuple(SCSpecTypeTupleXDR)
    case bytesN(SCSpecTypeBytesNXDR)
    case udt(SCSpecTypeUDTXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCSpecType(rawValue: discriminant)
        
        switch type {
        case .bool:
            self = .bool
        case .void:
            self = .void
        case .error:
            self = .error
        case .u32:
            self = .u32
        case .i32:
            self = .i32
        case .u64:
            self = .u64
        case .i64:
            self = .i64
        case .timepoint:
            self = .timepoint
        case .duration:
            self = .duration
        case .u128:
            self = .u128
        case .i128:
            self = .i128
        case .u256:
            self = .u256
        case .i256:
            self = .i256
        case .bytes:
            self = .bytes
        case .string:
            self = .string
        case .symbol:
            self = .symbol
        case .address:
            self = .address
        case .muxedAddress:
            self = .muxedAddress
        case .option:
            let option = try container.decode(SCSpecTypeOptionXDR.self)
            self = .option(option)
        case .result:
            let result = try container.decode(SCSpecTypeResultXDR.self)
            self = .result(result)
        case .vec:
            let vec = try container.decode(SCSpecTypeVecXDR.self)
            self = .vec(vec)
        case .map:
            let map = try container.decode(SCSpecTypeMapXDR.self)
            self = .map(map)
        case .tuple:
            let tuple = try container.decode(SCSpecTypeTupleXDR.self)
            self = .tuple(tuple)
        case .bytesN:
            let bytesN = try container.decode(SCSpecTypeBytesNXDR.self)
            self = .bytesN(bytesN)
        case .udt:
            let udt = try container.decode(SCSpecTypeUDTXDR.self)
            self = .udt(udt)
        case .val:
            self = .val
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCSpecTypeDefXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .val: return SCSpecType.val.rawValue
        case .bool: return SCSpecType.bool.rawValue
        case .void: return SCSpecType.bool.rawValue
        case .error: return SCSpecType.error.rawValue
        case .u32: return SCSpecType.u32.rawValue
        case .i32: return SCSpecType.i32.rawValue
        case .u64: return SCSpecType.u64.rawValue
        case .i64: return SCSpecType.i64.rawValue
        case .timepoint: return SCSpecType.timepoint.rawValue
        case .duration: return SCSpecType.duration.rawValue
        case .u128: return SCSpecType.u128.rawValue
        case .i128: return SCSpecType.i128.rawValue
        case .u256: return SCSpecType.u256.rawValue
        case .i256: return SCSpecType.i256.rawValue
        case .bytes: return SCSpecType.bytes.rawValue
        case .string: return SCSpecType.string.rawValue
        case .symbol: return SCSpecType.symbol.rawValue
        case .address: return SCSpecType.address.rawValue
        case .muxedAddress: return SCSpecType.muxedAddress.rawValue
        case .option: return SCSpecType.option.rawValue
        case .result: return SCSpecType.result.rawValue
        case .vec: return SCSpecType.vec.rawValue
        case .map: return SCSpecType.map.rawValue
        case .tuple: return SCSpecType.tuple.rawValue
        case .bytesN: return SCSpecType.bytesN.rawValue
        case .udt: return SCSpecType.udt.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .option (let option):
            try container.encode(option)
            break
        case .result (let result):
            try container.encode(result)
            break
        case .vec (let vec):
            try container.encode(vec)
            break
        case .map (let map):
            try container.encode(map)
            break
        case .tuple (let tuple):
            try container.encode(tuple)
            break
        case .bytesN (let bytesN):
            try container.encode(bytesN)
            break
        case .udt (let udt):
            try container.encode(udt)
            break
        default:
            break
        }
    }
}

public struct SCSpecUDTStructFieldV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    public let type: SCSpecTypeDefXDR
    
    public init(doc: String, name:String, type:SCSpecTypeDefXDR) {
        self.doc = doc
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
        type = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(type)
    }
}

public struct SCSpecUDTStructV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let lib: String
    public let name: String
    public let fields: [SCSpecUDTStructFieldV0XDR]
    
    public init(doc:String, lib:String, name:String, fields:[SCSpecUDTStructFieldV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.fields = fields
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try container.decode(String.self)
        name = try container.decode(String.self)
        fields = try decodeArray(type: SCSpecUDTStructFieldV0XDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(lib)
        try container.encode(name)
        try container.encode(fields)
    }
}

public struct SCSpecUDTUnionCaseVoidV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    
    public init(doc: String, name:String) {
        self.doc = doc
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
    }
}

public struct SCSpecUDTUnionCaseTupleV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    public let type: [SCSpecTypeDefXDR]
    
    public init(doc: String, name:String, type:[SCSpecTypeDefXDR]) {
        self.doc = doc
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
        type = try decodeArray(type: SCSpecTypeDefXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(type)
    }
}

public enum SCSpecUDTUnionCaseV0Kind: Int32 {
    case voidV0 = 0
    case tupleV0 = 1
}

public enum SCSpecUDTUnionCaseV0XDR: XDRCodable, Sendable {

    case voidV0(SCSpecUDTUnionCaseVoidV0XDR)
    case tupleV0(SCSpecUDTUnionCaseTupleV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let kind = SCSpecUDTUnionCaseV0Kind(rawValue: discriminant)
        
        switch kind {
        case .voidV0:
            let voidV0 = try container.decode(SCSpecUDTUnionCaseVoidV0XDR.self)
            self = .voidV0(voidV0)
        case .tupleV0:
            let tupleV0 = try container.decode(SCSpecUDTUnionCaseTupleV0XDR.self)
            self = .tupleV0(tupleV0)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCSpecUDTUnionCaseV0Kind discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .voidV0: return SCSpecUDTUnionCaseV0Kind.voidV0.rawValue
        case .tupleV0: return SCSpecUDTUnionCaseV0Kind.tupleV0.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .voidV0 (let voidV0):
            try container.encode(voidV0)
            break
        case .tupleV0 (let tupleV0):
            try container.encode(tupleV0)
            break
        }
    }
}

public struct SCSpecUDTUnionV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let lib: String
    public let name: String
    public let cases: [SCSpecUDTUnionCaseV0XDR]
    
    public init(doc: String, lib:String, name:String, cases:[SCSpecUDTUnionCaseV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.cases = cases
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try container.decode(String.self)
        name = try container.decode(String.self)
        cases = try decodeArray(type: SCSpecUDTUnionCaseV0XDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(lib)
        try container.encode(name)
        try container.encode(cases)
    }
}

public struct SCSpecUDTEnumCaseV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    public let value: UInt32
    
    public init(doc: String, name:String, value:UInt32) {
        self.doc = doc
        self.name = name
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
        value = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(value)
    }
}

public struct SCSpecUDTEnumV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let lib: String
    public let name: String
    public let cases: [SCSpecUDTEnumCaseV0XDR]
    
    public init(doc: String, lib:String, name:String, cases:[SCSpecUDTEnumCaseV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.cases = cases
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try container.decode(String.self)
        name = try container.decode(String.self)
        cases = try decodeArray(type: SCSpecUDTEnumCaseV0XDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(lib)
        try container.encode(name)
        try container.encode(cases)
    }
}

public struct SCSpecUDTErrorEnumV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let lib: String
    public let name: String
    public let cases: [SCSpecUDTEnumCaseV0XDR]
    
    public init(doc: String, lib:String, name:String, cases:[SCSpecUDTEnumCaseV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.cases = cases
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try container.decode(String.self)
        name = try container.decode(String.self)
        cases = try decodeArray(type: SCSpecUDTEnumCaseV0XDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(lib)
        try container.encode(name)
        try container.encode(cases)
    }
}

public struct SCSpecFunctionInputV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    public let type: SCSpecTypeDefXDR
    
    public init(doc: String, name:String, type:SCSpecTypeDefXDR) {
        self.doc = doc
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
        type = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(type)
    }
}

public struct SCSpecFunctionV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    public let inputs: [SCSpecFunctionInputV0XDR]
    public let outputs: [SCSpecTypeDefXDR]
    
    public init(doc: String, name:String, inputs:[SCSpecFunctionInputV0XDR], outputs:[SCSpecTypeDefXDR]) {
        self.doc = doc
        self.name = name
        self.inputs = inputs
        self.outputs = outputs
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
        inputs = try decodeArray(type: SCSpecFunctionInputV0XDR.self, dec: decoder)
        outputs = try decodeArray(type: SCSpecTypeDefXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(inputs)
        try container.encode(outputs)
    }
}

public struct SCSpecEventV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let lib: String
    public let name: String
    public let prefixTopics: [String]
    public let params: [SCSpecEventParamV0XDR]
    public let dataFormat: SCSpecEventDataFormat
    
    public init(doc: String, lib:String, name:String, prefixTopics:[String], params:[SCSpecEventParamV0XDR], dataFormat:SCSpecEventDataFormat) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.prefixTopics = prefixTopics
        self.params = params
        self.dataFormat = dataFormat
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try container.decode(String.self)
        name = try container.decode(String.self)
        prefixTopics = try decodeArray(type: String.self, dec: decoder)
        params = try decodeArray(type: SCSpecEventParamV0XDR.self, dec: decoder)
        let discriminant = try container.decode(Int32.self)
        guard let decodedDataFormat = SCSpecEventDataFormat(rawValue: discriminant) else {
            throw StellarSDKError.decodingError(message: "unknown SCSpecEventDataFormat value: \(discriminant)")
        }
        dataFormat = decodedDataFormat
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(lib)
        try container.encode(name)
        try container.encode(prefixTopics)
        try container.encode(params)
        try container.encode(dataFormat.rawValue)
    }
}

public enum SCSpecEventDataFormat: Int32, Sendable {
    case singleValue = 0
    case vec = 1
    case map = 2
}

public enum SCSpecEventParamLocationV0: Int32, Sendable {
    case data = 0
    case topicList = 1
}

public struct SCSpecEventParamV0XDR: XDRCodable, Sendable {
    public let doc: String
    public let name: String
    public let type: SCSpecTypeDefXDR
    public let location: SCSpecEventParamLocationV0
    
    public init(doc: String, name:String, type:SCSpecTypeDefXDR, location:SCSpecEventParamLocationV0) {
        self.doc = doc
        self.name = name
        self.type = type
        self.location = location
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try container.decode(String.self)
        type = try container.decode(SCSpecTypeDefXDR.self)
        let discriminant = try container.decode(Int32.self)
        guard let decodedLocation = SCSpecEventParamLocationV0(rawValue: discriminant) else {
            throw StellarSDKError.decodingError(message: "unknown SCSpecEventParamLocationV0 value: \(discriminant)")
        }
        location = decodedLocation
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(type)
        try container.encode(location.rawValue)
    }
}

public enum SCSpecEntryKind: Int32 {
    case functionV0 = 0
    case structV0 = 1
    case unionV0 = 2
    case enumV0 = 3
    case errorEnumV0 = 4
    case entryEventV0 = 5
}

public enum SCSpecEntryXDR: XDRCodable, Sendable {

    case functionV0(SCSpecFunctionV0XDR)
    case structV0(SCSpecUDTStructV0XDR)
    case unionV0(SCSpecUDTUnionV0XDR)
    case enumV0(SCSpecUDTEnumV0XDR)
    case errorEnumV0(SCSpecUDTErrorEnumV0XDR)
    case eventV0(SCSpecEventV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let kind = SCSpecEntryKind(rawValue: discriminant)
        
        switch kind {
        case .functionV0:
            let functionV0 = try container.decode(SCSpecFunctionV0XDR.self)
            self = .functionV0(functionV0)
        case .structV0:
            let structV0 = try container.decode(SCSpecUDTStructV0XDR.self)
            self = .structV0(structV0)
        case .unionV0:
            let unionV0 = try container.decode(SCSpecUDTUnionV0XDR.self)
            self = .unionV0(unionV0)
        case .enumV0:
            let enumV0 = try container.decode(SCSpecUDTEnumV0XDR.self)
            self = .enumV0(enumV0)
        case .errorEnumV0:
            let errorEnumV0 = try container.decode(SCSpecUDTErrorEnumV0XDR.self)
            self = .errorEnumV0(errorEnumV0)
        case .entryEventV0:
            let eventV0 = try container.decode(SCSpecEventV0XDR.self)
            self = .eventV0(eventV0)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCSpecEntryXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .functionV0: return SCSpecEntryKind.functionV0.rawValue
        case .structV0: return SCSpecEntryKind.structV0.rawValue
        case .unionV0: return SCSpecEntryKind.unionV0.rawValue
        case .enumV0: return SCSpecEntryKind.enumV0.rawValue
        case .errorEnumV0: return SCSpecEntryKind.errorEnumV0.rawValue
        case .eventV0: return SCSpecEntryKind.entryEventV0.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .functionV0 (let functionV0):
            try container.encode(functionV0)
            break
        case .structV0 (let structV0):
            try container.encode(structV0)
            break
        case .unionV0 (let unionV0):
            try container.encode(unionV0)
            break
        case .enumV0 (let enumV0):
            try container.encode(enumV0)
            break
        case .errorEnumV0 (let errorEnumV0):
            try container.encode(errorEnumV0)
            break
        case .eventV0 (let eventV0):
            try container.encode(eventV0)
            break
        }
    }
}
