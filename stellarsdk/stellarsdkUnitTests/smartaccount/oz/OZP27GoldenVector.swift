//
//  OZP27GoldenVector.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Fixed authorization entry shared by the Protocol 27 OZ smart-account signing tests.
//

import Foundation
@testable import stellarsdk

/// Builds a minimal SorobanAuthorizationEntryXDR for fixed parameters used across
/// the golden-vector and arm-handling tests.
///
/// Golden vector parameters (normative, must not be changed):
///   network:     "Test SDF Network ; September 2015"
///   nonce:       123456789101112
///   expiration:  4242
///   contract:    CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE
///   fn:          hello(u64 1234)
///
/// Expected legacy ADDRESS sha256 (hex):
///   120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe
enum OZP27GoldenVector {
    static let network = "Test SDF Network ; September 2015"
    static let nonce: Int64 = 123456789101112
    static let expiration: UInt32 = 4242
    static let contractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

    /// Hex-encoded SHA-256 of the legacy ADDRESS preimage for the parameters above.
    static let legacyPreimageHashHex =
        "120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe"

    /// Builds the fixed test entry with the legacy ADDRESS arm.
    static func makeAddressEntry() throws -> SorobanAuthorizationEntryXDR {
        let contractAddress = try SCAddressXDR(contractId: contractId)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "hello",
                args: [.u64(1234)]
            )),
            subInvocations: []
        )
        let creds = SorobanAddressCredentialsXDR(
            address: contractAddress,
            nonce: nonce,
            signatureExpirationLedger: expiration,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(creds),
            rootInvocation: invocation
        )
    }

    /// Builds the same fixed entry but with the ADDRESS_V2 arm.
    static func makeAddressV2Entry() throws -> SorobanAuthorizationEntryXDR {
        var entry = try makeAddressEntry()
        let creds = entry.credentials.addressCredentials!
        entry.credentials = .addressV2(creds)
        return entry
    }

    /// Builds the same fixed entry but with the ADDRESS_WITH_DELEGATES arm (empty delegates).
    static func makeAddressWithDelegatesEntry() throws -> SorobanAuthorizationEntryXDR {
        var entry = try makeAddressEntry()
        let creds = entry.credentials.addressCredentials!
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: creds,
            delegates: []
        )
        entry.credentials = .addressWithDelegates(withDelegates)
        return entry
    }
}
