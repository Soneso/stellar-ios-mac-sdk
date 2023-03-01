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
    case u32 = 1
    case i32 = 2
    case u64 = 3
    case i64 = 4
    case u128 = 5
    case i128 = 6
    case bool = 7
    case symbol = 8
    case bitset = 9
    case status = 10
    case bytes = 11
    case invoker = 12
    case address = 13
    
    // Types with parameters
    case option = 1000
    case result = 1001
    case vec = 1002
    case set = 1003
    case map = 1004
    case tuple = 1005
    case bytesN = 1006
    
    // User defined types.
    case udt = 2000
}

public struct SCSpecTypeOptionXDR: XDRCodable {
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

public struct SCSpecTypeResultXDR: XDRCodable {
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

public struct SCSpecTypeVecXDR: XDRCodable {
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

public struct SCSpecTypeMapXDR: XDRCodable {
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

public struct SCSpecTypeSetXDR: XDRCodable {
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

public struct SCSpecTypeBytesNXDR: XDRCodable {
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


public struct SCSpecTypeTupleXDR: XDRCodable {
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

public struct SCSpecTypeUDTXDR: XDRCodable {
    public let name: [String]
    
    public init(name:[String]) {
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        name = try decodeArray(type: String.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(name)
    }
}

public indirect enum SCSpecTypeDefXDR: XDRCodable {

    case val
    case u64
    case i64
    case u128
    case i128
    case u32
    case i32
    case bool
    case symbol
    case bitset
    case status
    case bytes
    case invoker
    case address
    case option(SCSpecTypeOptionXDR)
    case result(SCSpecTypeResultXDR)
    case vec(SCSpecTypeVecXDR)
    case map(SCSpecTypeMapXDR)
    case set(SCSpecTypeSetXDR)
    case tuple(SCSpecTypeTupleXDR)
    case bytesN(SCSpecTypeBytesNXDR)
    case udt(SCSpecTypeUDTXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCSpecType(rawValue: discriminant)!
        
        switch type {
        case .u64:
            self = .u64
        case .i64:
            self = .i64
        case .u128:
            self = .u128
        case .i128:
            self = .i128
        case .u32:
            self = .u32
        case .i32:
            self = .i32
        case .bool:
            self = .bool
        case .symbol:
            self = .symbol
        case .bitset:
            self = .bitset
        case .status:
            self = .status
        case .bytes:
            self = .bytes
        case .invoker:
            self = .invoker
        case .address:
            self = .address
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
        case .set:
            let set = try container.decode(SCSpecTypeSetXDR.self)
            self = .set(set)
        case .tuple:
            let tuple = try container.decode(SCSpecTypeTupleXDR.self)
            self = .tuple(tuple)
        case .bytesN:
            let bytesN = try container.decode(SCSpecTypeBytesNXDR.self)
            self = .bytesN(bytesN)
        case .udt:
            let udt = try container.decode(SCSpecTypeUDTXDR.self)
            self = .udt(udt)
        default:
            self = .val
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .val: return SCSpecType.val.rawValue
        case .u64: return SCSpecType.u64.rawValue
        case .i64: return SCSpecType.i64.rawValue
        case .u128: return SCSpecType.u128.rawValue
        case .i128: return SCSpecType.i128.rawValue
        case .u32: return SCSpecType.u32.rawValue
        case .i32: return SCSpecType.i32.rawValue
        case .bool: return SCSpecType.bool.rawValue
        case .symbol: return SCSpecType.symbol.rawValue
        case .bitset: return SCSpecType.bitset.rawValue
        case .status: return SCSpecType.status.rawValue
        case .bytes: return SCSpecType.bytes.rawValue
        case .invoker: return SCSpecType.invoker.rawValue
        case .address: return SCSpecType.address.rawValue
        case .option: return SCSpecType.option.rawValue
        case .result: return SCSpecType.result.rawValue
        case .vec: return SCSpecType.vec.rawValue
        case .map: return SCSpecType.map.rawValue
        case .set: return SCSpecType.set.rawValue
        case .tuple: return SCSpecType.tuple.rawValue
        case .bytesN: return SCSpecType.bytesN.rawValue
        case .udt: return SCSpecType.udt.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .val:
            break
        case .u64:
            break
        case .i64:
            break
        case .u128:
            break
        case .i128:
            break
        case .u32:
            break
        case .i32:
            break
        case .bool:
            break
        case .symbol:
            break
        case .bitset:
            break
        case .status:
            break
        case .bytes:
            break
        case .invoker:
            break
        case .address:
            break
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
        case .set (let set):
            try container.encode(set)
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
        }
    }
}

public struct SCSpecUDTStructFieldV0XDR: XDRCodable {
    public let doc: String
    public let name: [String]
    public let type: SCSpecTypeDefXDR
    
    public init(doc: String, name:[String], type:SCSpecTypeDefXDR) {
        self.doc = doc
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try decodeArray(type: String.self, dec: decoder)
        type = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(type)
    }
}

public struct SCSpecUDTStructV0XDR: XDRCodable {
    public let doc: String
    public let lib: [String]
    public let name: [String]
    public let fields: [SCSpecUDTStructFieldV0XDR]
    
