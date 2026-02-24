// This file is hand-written because the XDR spec changed SCEnvMetaEntry's
// interface_version from a single uint64 to a struct with two uint32 fields.
// The SDK preserves the original UInt64 API for backward compatibility.

import Foundation

public enum SCEnvMetaEntryXDR: XDRCodable, Sendable {
    case interfaceVersion (UInt64)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(Int32.self)

        switch type {
        default:
            let version = try container.decode(UInt64.self)
            self = .interfaceVersion(version)
        }
    }

    public func type() -> Int32 {
        switch self {
        case .interfaceVersion: return SCEnvMetaKind.interfaceVersion.rawValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())

        switch self {
        case .interfaceVersion (let version):
            try container.encode(version)
        }
    }
}
