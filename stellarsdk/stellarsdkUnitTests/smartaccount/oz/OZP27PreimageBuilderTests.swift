//
//  OZP27PreimageBuilderTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Envelope type selection in the preimage builder under Protocol 27.
//

import XCTest
@testable import stellarsdk

/// Verifies that `buildPreimage(network:)` selects the correct envelope type for each
/// credential arm, independently of the higher-level signing paths.
final class OZP27PreimageBuilderTests: XCTestCase {

    private let network = Network.testnet

    // MARK: ADDRESS selects legacy envelope type

    func test_buildPreimage_addressArm_selectsLegacyEnvelopeType() throws {
        let entry = try OZP27GoldenVector.makeAddressEntry()
        let preimage = try entry.buildPreimage(network: network)
        if case .sorobanAuthorization = preimage {
            // correct envelope type, pass
        } else {
            XCTFail("ADDRESS arm must produce sorobanAuthorization preimage, got \(preimage)")
        }
    }

    // MARK: ADDRESS_V2 selects WITH_ADDRESS envelope type

    func test_buildPreimage_addressV2Arm_selectsWithAddressEnvelopeType() throws {
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
        let preimage = try entry.buildPreimage(network: network)
        if case .sorobanAuthorizationWithAddress = preimage {
            // correct envelope type, pass
        } else {
            XCTFail("ADDRESS_V2 arm must produce sorobanAuthorizationWithAddress preimage, got \(preimage)")
        }
    }

    // MARK: ADDRESS_WITH_DELEGATES selects WITH_ADDRESS envelope type

    func test_buildPreimage_withDelegatesArm_selectsWithAddressEnvelopeType() throws {
        let entry = try OZP27GoldenVector.makeAddressWithDelegatesEntry()
        let preimage = try entry.buildPreimage(network: network)
        if case .sorobanAuthorizationWithAddress = preimage {
            // correct envelope type, pass
        } else {
            XCTFail("ADDRESS_WITH_DELEGATES arm must produce sorobanAuthorizationWithAddress preimage, got \(preimage)")
        }
    }

    // MARK: ADDRESS and ADDRESS_V2 produce different hashes for identical credentials

    func test_buildPreimage_addressVsV2_produceDifferentHashes() throws {
        let addressEntry = try OZP27GoldenVector.makeAddressEntry()
        let v2Entry      = try OZP27GoldenVector.makeAddressV2Entry()

        let addressHash = try sha256OfPreimage(addressEntry)
        let v2Hash      = try sha256OfPreimage(v2Entry)

        XCTAssertNotEqual(addressHash, v2Hash,
            "ADDRESS and ADDRESS_V2 must produce different preimage hashes for identical credentials")
    }

    // MARK: ADDRESS_V2 and ADDRESS_WITH_DELEGATES produce same hash when delegates are empty

    /// Both V2 and WITH_DELEGATES (empty delegates) use the same preimage structure with the
    /// same address; the hashes must be equal when the top-level credentials are identical.
    func test_buildPreimage_v2AndEmptyWithDelegates_produceSameHash() throws {
        let v2Entry      = try OZP27GoldenVector.makeAddressV2Entry()
        let delegatesEntry = try OZP27GoldenVector.makeAddressWithDelegatesEntry()

        let v2Hash         = try sha256OfPreimage(v2Entry)
        let delegatesHash  = try sha256OfPreimage(delegatesEntry)

        XCTAssertEqual(v2Hash, delegatesHash,
            "ADDRESS_V2 and WITH_DELEGATES (empty) with identical credentials must produce the same preimage hash")
    }

    // MARK: Top-level address is embedded in WITH_ADDRESS preimage

    /// Verifies that the address field in the WITH_ADDRESS preimage is the top-level
    /// credential address, not a delegate address or zero bytes.
    func test_buildPreimage_withAddress_embedsTopLevelAddress() throws {
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
        let preimage = try entry.buildPreimage(network: network)
        guard case .sorobanAuthorizationWithAddress(let body) = preimage else {
            XCTFail("Expected sorobanAuthorizationWithAddress")
            return
        }
        // The embedded address must equal the contract address used in the test fixture.
        let expectedAddress = try SCAddressXDR(contractId: OZP27GoldenVector.contractId)
        let encoded1 = try Data(XDREncoder.encode(body.address))
        let encoded2 = try Data(XDREncoder.encode(expectedAddress))
        XCTAssertEqual(encoded1, encoded2,
            "WITH_ADDRESS preimage must embed the top-level credential address")
    }

    // MARK: Helper

    private func sha256OfPreimage(_ entry: SorobanAuthorizationEntryXDR) throws -> Data {
        let preimage = try entry.buildPreimage(network: network)
        let encoded  = try Data(XDREncoder.encode(preimage))
        return encoded.sha256Hash
    }
}