    public init(doc:String, lib:[String], name:[String], fields:[SCSpecUDTStructFieldV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.fields = fields
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try decodeArray(type: String.self, dec: decoder)
        name = try decodeArray(type: String.self, dec: decoder)
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

public struct SCSpecUDTUnionCaseVoidV0XDR: XDRCodable {
    public let doc: String
    public let name: [String]
    
    public init(doc: String, name:[String]) {
        self.doc = doc
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try decodeArray(type: String.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
    }
}

public struct SCSpecUDTUnionCaseTupleV0XDR: XDRCodable {
    public let doc: String
    public let name: [String]
    public let type: SCSpecTypeDefXDR
    
    public init(doc: String, name:[String], type:SCSpecTypeDefXDR) {
        self.doc = doc
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try decodeArray(type: String.self, dec: decoder)
        type = try container.decode(SCSpecTypeDefXDR.self)
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

public enum SCSpecUDTUnionCaseV0XDR: XDRCodable {

    case voidV0(SCSpecUDTUnionCaseVoidV0XDR)
    case tupleV0(SCSpecUDTUnionCaseTupleV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let kind = SCSpecUDTUnionCaseV0Kind(rawValue: discriminant)!
        
        switch kind {
        case .voidV0:
            let voidV0 = try container.decode(SCSpecUDTUnionCaseVoidV0XDR.self)
            self = .voidV0(voidV0)
        case .tupleV0:
            let tupleV0 = try container.decode(SCSpecUDTUnionCaseTupleV0XDR.self)
            self = .tupleV0(tupleV0)
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

public struct SCSpecUDTUnionV0XDR: XDRCodable {
    public let doc: String
    public let lib: [String]
    public let name: [String]
    public let cases: [SCSpecUDTUnionCaseV0XDR]
    
    public init(doc: String, lib:[String], name:[String], cases:[SCSpecUDTUnionCaseV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.cases = cases
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try decodeArray(type: String.self, dec: decoder)
        name = try decodeArray(type: String.self, dec: decoder)
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

public struct SCSpecUDTEnumCaseV0XDR: XDRCodable {
    public let doc: String
    public let name: [String]
    public let value: UInt32
    
    public init(doc: String, name:[String], value:UInt32) {
        self.doc = doc
        self.name = name
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try decodeArray(type: String.self, dec: decoder)
        value = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(value)
    }
}

public struct SCSpecUDTEnumV0XDR: XDRCodable {
    public let doc: String
    public let lib: [String]
    public let name: [String]
    public let cases: [SCSpecUDTEnumCaseV0XDR]
    
    public init(doc: String, lib:[String], name:[String], cases:[SCSpecUDTEnumCaseV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.cases = cases
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try decodeArray(type: String.self, dec: decoder)
        name = try decodeArray(type: String.self, dec: decoder)
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

public struct SCSpecUDTErrorEnumV0XDR: XDRCodable {
    public let doc: String
    public let lib: [String]
    public let name: [String]
    public let cases: [SCSpecUDTEnumCaseV0XDR]
    
    public init(doc: String, lib:[String], name:[String], cases:[SCSpecUDTEnumCaseV0XDR]) {
        self.doc = doc
        self.lib = lib
        self.name = name
        self.cases = cases
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        lib = try decodeArray(type: String.self, dec: decoder)
        name = try decodeArray(type: String.self, dec: decoder)
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

public struct SCSpecFunctionInputV0XDR: XDRCodable {
    public let doc: String
    public let name: [String]
    public let type: SCSpecTypeDefXDR
    
    public init(doc: String, name:[String], type:SCSpecTypeDefXDR) {
        self.doc = doc
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        doc = try container.decode(String.self)
        name = try decodeArray(type: String.self, dec: decoder)
        type = try container.decode(SCSpecTypeDefXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(doc)
        try container.encode(name)
        try container.encode(type)
    }
}

public struct SCSpecFunctionV0XDR: XDRCodable {
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

public enum SCSpecEntryKind: Int32 {
    case functionV0 = 0
    case structV0 = 1
    case unionV0 = 2
    case enumV0 = 3
    case errorEnumV0 = 4
}

public enum SCSpecEntryXDR: XDRCodable {

    case functionV0(SCSpecFunctionV0XDR)
    case structV0(SCSpecUDTStructV0XDR)
    case unionV0(SCSpecUDTUnionV0XDR)
    case enumV0(SCSpecUDTEnumV0XDR)
    case errorEnumV0(SCSpecUDTErrorEnumV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let kind = SCSpecEntryKind(rawValue: discriminant)!
        
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
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .functionV0: return SCSpecEntryKind.functionV0.rawValue
        case .structV0: return SCSpecEntryKind.structV0.rawValue
        case .unionV0: return SCSpecEntryKind.unionV0.rawValue
        case .enumV0: return SCSpecEntryKind.enumV0.rawValue
        case .errorEnumV0: return SCSpecEntryKind.errorEnumV0.rawValue
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
        }
    }
}
