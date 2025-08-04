//
//  ContractSpec.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// The `ContractSpec` class offers a range of useful functions based on the contract spec entries of a contract.
/// It can be used to find specific entries from the contract specification and, more importantly,
/// to easily prepare the arguments to invoke the contract functions.
public class ContractSpec {
    
    /// The spec entries of the contract
    public let entries: [SCSpecEntryXDR]
    
    /// Initialize ContractSpec with spec entries
    /// - Parameter entries: Array of SCSpecEntryXDR objects
    public init(entries: [SCSpecEntryXDR]) {
        self.entries = entries
    }
    
    /// Gets the XDR functions from the spec.
    /// - Returns: Array of SCSpecFunctionV0XDR objects
    public func funcs() -> [SCSpecFunctionV0XDR] {
        var result: [SCSpecFunctionV0XDR] = []
        
        for entry in entries {
            switch entry {
            case .functionV0(let functionV0):
                result.append(functionV0)
            default:
                break
            }
        }
        
        return result
    }
    
    /// Gets the XDR function spec for the given function name if available.
    /// - Parameter name: Name of the function
    /// - Returns: The function spec or nil if not found
    public func getFunc(name: String) -> SCSpecFunctionV0XDR? {
        for entry in entries {
            switch entry {
            case .functionV0(let functionV0):
                if functionV0.name == name {
                    return functionV0
                }
            default:
                break
            }
        }
        return nil
    }
    
    /// Finds the XDR spec entry for the given name.
    /// - Parameter name: The name to find
    /// - Returns: The entry or nil if not found
    public func findEntry(name: String) -> SCSpecEntryXDR? {
        for entry in entries {
            switch entry {
            case .functionV0(let functionV0):
                if functionV0.name == name {
                    return entry
                }
            case .structV0(let structV0):
                if structV0.name == name {
                    return entry
                }
            case .unionV0(let unionV0):
                if unionV0.name == name {
                    return entry
                }
            case .enumV0(let enumV0):
                if enumV0.name == name {
                    return entry
                }
            case .errorEnumV0(let errorEnumV0):
                if errorEnumV0.name == name {
                    return entry
                }
            case .eventV0(_):
                break
            }
        }
        return nil
    }
    
    /// Converts native arguments to SCValXDR values for calling a contract function.
    /// - Parameters:
    ///   - name: Name of the function
    ///   - args: Dictionary of argument names to values
    /// - Returns: Array of SCValXDR objects ordered by position
    /// - Throws: ContractSpecError if function not found or arguments are invalid
    public func funcArgsToXdrSCValues(name: String, args: [String: Any]) throws -> [SCValXDR] {
        guard let function = getFunc(name: name) else {
            throw ContractSpecError.functionNotFound(name: name)
        }
        
        var result: [SCValXDR] = []
        
        for input in function.inputs {
            guard let nativeArg = args[input.name] else {
                throw ContractSpecError.argumentNotFound(name: input.name)
            }
            
            let scVal = try nativeToXdrSCVal(val: nativeArg, ty: input.type)
            result.append(scVal)
        }
        
        return result
    }
    
    /// Converts a native Swift value to an SCValXDR based on the given type.
    /// - Parameters:
    ///   - val: Native Swift value
    ///   - ty: The expected type
    /// - Returns: The converted SCValXDR
    /// - Throws: ContractSpecError if conversion fails
    public func nativeToXdrSCVal(val: Any?, ty: SCSpecTypeDefXDR) throws -> SCValXDR {
        // Handle UDT (User Defined Types)
        switch ty {
        case .udt(let udt):
            return try nativeToUdt(val: val, name: udt.name)
        case .option(let option):
            if val == nil || val is NSNull {
                return SCValXDR.void
            }
            return try nativeToXdrSCVal(val: val, ty: option.valueType)
        case .void:
            if val == nil || val is NSNull {
                return SCValXDR.void
            }
            throw ContractSpecError.invalidType(message: "Type was void but val was not nil")
        default:
            break
        }
        
        // Handle nil for non-void types
        if val == nil || val is NSNull {
            throw ContractSpecError.invalidType(message: "Value was nil but type was not void or option")
        }
        
        // If already SCValXDR, return as is
        if let scVal = val as? SCValXDR {
            return scVal
        }
        
        // Handle arrays
        if let array = val as? [Any] {
            return try handleArrayConversion(array: array, ty: ty)
        }
        
        // Handle dictionaries (for maps and structs)
        if let dict = val as? [AnyHashable: Any] {
            return try handleDictionaryConversion(dict: dict, ty: ty)
        }
        
        // Handle numbers
        if let intVal = val as? Int {
            return try handleIntConversion(intVal: intVal, ty: ty)
        }
        
        // Handle strings
        if let stringVal = val as? String {
            return try handleStringConversion(stringVal: stringVal, ty: ty)
        }
        
        // Handle booleans
        if let boolVal = val as? Bool {
            switch ty {
            case .bool:
                return SCValXDR.bool(boolVal)
            default:
                throw ContractSpecError.invalidType(message: "Invalid type for boolean value")
            }
        }
        
        throw ContractSpecError.conversionFailed(message: "Failed to convert val of type \(type(of: val))")
    }
    
