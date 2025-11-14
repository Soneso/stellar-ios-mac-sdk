//
//  SorobanContractParser.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.09.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta.
/// see: [Stellar developer docs](https://developers.stellar.org)
public class SorobanContractParser {
    
    /// Parses a soroban contract byteCode to get Environment Meta, Contract Spec and Contract Meta.
    /// see: [Stellar developer docs](https://developers.stellar.org)
    /// Returns SorobanContractInfo containing the parsed data.
    /// Throws SorobanContractParserError if any exception occurred during the byte code parsing. E.g. invalid byte code.
    public static func parseContractByteCode(byteCode:Data) throws -> SorobanContractInfo {
        do {
            if let bytesString = String(data: byteCode, encoding: .isoLatin1) {
                if let xdrEnvMeta = parseEnvironmentMeta(bytesString: bytesString) {
                    switch xdrEnvMeta {
                    case .interfaceVersion(let uInt64):
                        if let specEntries = parseContractSpec(bytesString: bytesString) {
                            let metaEntries = parseMeta(bytesString: bytesString)
                            return SorobanContractInfo(envInterfaceVersion: uInt64,
                                                       specEntries: specEntries,
                                                       metaEntries: metaEntries)
                        } else {
                            throw SorobanContractParserError.specEntriesNotFound
                        }
                    }
                } else {
                    throw SorobanContractParserError.environmentMetaNotFound
                }
            } else {
                throw SorobanContractParserError.invalidByteCode
            }
        } catch let error {
            if error is SorobanContractParserError {
                throw error
            } else {
                throw SorobanContractParserError.invalidByteCode
            }
        }
        
    }
    
    private static func parseEnvironmentMeta(bytesString:String) -> SCEnvMetaEntryXDR? {
        var envMetaBytesStr = slice(input: bytesString, from: "contractenvmetav0", to: "contractenvmetav0")
        if (envMetaBytesStr == nil) {
            envMetaBytesStr = slice(input: bytesString, from: "contractenvmetav0", to: "contractspecv0")
        }
        if (envMetaBytesStr == nil) {
            envMetaBytesStr = end(input: bytesString, from: "contractenvmetav0")
        }
        if let envMetaBytes = envMetaBytesStr?.data(using: .isoLatin1) {
            let xdrDecoder = XDRDecoder.init(data: [UInt8](envMetaBytes))
            return try? SCEnvMetaEntryXDR(from: xdrDecoder)
            
        }
        return nil
    }
    
    private static func parseContractSpec(bytesString:String) -> [SCSpecEntryXDR]? {
        var specBytesStr = slice(input: bytesString, from: "contractspecv0", to: "contractenvmetav0")
        if (specBytesStr == nil) {
            specBytesStr = slice(input: bytesString, from: "contractspecv0", to: "contractspecv0")
        }
        if (specBytesStr == nil) {
            specBytesStr = end(input: bytesString, from: "contractspecv0")
        }
        if (specBytesStr == nil) {
            return nil
        }
        
        var specEntries:[SCSpecEntryXDR] = []
        while !specBytesStr!.isEmpty {
            if let specBytes = specBytesStr?.data(using: .isoLatin1) {
                let xdrDecoder = XDRDecoder.init(data: [UInt8](specBytes))
                if let entry = try? SCSpecEntryXDR(from: xdrDecoder) {
                    specEntries.append(entry)
                    if let enc = try? XDREncoder.encode(entry),
                       let entryBytesString = String(data: Data(enc), encoding: .isoLatin1),
                       let remaining = end(input: specBytesStr!, from: entryBytesString) {
                        specBytesStr = remaining
                        continue
                    }
                }
            }
            break
        }
        
        return specEntries
    }
    
    private static func parseMeta(bytesString:String) -> [String: String] {
        var metaBytesStr = slice(input: bytesString, from: "contractmetav0", to: "contractenvmetav0")
        if (metaBytesStr == nil) {
            metaBytesStr = slice(input: bytesString, from: "contractmetav0", to: "contractspecv0")
        }
        if (metaBytesStr == nil) {
            metaBytesStr = end(input: bytesString, from: "contractmetav0")
        }
        var result: [String: String] = [:]
        if (metaBytesStr == nil) {
            return result
        }
        
        while !metaBytesStr!.isEmpty {
            if let metaBytes = metaBytesStr?.data(using: .isoLatin1) {
                let xdrDecoder = XDRDecoder.init(data: [UInt8](metaBytes))
                if let entry = try? SCMetaEntryXDR(from: xdrDecoder) {
                    switch entry {
                    case .v0(let sCMetaV0XDR):
                        result[sCMetaV0XDR.key] = sCMetaV0XDR.value
                        if let enc = try? XDREncoder.encode(entry),
                           let entryBytesString = String(data: Data(enc), encoding: .isoLatin1),
                           let remaining = end(input: metaBytesStr!, from: entryBytesString) {
                            metaBytesStr = remaining
                            continue
                        }
                    }
                }
            }
            break
        }
        
        return result
    }
    
    private static func slice(input: String, from: String, to: String) -> String? {
        guard let rangeFrom = input.range(of: from)?.upperBound else { return nil }
        guard let rangeTo = input[rangeFrom...].range(of: to)?.lowerBound else { return nil }
        return String(input[rangeFrom..<rangeTo])
    }
    
    private static func end(input: String, from: String) -> String? {
        guard let rangeFrom = input.range(of: from)?.upperBound else { return nil }
        return String(input[rangeFrom...])
    }
}

