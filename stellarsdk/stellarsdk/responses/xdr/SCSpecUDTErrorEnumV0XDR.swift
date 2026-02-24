// This file is hand-written because the XDR spec uses SCSpecUDTErrorEnumCaseV0
// for the cases field, but the SDK uses SCSpecUDTEnumCaseV0XDR for backward
// compatibility (both types have the same wire format).

import Foundation

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
