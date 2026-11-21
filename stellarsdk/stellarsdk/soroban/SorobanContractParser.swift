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
public final class SorobanContractParser: Sendable {

    private static let envMetaSectionName = "contractenvmetav0"
    private static let specSectionName = "contractspecv0"
    private static let metaSectionName = "contractmetav0"
    // The wasm binary header, `\0asm` followed by version 1, and the id of a custom section.
    private static let wasmMagic: [UInt8] = [0x00, 0x61, 0x73, 0x6d]
    private static let wasmVersion: [UInt8] = [0x01, 0x00, 0x00, 0x00]
    private static let customSectionId: UInt8 = 0

    /// Parses a soroban contract byteCode to get Environment Meta, Contract Spec and Contract Meta.
    ///
    /// The byte code is read as a wasm module: after the header, every section is walked by its id
    /// and its size. The content of the first `contractenvmetav0` and `contractspecv0` custom
    /// section is decoded as a stream of `SCEnvMetaEntryXDR` and `SCSpecEntryXDR` entries up to the
    /// end of the section; later sections with one of these names do not change the result. The
    /// interface version comes from the first environment meta entry. Every `contractmetav0`
    /// section is decoded on its own as a stream of `SCMetaEntryXDR` entries, and the entries of all
    /// of them are read in module order, as SEP-46 defines. Values with the same metadata key are
    /// joined with a comma. For the `sep` key, this implements SEP-47.
    /// see: [Stellar developer docs](https://developers.stellar.org)
    ///
    /// - Parameter byteCode: The contract wasm.
    /// - Returns: SorobanContractInfo containing the parsed data.
    /// - Throws: `SorobanContractParserError.malformedModule` when the header or the framing of any
    ///   section does not fit the input, `.invalidSectionEntry` when an entry of one of the three
    ///   sections does not decode, has an unknown kind or is cut by the end of its section,
    ///   `.environmentMetaNotFound` when the first `contractenvmetav0` section is absent or empty, and
    ///   `.specEntriesNotFound` when the module has no `contractspecv0` section.
    public static func parseContractByteCode(byteCode:Data) throws -> SorobanContractInfo {
        let bytes = [UInt8](byteCode)
        let sections = try readCustomSections(bytes)
        let envMetaEntries = try sections[envMetaSectionName]?.first.map {
            try decodeEntries(SCEnvMetaEntryXDR.self, section: envMetaSectionName, bytes: bytes, content: $0)
        } ?? []
        guard case .interfaceVersion(let interfaceVersion)? = envMetaEntries.first else {
            throw SorobanContractParserError.environmentMetaNotFound
        }
        guard let specContent = sections[specSectionName]?.first else {
            throw SorobanContractParserError.specEntriesNotFound
        }
        let specEntries = try decodeEntries(SCSpecEntryXDR.self, section: specSectionName, bytes: bytes, content: specContent)
        let metaList = try (sections[metaSectionName] ?? []).flatMap {
            try decodeEntries(SCMetaEntryXDR.self, section: metaSectionName, bytes: bytes, content: $0)
        }
        var metaEntries: [String: String] = [:]
        for case .v0(let meta) in metaList {
            // Values with the same metadata key are joined with a comma. For the `sep` key, this implements SEP-47.
            if let existingValue = metaEntries[meta.key] {
                metaEntries[meta.key] = existingValue + "," + meta.value
            } else {
                metaEntries[meta.key] = meta.value
            }
        }
        return SorobanContractInfo(interfaceVersion: interfaceVersion,
                                   specEntries: specEntries,
                                   metaEntries: metaEntries)
    }

    /// Walks every section of a wasm module and returns, for each section name the parser reads, the
    /// content ranges of the custom sections with that name in module order. The content of a custom
    /// section starts after its name. Sections of the other kinds are skipped by their size, so bytes
    /// inside them never start a section.
    ///
    /// - Throws: `SorobanContractParserError.malformedModule` naming the offset of the malformed field.
    private static func readCustomSections(_ bytes: [UInt8]) throws -> [String: [Range<Int>]] {
        let headerLength = wasmMagic.count + wasmVersion.count
        guard bytes.count >= headerLength else {
            throw malformed(0, "the module has \(bytes.count) bytes, fewer than the \(headerLength) bytes of the wasm header")
        }
        guard bytes[0..<wasmMagic.count].elementsEqual(wasmMagic) else {
            throw malformed(0, "the module does not start with the wasm magic 00 61 73 6d")
        }
        guard bytes[wasmMagic.count..<headerLength].elementsEqual(wasmVersion) else {
            throw malformed(wasmMagic.count, "the wasm version is not 01 00 00 00")
        }
        var sections: [String: [Range<Int>]] = [:]
        var position = headerLength
        while position < bytes.count {
            let sectionStart = position
            position += 1
            let sizeOffset = position
            let size = Int(try readLEB128U32(bytes, at: &position, end: bytes.count, field: "section size"))
            guard size <= bytes.count - position else {
                throw malformed(sizeOffset, "the section at offset \(sectionStart) declares \(size) bytes, but \(bytes.count - position) bytes follow its size")
            }
            let sectionEnd = position + size
            if bytes[sectionStart] == customSectionId {
                let nameLengthOffset = position
                let nameLength = Int(try readLEB128U32(bytes, at: &position, end: sectionEnd, field: "custom section name length"))
                guard nameLength <= sectionEnd - position else {
                    throw malformed(nameLengthOffset, "the custom section at offset \(sectionStart) declares a name of \(nameLength) bytes, but \(sectionEnd - position) bytes of the section follow its name length")
                }
                let name = bytes[position..<position + nameLength]
                if let known = [envMetaSectionName, specSectionName, metaSectionName].first(where: { name.elementsEqual($0.utf8) }) {
                    sections[known, default: []].append(position + nameLength..<sectionEnd)
                }
            }
            position = sectionEnd
        }
        return sections
    }

