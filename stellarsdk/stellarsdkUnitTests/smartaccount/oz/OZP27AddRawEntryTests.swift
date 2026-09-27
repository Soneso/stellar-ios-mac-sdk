//
//  OZP27AddRawEntryTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Credential-arm preservation in `addRawSignatureMapEntry` under Protocol 27.
//

import XCTest
@testable import stellarsdk

final class OZP27AddRawEntryTests: XCTestCase {

    // MARK: ADDRESS arm preserved

    func test_addRawSignatureMapEntry_addressArm_preserved() throws {
        let entry = try OZP27GoldenVector.makeAddressEntry()
        let delegatedSignerAddress = try KeyPair.generateRandomKeyPair().accountId
        let delegatedSigner = try OZDelegatedSigner(address: delegatedSignerAddress)
        let signerKey = try delegatedSigner.toScVal()
        let sigValue: SCValXDR = .bytes(Data([0x01, 0x02]))
        let updated = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: signerKey,
            signatureValue: sigValue
        )
        if case .address = updated.credentials {
            // arm preserved, pass
        } else {
            XCTFail("Expected .address arm, got \(updated.credentials)")
        }
    }

    // MARK: ADDRESS_V2 arm preserved

    func test_addRawSignatureMapEntry_addressV2Arm_preserved() throws {
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
        let delegatedSignerAddress = try KeyPair.generateRandomKeyPair().accountId
        let delegatedSigner = try OZDelegatedSigner(address: delegatedSignerAddress)
        let signerKey = try delegatedSigner.toScVal()
        let sigValue: SCValXDR = .bytes(Data([0x01, 0x02]))
        let updated = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: signerKey,
            signatureValue: sigValue
        )
        if case .addressV2 = updated.credentials {
            // arm preserved, pass
        } else {
            XCTFail("Expected .addressV2 arm, got \(updated.credentials)")
        }
    }
}