/// Stores information parsed from a soroban contract byte code such as
/// Environment Meta, Contract Spec Entries and Contract Meta Entries.
/// See also: [Stellar developer docs](https://developers.stellar.org)
public class SorobanContractInfo {

    /// Environment interface version the contract was compiled against.
    public let envInterfaceVersion:UInt64

    /// Raw contract specification entries defining types, functions, and events.
    public let specEntries:[SCSpecEntryXDR]

    /// Key-value metadata entries from the contract's custom section.
    public let metaEntries: [String: String]

    /// List of SEPs (Stellar Ecosystem Proposals) supported by the contract.
    /// Extracted from the "sep" meta entry as defined in SEP-47.
    public let supportedSeps: [String]

    /// Contract functions extracted from spec entries.
    /// Contains all function specifications exported by the contract.
    public let funcs: [SCSpecFunctionV0XDR]

    /// User-defined type structs extracted from spec entries.
    /// Contains all UDT struct specifications exported by the contract.
    public let udtStructs: [SCSpecUDTStructV0XDR]

    /// User-defined type unions extracted from spec entries.
    /// Contains all UDT union specifications exported by the contract.
    public let udtUnions: [SCSpecUDTUnionV0XDR]

    /// User-defined type enums extracted from spec entries.
    /// Contains all UDT enum specifications exported by the contract.
    public let udtEnums: [SCSpecUDTEnumV0XDR]

    /// User-defined type error enums extracted from spec entries.
    /// Contains all UDT error enum specifications exported by the contract.
    public let udtErrorEnums: [SCSpecUDTErrorEnumV0XDR]

    /// Event specifications extracted from spec entries.
    /// Contains all event specifications exported by the contract.
    public let events: [SCSpecEventV0XDR]

    /// Creates contract info from environment interface version, spec entries, and metadata entries.
    public init(envInterfaceVersion:UInt64, specEntries:[SCSpecEntryXDR], metaEntries: [String: String]) {
        self.envInterfaceVersion = envInterfaceVersion
        self.specEntries = specEntries
        self.metaEntries = metaEntries
        self.supportedSeps = SorobanContractInfo.parseSupportedSeps(metaEntries: metaEntries)
        self.funcs = SorobanContractInfo.parseFuncs(specEntries: specEntries)
        self.udtStructs = SorobanContractInfo.parseUdtStructs(specEntries: specEntries)
        self.udtUnions = SorobanContractInfo.parseUdtUnions(specEntries: specEntries)
        self.udtEnums = SorobanContractInfo.parseUdtEnums(specEntries: specEntries)
        self.udtErrorEnums = SorobanContractInfo.parseUdtErrorEnums(specEntries: specEntries)
        self.events = SorobanContractInfo.parseEvents(specEntries: specEntries)
    }

    /// Parses the supported SEPs from the meta entries.
    /// The "sep" meta entry contains a comma-separated list of SEP identifiers.
    /// Duplicates are removed while preserving the order of first appearance.
    private static func parseSupportedSeps(metaEntries: [String: String]) -> [String] {
        guard let sepValue = metaEntries["sep"], !sepValue.isEmpty else {
            return []
        }
        let seps = sepValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        return seps.filter { seen.insert($0).inserted }
    }

    /// Parses contract functions from spec entries.
    private static func parseFuncs(specEntries: [SCSpecEntryXDR]) -> [SCSpecFunctionV0XDR] {
        return specEntries.compactMap { entry in
            if case .functionV0(let functionV0) = entry {
                return functionV0
            }
            return nil
        }
    }

    /// Parses user-defined type structs from spec entries.
    private static func parseUdtStructs(specEntries: [SCSpecEntryXDR]) -> [SCSpecUDTStructV0XDR] {
        return specEntries.compactMap { entry in
            if case .structV0(let structV0) = entry {
                return structV0
            }
            return nil
        }
    }

    /// Parses user-defined type unions from spec entries.
    private static func parseUdtUnions(specEntries: [SCSpecEntryXDR]) -> [SCSpecUDTUnionV0XDR] {
        return specEntries.compactMap { entry in
            if case .unionV0(let unionV0) = entry {
                return unionV0
            }
            return nil
        }
    }

    /// Parses user-defined type enums from spec entries.
    private static func parseUdtEnums(specEntries: [SCSpecEntryXDR]) -> [SCSpecUDTEnumV0XDR] {
        return specEntries.compactMap { entry in
            if case .enumV0(let enumV0) = entry {
                return enumV0
            }
            return nil
        }
    }

    /// Parses user-defined type error enums from spec entries.
    private static func parseUdtErrorEnums(specEntries: [SCSpecEntryXDR]) -> [SCSpecUDTErrorEnumV0XDR] {
        return specEntries.compactMap { entry in
            if case .errorEnumV0(let errorEnumV0) = entry {
                return errorEnumV0
            }
            return nil
        }
    }

    /// Parses event specifications from spec entries.
    private static func parseEvents(specEntries: [SCSpecEntryXDR]) -> [SCSpecEventV0XDR] {
        return specEntries.compactMap { entry in
            if case .eventV0(let eventV0) = entry {
                return eventV0
            }
            return nil
        }
    }
}

/// Thrown if the SorobanContractParser failed parsing the given byte code.
public enum SorobanContractParserError: Error {
    /// The provided byte code is invalid or corrupted.
    case invalidByteCode
    /// The contract environment metadata section could not be found in the byte code.
    case environmentMetaNotFound
    /// The contract specification entries section could not be found in the byte code.
    case specEntriesNotFound
}