    /// Reads an unsigned LEB128 value of at most 32 bits, as wasm encodes sizes and lengths: at most
    /// 5 bytes, all before `end`, and the fifth byte holds only the 4 highest bits of the value.
    ///
    /// - Throws: `SorobanContractParserError.malformedModule` naming the offset of the value.
    private static func readLEB128U32(_ bytes: [UInt8], at position: inout Int, end: Int, field: String) throws -> UInt32 {
        let start = position
        var value: UInt32 = 0
        var shift: UInt32 = 0
        var byte: UInt8
        repeat {
            guard position < end else {
                throw malformed(start, "the \(field) at offset \(start) runs past offset \(end)")
            }
            byte = bytes[position]
            position += 1
            if shift == 28 { // the fifth byte
                guard byte & 0x80 == 0 else {
                    throw malformed(start, "the \(field) at offset \(start) is longer than 5 bytes")
                }
                guard byte & 0x70 == 0 else {
                    throw malformed(start, "the \(field) at offset \(start) exceeds 32 bits")
                }
            }
            value |= UInt32(byte & 0x7f) << shift
            shift += 7
        } while byte & 0x80 != 0
        return value
    }

    /// Decodes the content of a custom section as a stream of entries, one after the other, until the
    /// content is consumed. The reader position measures what each entry consumed.
    ///
    /// - Throws: `SorobanContractParserError.invalidSectionEntry` naming the section and the module
    ///   offset of the entry that does not decode.
    private static func decodeEntries<Entry: XDRDecodable>(_ type: Entry.Type, section: String, bytes: [UInt8], content: Range<Int>) throws -> [Entry] {
        let decoder = XDRDecoder(data: Array(bytes[content]))
        var entries: [Entry] = []
        while decoder.remainingBytes > 0 {
            let offset = content.upperBound - decoder.remainingBytes
            do {
                entries.append(try decoder.decode(Entry.self))
            } catch {
                throw SorobanContractParserError.invalidSectionEntry(section: section, offset: offset, message: describe(error))
            }
        }
        return entries
    }

    private static func describe(_ error: Error) -> String {
        switch error {
        case StellarSDKError.xdrDecodingError(let message):
            return message
        case XDRDecoder.Error.invalidUTF8(let bytes):
            return "a string of length \(bytes.count) is not valid UTF-8"
        default:
            return "\(error)"
        }
    }

    private static func malformed(_ offset: Int, _ message: String) -> SorobanContractParserError {
        return .malformedModule(offset: offset, message: message)
    }
}

/// Stores information parsed from a soroban contract byte code such as
/// Environment Meta, Contract Spec Entries and Contract Meta Entries.
/// See also: [Stellar developer docs](https://developers.stellar.org)
public final class SorobanContractInfo: Sendable {

    /// Protocol version the contract was compiled against.
    public let envProtocolVersion:UInt32

    /// Pre-release version (0 for stable releases).
    public let envPreReleaseVersion:UInt32

    /// Raw contract specification entries defining types, functions, and events.
    public let specEntries:[SCSpecEntryXDR]

    /// Key-value metadata entries from the contract's `contractmetav0` custom sections.
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

    /// Creates contract info from the parsed interface version, spec entries, and metadata entries.
    public init(interfaceVersion:SCEnvMetaEntryXDRInterfaceVersionXDR, specEntries:[SCSpecEntryXDR], metaEntries: [String: String]) {
        self.envProtocolVersion = interfaceVersion.`protocol`
        self.envPreReleaseVersion = interfaceVersion.preRelease
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
public enum SorobanContractParserError: Error, Sendable {
    /// The provided byte code is invalid or corrupted.
    case invalidByteCode
    /// The first `contractenvmetav0` section of the byte code is absent or empty.
    case environmentMetaNotFound
    /// The contract specification entries section could not be found in the byte code.
    case specEntriesNotFound
    /// The byte code is not a well-formed wasm module: the header, the size of a section or the
    /// name of a custom section does not fit the input. `offset` is the module offset of the
    /// malformed field and `message` names the values involved.
    case malformedModule(offset: Int, message: String)
    /// An entry of a `contractenvmetav0`, `contractspecv0` or `contractmetav0` section does not
    /// decode: its kind is unknown, a value in it is invalid, or the end of the section cuts it.
    /// `section` names the section, `offset` is the module offset where the entry starts and
    /// `message` names the decoding failure.
    case invalidSectionEntry(section: String, offset: Int, message: String)
}