    // MARK: - Private helper methods
    
    private func nativeToUdt(val: Any?, name: String) throws -> SCValXDR {
        guard let entry = findEntry(name: name) else {
            throw ContractSpecError.entryNotFound(name: name)
        }
        
        switch entry {
        case .enumV0(let enumV0):
            guard let intVal = val as? Int else {
                throw ContractSpecError.invalidType(message: "Expected Int for enum \(name), but got \(type(of: val))")
            }
            return try nativeToEnum(val: intVal, enumDef: enumV0)
            
        case .structV0(let structV0):
            return try nativeToStruct(val: val, structDef: structV0)
            
        case .unionV0(let unionV0):
            guard let unionVal = val as? NativeUnionVal else {
                throw ContractSpecError.invalidType(message: "For union \(name), val must be of type NativeUnionVal, got \(type(of: val))")
            }
            return try nativeToUnion(val: unionVal, unionDef: unionV0)
            
        default:
            throw ContractSpecError.invalidType(message: "Failed to parse udt \(name)")
        }
    }
    
    private func nativeToEnum(val: Int, enumDef: SCSpecUDTEnumV0XDR) throws -> SCValXDR {
        for enumCase in enumDef.cases {
            if enumCase.value == UInt32(val) {
                return SCValXDR.u32(UInt32(val))
            }
        }
        throw ContractSpecError.invalidEnumValue(message: "No such enum entry: \(val) in \(enumDef.name)")
    }
    
    private func nativeToStruct(val: Any?, structDef: SCSpecUDTStructV0XDR) throws -> SCValXDR {
        let fields = structDef.fields
        var hasNumeric = false
        var allNumeric = true
        
        // Check if all field names are numeric
        for field in fields {
            if Int(field.name) != nil {
                hasNumeric = true
            } else {
                allNumeric = false
            }
        }
        
        if hasNumeric && !allNumeric {
            throw ContractSpecError.invalidType(message: "Mixed numeric and non-numeric field names are not allowed")
        }
        
        // If all fields are numeric, expect an array
        if allNumeric {
            guard let array = val as? [Any] else {
                throw ContractSpecError.invalidType(message: "Value must be an array for struct \(structDef.name)")
            }
            
            guard array.count == fields.count else {
                throw ContractSpecError.invalidType(message: "Value contains invalid number of entries for struct \(structDef.name)")
            }
            
            var scValues: [SCValXDR] = []
            for (index, field) in fields.enumerated() {
                let scVal = try nativeToXdrSCVal(val: array[index], ty: field.type)
                scValues.append(scVal)
            }
            return SCValXDR.vec(scValues)
        }
        
        // Otherwise, expect a dictionary
        guard let dict = val as? [AnyHashable: Any] else {
            throw ContractSpecError.invalidType(message: "Value must be a dictionary for struct \(structDef.name)")
        }
        
        var mapEntries: [SCMapEntryXDR] = []
        for field in fields {
            let entryKey = try nativeToXdrSCVal(val: field.name, ty: SCSpecTypeDefXDR.symbol)
            guard let fieldValue = dict[field.name] else {
                throw ContractSpecError.argumentNotFound(name: field.name)
            }
            let entryVal = try nativeToXdrSCVal(val: fieldValue, ty: field.type)
            mapEntries.append(SCMapEntryXDR(key: entryKey, val: entryVal))
        }
        
        return SCValXDR.map(mapEntries)
    }
    
    private func nativeToUnion(val: NativeUnionVal, unionDef: SCSpecUDTUnionV0XDR) throws -> SCValXDR {
        let entryName = val.tag
        var caseFound: SCSpecUDTUnionCaseV0XDR?
        
        for unionCase in unionDef.cases {
            switch unionCase {
            case .voidV0(let voidCase):
                if voidCase.name == entryName {
                    caseFound = unionCase
                    break
                }
            case .tupleV0(let tupleCase):
                if tupleCase.name == entryName {
                    caseFound = unionCase
                    break
                }
            }
        }
        
        guard let foundCase = caseFound else {
            throw ContractSpecError.invalidEnumValue(message: "No such union entry: \(entryName) in \(unionDef.name)")
        }
        
        let key = SCValXDR.symbol(entryName)
        
        switch foundCase {
        case .voidV0(_):
            return SCValXDR.vec([key])
            
        case .tupleV0(let tupleCase):
            let types = tupleCase.type
            guard let values = val.values, values.count == types.count else {
                throw ContractSpecError.invalidType(
                    message: "Union \(unionDef.name) expects \(types.count) values, but got \(val.values?.count ?? 0)"
                )
            }
            
            var scValues: [SCValXDR] = [key]
            for (index, value) in values.enumerated() {
                let scVal = try nativeToXdrSCVal(val: value, ty: types[index])
                scValues.append(scVal)
            }
            return SCValXDR.vec(scValues)
        }
    }
    
