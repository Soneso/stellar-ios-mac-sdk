//
//  OZSignerScValTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSignerScValTests: XCTestCase {

    private var validAccountG: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    override func setUp() {
        super.setUp()
        validAccountG = try! KeyPair.generateRandomKeyPair().accountId
    }

    // MARK: - OZDelegatedSigner.toScVal shape

    func testDelegatedSigner_toScVal_returnsVecType() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let scVal = try signer.toScVal()
        if case .vec = scVal { } else {
            XCTFail("Expected Vec")
        }
    }

    func testDelegatedSigner_toScVal_hasTwoElements() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        guard case .vec(let elements) = try signer.toScVal() else {
            XCTFail("Expected Vec")
            return
        }
        XCTAssertEqual(elements?.count, 2)
    }

    func testDelegatedSigner_toScVal_firstElementIsSymbolDelegated() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        guard case .vec(let elements) = try signer.toScVal(),
              let first = elements?.first,
              case .symbol(let name) = first else {
            XCTFail("Expected first symbol")
            return
        }
        XCTAssertEqual(name, "Delegated")
    }

    func testDelegatedSigner_toScVal_secondElementIsAddress() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        guard case .vec(let elements) = try signer.toScVal(),
              elements?.count == 2,
              case .address = elements![1] else {
            XCTFail("Expected address as second element")
            return
        }
    }

    func testDelegatedSigner_toScVal_addressMatchesAccountId() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        guard case .vec(let elements) = try signer.toScVal(),
              elements?.count == 2,
              case .address(let scAddress) = elements![1] else {
            XCTFail("Expected address element")
            return
        }
        XCTAssertEqual(scAddress.accountId, validAccountG)
    }

    func testDelegatedSigner_toScVal_contractAddressShape() throws {
        let signer = try OZDelegatedSigner(address: validContractC)
        guard case .vec(let elements) = try signer.toScVal(),
              elements?.count == 2,
              case .address = elements![1] else {
            XCTFail("Expected address element")
            return
        }
    }

    func testDelegatedSigner_invalidAddress_throws() {
        XCTAssertThrowsError(try OZDelegatedSigner(address: "invalid")) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAddress)
        }
    }

    func testDelegatedSigner_emptyAddress_throws() {
        XCTAssertThrowsError(try OZDelegatedSigner(address: "")) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAddress)
        }
    }

    // MARK: - OZExternalSigner.toScVal shape

    func testExternalSigner_toScVal_returnsVecType() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        if case .vec = try signer.toScVal() { } else {
            XCTFail("Expected Vec")
        }
    }

    func testExternalSigner_toScVal_hasThreeElements() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        guard case .vec(let elements) = try signer.toScVal() else {
            XCTFail("Expected Vec")
            return
        }
        XCTAssertEqual(elements?.count, 3)
    }

    func testExternalSigner_toScVal_firstElementIsSymbolExternal() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        guard case .vec(let elements) = try signer.toScVal(),
              let first = elements?.first,
              case .symbol(let name) = first else {
            XCTFail("Expected first symbol")
            return
        }
        XCTAssertEqual(name, "External")
    }

    func testExternalSigner_toScVal_secondElementIsAddress() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        guard case .vec(let elements) = try signer.toScVal(),
              elements?.count == 3,
              case .address = elements![1] else {
            XCTFail("Expected address as second element")
            return
        }
    }

    func testExternalSigner_toScVal_thirdElementIsBytes() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA, 0xBB]))
        guard case .vec(let elements) = try signer.toScVal(),
              elements?.count == 3,
              case .bytes(let bytes) = elements![2] else {
            XCTFail("Expected bytes as third element")
            return
        }
        XCTAssertEqual(bytes, Data([0xAA, 0xBB]))
    }

    func testExternalSigner_invalidVerifier_throws() {
        XCTAssertThrowsError(
            try OZExternalSigner(verifierAddress: "invalid", keyData: Data([0x01]))
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAddress)
        }
    }

    func testExternalSigner_emptyKeyData_throws() {
        XCTAssertThrowsError(
            try OZExternalSigner(verifierAddress: validContractC, keyData: Data())
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExternalSigner_webAuthn_invalidKeySize_throws() {
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: Data(repeating: 0x04, count: 64),
                credentialId: Data([0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExternalSigner_webAuthn_compressedPubkey_throws() {
        var pk = Data(count: 65)
        pk[0] = 0x02
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: pk,
                credentialId: Data([0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExternalSigner_webAuthn_emptyCredentialId_throws() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: pk,
                credentialId: Data()
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExternalSigner_ed25519_invalidKeySize_throws() {
        XCTAssertThrowsError(
            try OZExternalSigner.ed25519(
                verifierAddress: validContractC,
                publicKey: Data(repeating: 0x01, count: 31)
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    // MARK: - OZSubmissionMethod

    func testSubmissionMethod_hasTwoCases() {
        let cases: [OZSubmissionMethod] = [.relayer, .rpc]
        XCTAssertEqual(cases.count, 2)
    }

    func testSubmissionMethod_relayerCaseDistinctFromRpc() {
        XCTAssertNotEqual(
            String(describing: OZSubmissionMethod.relayer),
            String(describing: OZSubmissionMethod.rpc)
        )
    }

    // MARK: - Round trips

    func testDelegatedSigner_toScVal_isStable() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let s1 = try signer.toScVal()
        let s2 = try signer.toScVal()
        XCTAssertEqual(
            try Data(XDREncoder.encode(s1)).base16EncodedString(),
            try Data(XDREncoder.encode(s2)).base16EncodedString()
        )
    }

    func testExternalSigner_toScVal_isStable() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s1 = try signer.toScVal()
        let s2 = try signer.toScVal()
        XCTAssertEqual(
            try Data(XDREncoder.encode(s1)).base16EncodedString(),
            try Data(XDREncoder.encode(s2)).base16EncodedString()
        )
    }

    func testSignerScVal_delegatedAndExternal_distinctEncodings() throws {
        let delegated = try OZDelegatedSigner(address: validAccountG)
        let external = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let dHex = try Data(XDREncoder.encode(delegated.toScVal())).base16EncodedString()
        let eHex = try Data(XDREncoder.encode(external.toScVal())).base16EncodedString()
        XCTAssertNotEqual(dHex, eHex)
    }

    func testSignerScVal_delegatedSameAddressSameEncoding() throws {
        let signerA = try OZDelegatedSigner(address: validAccountG)
        let signerB = try OZDelegatedSigner(address: validAccountG)
        let aHex = try Data(XDREncoder.encode(signerA.toScVal())).base16EncodedString()
        let bHex = try Data(XDREncoder.encode(signerB.toScVal())).base16EncodedString()
        XCTAssertEqual(aHex, bHex)
    }

    func testSignerScVal_externalSameKeyDataSameEncoding() throws {
        let signerA = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let signerB = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let aHex = try Data(XDREncoder.encode(signerA.toScVal())).base16EncodedString()
        let bHex = try Data(XDREncoder.encode(signerB.toScVal())).base16EncodedString()
        XCTAssertEqual(aHex, bHex)
    }

    func testSignerScVal_externalDifferentKeyDataDifferentEncoding() throws {
        let signerA = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let signerB = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xBB]))
        let aHex = try Data(XDREncoder.encode(signerA.toScVal())).base16EncodedString()
        let bHex = try Data(XDREncoder.encode(signerB.toScVal())).base16EncodedString()
        XCTAssertNotEqual(aHex, bHex)
    }
}
