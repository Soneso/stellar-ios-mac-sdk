//
//  MuxedContract.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.10.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// A contract with an optional 64-bit multiplexing id
/// ([CAP-0084](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0084.md),
/// protocol 30 and higher).
///
/// A muxed contract address pairs a contract with an id the way a muxed account address pairs
/// an account with one. Its address is the "W..." strkey when the multiplexing id is set and
/// the "C..." strkey of the contract when it is not. The Stellar Asset Contract accepts a muxed
/// contract address as the recipient of a transfer; it is never an authorization address.
///
/// ```swift
/// let muxed = try MuxedContract(contractId: "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE",
///                               id: 123456)
/// print(muxed.address) // WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG
///
/// let parsed = try MuxedContract(address: muxed.address)
/// print(parsed.contractId) // CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE
/// print(parsed.id ?? 0)    // 123456
/// ```
public struct MuxedContract: Equatable, Sendable {
    /// The contract id ("C...").
    public let contractId: String

    /// The multiplexing id, nil for a plain contract address.
    public let id: UInt64?

    /// The muxed contract address ("W...") when `id` is set, otherwise `contractId`.
    public let address: String

    private let contractHash: WrappedData32

    /// Creates a muxed contract from a contract id and a multiplexing id.
    ///
    /// - Parameter contractId: the contract id ("C...")
    /// - Parameter id: the multiplexing id
    /// - Throws: StellarSDKError.invalidArgument naming the value if `contractId` is not a
    ///   valid contract id
    public init(contractId: String, id: UInt64) throws {
        guard contractId.isValidContractId() else {
            throw StellarSDKError.invalidArgument(message: "not a contract id (C...): \(contractId)")
        }
        try self.init(scAddress: SCAddressXDR(contractId: contractId, id: id))
    }

    /// Creates a muxed contract from a contract address ("C..."), which leaves `id` nil, or
    /// from a muxed contract address ("W...").
    ///
    /// - Throws: StellarSDKError.invalidArgument naming the value if `address` is neither
    public init(address: String) throws {
        if address.isValidContractId() {
            try self.init(scAddress: SCAddressXDR(contractId: address))
        } else if address.isValidMuxedContractId() {
            try self.init(scAddress: SCAddressXDR(muxedContractId: address))
        } else {
            throw StellarSDKError.invalidArgument(
                message: "not a contract (C...) or muxed contract (W...) address: \(address)")
        }
    }

    /// Creates a muxed contract from the contract arm of an XDR address, which leaves `id`
    /// nil, or from its muxed contract arm.
    ///
    /// - Throws: StellarSDKError.invalidArgument naming the arm for any other arm
    public init(scAddress: SCAddressXDR) throws {
        let hash: WrappedData32
        let muxedId: UInt64?
        switch scAddress {
        case .contract(let contract):
            hash = contract
            muxedId = nil
        case .muxedContract(let muxedContract):
            hash = muxedContract.contractId
            muxedId = muxedContract.id
        default:
            let arm = SCAddressType(rawValue: scAddress.type())?.enumName() ?? "\(scAddress.type())"
            throw StellarSDKError.invalidArgument(
                message: "expected a contract or muxed contract address, got \(arm)")
        }
        contractHash = hash
        id = muxedId
        contractId = try hash.wrapped.encodeContractId()
        address = try muxedId.map { try MuxedContractXDR(id: $0, contractId: hash).toStrKey() } ?? contractId
    }

    /// Converts this muxed contract to its XDR address: the muxed contract arm when `id` is
    /// set, the contract arm when it is not.
    public func toSCAddress() -> SCAddressXDR {
        guard let id else {
            return .contract(contractHash)
        }
        return .muxedContract(MuxedContractXDR(id: id, contractId: contractHash))
    }
}