    private func handleArrayConversion(array: [Any], ty: SCSpecTypeDefXDR) throws -> SCValXDR {
        switch ty {
        case .vec(let vec):
            var scValues: [SCValXDR] = []
            for element in array {
                let scVal = try nativeToXdrSCVal(val: element, ty: vec.elementType)
                scValues.append(scVal)
            }
            return SCValXDR.vec(scValues)
            
        case .tuple(let tuple):
            guard array.count == tuple.valueTypes.count else {
                throw ContractSpecError.invalidType(
                    message: "Tuple expects \(tuple.valueTypes.count) values, but \(array.count) were provided"
                )
            }
            var scValues: [SCValXDR] = []
            for (index, element) in array.enumerated() {
                let scVal = try nativeToXdrSCVal(val: element, ty: tuple.valueTypes[index])
                scValues.append(scVal)
            }
            return SCValXDR.vec(scValues)
            
        default:
            throw ContractSpecError.invalidType(message: "Type was not vec or tuple but val was array")
        }
    }
    
    private func handleDictionaryConversion(dict: [AnyHashable: Any], ty: SCSpecTypeDefXDR) throws -> SCValXDR {
        switch ty {
        case .map(let map):
            var mapEntries: [SCMapEntryXDR] = []
            for (key, value) in dict {
                let mapEntryKey = try nativeToXdrSCVal(val: key, ty: map.keyType)
                let mapEntryValue = try nativeToXdrSCVal(val: value, ty: map.valueType)
                mapEntries.append(SCMapEntryXDR(key: mapEntryKey, val: mapEntryValue))
            }
            return SCValXDR.map(mapEntries)
        default:
            throw ContractSpecError.invalidType(message: "Type was not map but val was dictionary")
        }
    }
    
    private func handleIntConversion(intVal: Int, ty: SCSpecTypeDefXDR) throws -> SCValXDR {
        switch ty {
        case .u32:
            guard intVal >= 0 else {
                throw ContractSpecError.invalidType(message: "Negative integer value provided for u32")
            }
            return SCValXDR.u32(UInt32(intVal))
            
        case .i32:
            return SCValXDR.i32(Int32(intVal))
            
        case .u64:
            guard intVal >= 0 else {
                throw ContractSpecError.invalidType(message: "Negative integer value provided for u64")
            }
            return SCValXDR.u64(UInt64(intVal))
            
        case .i64:
            return SCValXDR.i64(Int64(intVal))
            
        case .u128:
            guard intVal >= 0 else {
                throw ContractSpecError.invalidType(message: "Negative integer value provided for u128")
            }
            return SCValXDR.u128(UInt128PartsXDR(hi: 0, lo: UInt64(intVal)))
            
        case .i128:
            guard intVal >= 0 else {
                throw ContractSpecError.invalidType(message: "Negative integer value provided for i128")
            }
            return SCValXDR.i128(Int128PartsXDR(hi: 0, lo: UInt64(intVal)))
            
        case .u256:
            guard intVal >= 0 else {
                throw ContractSpecError.invalidType(message: "Negative integer value provided for u256")
            }
            return SCValXDR.u256(UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: UInt64(intVal)))
            
        case .i256:
            guard intVal >= 0 else {
                throw ContractSpecError.invalidType(message: "Negative integer value provided for i256")
            }
            return SCValXDR.i256(Int256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: UInt64(intVal)))
            
        default:
            throw ContractSpecError.invalidType(message: "Invalid type for val of type int")
        }
    }
    
    private func handleStringConversion(stringVal: String, ty: SCSpecTypeDefXDR) throws -> SCValXDR {
        switch ty {
        case .bytes, .bytesN(_):
            guard let data = stringVal.data(using: .utf8) else {
                throw ContractSpecError.conversionFailed(message: "Failed to convert string to bytes")
            }
            return SCValXDR.bytes(data)
            
        case .string:
            return SCValXDR.string(stringVal)
            
        case .symbol:
            return SCValXDR.symbol(stringVal)
            
        case .address:
            let address: SCAddressXDR
            if stringVal.hasPrefix("C") {
                address = try SCAddressXDR(contractId: stringVal)
            } else {
                address = try SCAddressXDR(accountId: stringVal)
            }
            return SCValXDR.address(address)
            
        default:
            throw ContractSpecError.invalidType(message: "Invalid type for val of type string")
        }
    }
}

/// Errors that can occur when working with ContractSpec
public enum ContractSpecError: Error {
    case functionNotFound(name: String)
    case argumentNotFound(name: String)
    case entryNotFound(name: String)
    case invalidType(message: String)
    case conversionFailed(message: String)
    case invalidEnumValue(message: String)
}
