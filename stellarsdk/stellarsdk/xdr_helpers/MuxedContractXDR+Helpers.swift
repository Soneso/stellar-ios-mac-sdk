//
//  MuxedContractXDR+Helpers.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.10.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// The "W..." strkey of a muxed contract address
/// ([CAP-0084](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0084.md)).
extension MuxedContractXDR {

    /// Creates the muxed contract a "W..." strkey names.
    ///
    /// - Parameter muxedContractId: the muxed contract address, for example
    ///   `WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC`
    /// - Throws: KeyUtilsError if the string is not a valid muxed contract strkey
    public init(muxedContractId: String) throws {
        self.init(strKeyPayload: try muxedContractId.decodeMuxedContractId())
    }

    /// The muxed contract address ("W...") of this value.
    ///
    /// - Throws: StellarSDKError.invalidArgument if the contract id is not 32 bytes wide
    public func toStrKey() throws -> String {
        return try strKeyPayload.encodeMuxedContractId()
    }

    /// The payload of the "W..." strkey: the contract id followed by the big-endian
    /// multiplexing id, the reverse of the XDR field order (SEP-23).
    var strKeyPayload: Data {
        var payload = contractId.wrapped
        withUnsafeBytes(of: id.bigEndian) { payload.append(contentsOf: $0) }
        return payload
    }

    /// Reads the 40 byte payload of a "W..." strkey, the width the strkey decoder enforces.
    init(strKeyPayload payload: Data) {
        let bytes = [UInt8](payload)
        let id = bytes[32..<40].reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
        self.init(id: id, contractId: WrappedData32(Data(bytes[0..<32])))
    }
}
