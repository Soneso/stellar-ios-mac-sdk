//
//  SorobanContractParser.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.09.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta.
/// see: https://developers.stellar.org/docs/tools/sdks/build-your-own
public class SorobanContractParser {
    
    /// Parses a soroban contract byteCode to get Environment Meta, Contract Spec and Contract Meta.
    /// see: https://developers.stellar.org/docs/tools/sdks/build-your-own
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
/// See also: https://developers.stellar.org/docs/tools/sdks/build-your-own
public class SorobanContractInfo {
    public let envInterfaceVersion:UInt64
    public let specEntries:[SCSpecEntryXDR]
    public let metaEntries: [String: String]

    /// List of SEPs (Stellar Ecosystem Proposals) supported by the contract.
    /// Extracted from the "sep" meta entry as defined in SEP-47.
    public let supportedSeps: [String]

    public init(envInterfaceVersion:UInt64, specEntries:[SCSpecEntryXDR], metaEntries: [String: String]) {
        self.envInterfaceVersion = envInterfaceVersion
        self.specEntries = specEntries
        self.metaEntries = metaEntries
        self.supportedSeps = SorobanContractInfo.parseSupportedSeps(metaEntries: metaEntries)
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
}

/// Thrown if the SorobanContractParser failed parsing the given byte code.
public enum SorobanContractParserError: Error {
    case invalidByteCode
    case environmentMetaNotFound
    case specEntriesNotFound
}
