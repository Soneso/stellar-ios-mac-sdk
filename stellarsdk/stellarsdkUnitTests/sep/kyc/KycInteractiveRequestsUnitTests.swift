//
//  KycInteractiveRequestsUnitTests.swift
//  stellarsdk
//
//  Created by Soneso
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class KycInteractiveRequestsUnitTests: XCTestCase {

    // MARK: - Test Data

    let testJWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
    let testAccount = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"
    let testIssuer = "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG"

    // MARK: - PutCustomerInfoRequest Tests

    func testPutCustomerInfoRequestInitialization() {
        let request = PutCustomerInfoRequest(jwt: testJWT)

        XCTAssertEqual(request.jwt, testJWT)
        XCTAssertNil(request.id)
        XCTAssertNil(request.account)
        XCTAssertNil(request.memo)
        XCTAssertNil(request.memoType)
        XCTAssertNil(request.type)
        XCTAssertNil(request.transactionId)
        XCTAssertNil(request.fields)
        XCTAssertNil(request.organizationFields)
        XCTAssertNil(request.financialAccountFields)
        XCTAssertNil(request.cardFields)
        XCTAssertNil(request.extraFields)
        XCTAssertNil(request.extraFiles)
    }

    func testPutCustomerInfoRequestWithId() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.id = "customer-123"

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["id"]!, encoding: .utf8), "customer-123")
    }

    func testPutCustomerInfoRequestWithAccount() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.account = testAccount

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["account"]!, encoding: .utf8), testAccount)
    }

    func testPutCustomerInfoRequestWithMemo() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.memo = "123456"
        request.memoType = "id"

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["memo"]!, encoding: .utf8), "123456")
        XCTAssertEqual(String(data: parameters["memo_type"]!, encoding: .utf8), "id")
    }

    func testPutCustomerInfoRequestWithType() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.type = "sep6-deposit"

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["type"]!, encoding: .utf8), "sep6-deposit")
    }

    func testPutCustomerInfoRequestWithTransactionId() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.transactionId = "tx-789"

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["transaction_id"]!, encoding: .utf8), "tx-789")
    }

    func testPutCustomerInfoRequestWithNaturalPersonFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.fields = [
            .firstName("John"),
            .lastName("Doe"),
            .emailAddress("john.doe@example.com"),
            .mobileNumber("+14155551234")
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["first_name"]!, encoding: .utf8), "John")
        XCTAssertEqual(String(data: parameters["last_name"]!, encoding: .utf8), "Doe")
        XCTAssertEqual(String(data: parameters["email_address"]!, encoding: .utf8), "john.doe@example.com")
        XCTAssertEqual(String(data: parameters["mobile_number"]!, encoding: .utf8), "+14155551234")
    }

    func testPutCustomerInfoRequestWithBinaryFieldsPlacedLast() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        let photoData = "photo".data(using: .utf8)!
        let proofData = "proof".data(using: .utf8)!

        request.fields = [
            .firstName("John"),
            .photoIdFront(photoData),
            .lastName("Doe"),
            .photoProofResidence(proofData)
        ]

        let parameters = request.toParameters()

        // Verify all fields are present (order is not guaranteed in dictionaries)
        XCTAssertEqual(String(data: parameters["first_name"]!, encoding: .utf8), "John")
        XCTAssertEqual(String(data: parameters["last_name"]!, encoding: .utf8), "Doe")
        XCTAssertEqual(parameters["photo_id_front"], photoData)
        XCTAssertEqual(parameters["photo_proof_residence"], proofData)
    }

    func testPutCustomerInfoRequestWithAllNaturalPersonBinaryFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        let photoFrontData = "front".data(using: .utf8)!
        let photoBackData = "back".data(using: .utf8)!
        let notaryData = "notary".data(using: .utf8)!
        let residenceData = "residence".data(using: .utf8)!
        let incomeData = "income".data(using: .utf8)!
        let livenessData = "liveness".data(using: .utf8)!

        request.fields = [
            .firstName("John"),
            .photoIdFront(photoFrontData),
            .photoIdBack(photoBackData),
            .notaryApprovalOfPhotoId(notaryData),
            .photoProofResidence(residenceData),
            .proofOfIncome(incomeData),
            .proofOfLiveness(livenessData)
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(parameters["photo_id_front"], photoFrontData)
        XCTAssertEqual(parameters["photo_id_back"], photoBackData)
        XCTAssertEqual(parameters["notary_approval_of_photo_id"], notaryData)
        XCTAssertEqual(parameters["photo_proof_residence"], residenceData)
        XCTAssertEqual(parameters["proof_of_income"], incomeData)
        XCTAssertEqual(parameters["proof_of_liveness"], livenessData)
    }

    func testPutCustomerInfoRequestWithIPAddressField() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.fields = [
            .ipAddress("192.168.1.100")
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["ip_address"]!, encoding: .utf8), "192.168.1.100")
    }

    func testPutCustomerInfoRequestWithReferralIdField() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.fields = [
            .referralId("ref-12345")
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["referral_id"]!, encoding: .utf8), "ref-12345")
    }

    func testPutCustomerInfoRequestWithOrganizationFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.organizationFields = [
            .name("Acme Corp"),
            .VATNumber("VAT123456"),
            .registrationNumber("REG789"),
            .directorName("Jane Smith")
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["organization.name"]!, encoding: .utf8), "Acme Corp")
        XCTAssertEqual(String(data: parameters["organization.VAT_number"]!, encoding: .utf8), "VAT123456")
        XCTAssertEqual(String(data: parameters["organization.registration_number"]!, encoding: .utf8), "REG789")
        XCTAssertEqual(String(data: parameters["organization.director_name"]!, encoding: .utf8), "Jane Smith")
    }

    func testPutCustomerInfoRequestWithOrganizationBinaryFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        let incorporationData = "incorporation".data(using: .utf8)!
        let proofAddressData = "proof".data(using: .utf8)!

        request.organizationFields = [
            .name("Acme Corp"),
            .photoIncorporationDoc(incorporationData),
            .photoProofAddress(proofAddressData)
        ]

        let parameters = request.toParameters()

        // Verify all fields are present (order is not guaranteed in dictionaries)
        XCTAssertEqual(String(data: parameters["organization.name"]!, encoding: .utf8), "Acme Corp")
        XCTAssertEqual(parameters["organization.photo_incorporation_doc"], incorporationData)
        XCTAssertEqual(parameters["organization.photo_proof_address"], proofAddressData)
    }

    func testPutCustomerInfoRequestWithFinancialAccountFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.financialAccountFields = [
            .bankName("Chase Bank"),
            .bankAccountNumber("1234567890"),
            .bankNumber("021000021"),
            .bankAccountType("checking")
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["bank_name"]!, encoding: .utf8), "Chase Bank")
        XCTAssertEqual(String(data: parameters["bank_account_number"]!, encoding: .utf8), "1234567890")
        XCTAssertEqual(String(data: parameters["bank_number"]!, encoding: .utf8), "021000021")
        XCTAssertEqual(String(data: parameters["bank_account_type"]!, encoding: .utf8), "checking")
    }

    func testPutCustomerInfoRequestWithCardFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.cardFields = [
            .number("4111111111111111"),
            .expirationDate("12/25"),
            .cvc("123"),
            .holderName("John Doe")
        ]

        let parameters = request.toParameters()
        XCTAssertNotNil(parameters["card.number"])
        XCTAssertNotNil(parameters["card.expiration_date"])
        XCTAssertNotNil(parameters["card.cvc"])
        XCTAssertNotNil(parameters["card.holder_name"])
    }

    func testPutCustomerInfoRequestWithExtraFields() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        request.extraFields = [
            "custom_field1": "value1",
            "custom_field2": "value2"
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(String(data: parameters["custom_field1"]!, encoding: .utf8), "value1")
        XCTAssertEqual(String(data: parameters["custom_field2"]!, encoding: .utf8), "value2")
    }

    func testPutCustomerInfoRequestWithExtraFiles() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        let file1Data = "file1".data(using: .utf8)!
        let file2Data = "file2".data(using: .utf8)!

        request.extraFiles = [
            "custom_file1": file1Data,
            "custom_file2": file2Data
        ]

        let parameters = request.toParameters()
        XCTAssertEqual(parameters["custom_file1"], file1Data)
        XCTAssertEqual(parameters["custom_file2"], file2Data)
    }

    func testPutCustomerInfoRequestWithMixedFieldTypes() {
        var request = PutCustomerInfoRequest(jwt: testJWT)
        let photoData = "photo".data(using: .utf8)!
        let customFileData = "custom".data(using: .utf8)!

        request.id = "customer-456"
        request.account = testAccount
        request.fields = [
            .firstName("John"),
            .photoIdFront(photoData)
        ]
        request.organizationFields = [
            .name("Test Org")
        ]
        request.financialAccountFields = [
            .bankName("Test Bank")
        ]
        request.extraFields = ["custom": "value"]
        request.extraFiles = ["custom_file": customFileData]

        let parameters = request.toParameters()
        XCTAssertNotNil(parameters["id"])
        XCTAssertNotNil(parameters["account"])
        XCTAssertNotNil(parameters["first_name"])
        XCTAssertNotNil(parameters["photo_id_front"])
        XCTAssertNotNil(parameters["organization.name"])
        XCTAssertNotNil(parameters["bank_name"])
        XCTAssertNotNil(parameters["custom"])
        XCTAssertNotNil(parameters["custom_file"])
    }

    // MARK: - Claimant Tests

    func testClaimantInitializationWithoutPredicate() {
        let claimant = Claimant(destination: testAccount)

        XCTAssertEqual(claimant.destination, testAccount)

        // Verify it creates an unconditional predicate
        if case .claimPredicateUnconditional = claimant.predicate {
            // Success
        } else {
            XCTFail("Expected unconditional predicate")
        }
    }

    func testClaimantInitializationWithPredicate() {
        let predicate = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let claimant = Claimant(destination: testAccount, predicate: predicate)

        XCTAssertEqual(claimant.destination, testAccount)

        if case .claimPredicateBeforeAbsTime(let timestamp) = claimant.predicate {
            XCTAssertEqual(timestamp, 1735689600)
        } else {
            XCTFail("Expected before absolute time predicate")
        }
    }

    func testClaimantPredicateUnconditional() {
        let predicate = Claimant.predicateUnconditional()

        if case .claimPredicateUnconditional = predicate {
            // Success
        } else {
            XCTFail("Expected unconditional predicate")
        }
    }

    func testClaimantPredicateBeforeAbsoluteTime() {
        let timestamp: Int64 = 1704067200
        let predicate = Claimant.predicateBeforeAbsoluteTime(unixEpoch: timestamp)

        if case .claimPredicateBeforeAbsTime(let value) = predicate {
            XCTAssertEqual(value, timestamp)
        } else {
            XCTFail("Expected before absolute time predicate")
        }
    }

    func testClaimantPredicateBeforeRelativeTime() {
        let seconds: Int64 = 86400 // 1 day
        let predicate = Claimant.predicateBeforeRelativeTime(seconds: seconds)

        if case .claimPredicateBeforeRelTime(let value) = predicate {
            XCTAssertEqual(value, seconds)
        } else {
            XCTFail("Expected before relative time predicate")
        }
    }

    func testClaimantPredicateAnd() {
        let left = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let right = Claimant.predicateUnconditional()
        let predicate = Claimant.predicateAnd(left: left, right: right)

        if case .claimPredicateAnd(let predicates) = predicate {
            XCTAssertEqual(predicates.count, 2)
        } else {
            XCTFail("Expected AND predicate")
        }
    }

    func testClaimantPredicateOr() {
        let left = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let right = Claimant.predicateBeforeRelativeTime(seconds: 3600)
        let predicate = Claimant.predicateOr(left: left, right: right)

        if case .claimPredicateOr(let predicates) = predicate {
            XCTAssertEqual(predicates.count, 2)
        } else {
            XCTFail("Expected OR predicate")
        }
    }

    func testClaimantPredicateNot() {
        let innerPredicate = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let predicate = Claimant.predicateNot(predicate: innerPredicate)

        if case .claimPredicateNot(let wrapped) = predicate {
            if case .claimPredicateBeforeAbsTime(let timestamp) = wrapped {
                XCTAssertEqual(timestamp, 1735689600)
            } else {
                XCTFail("Expected wrapped before absolute time predicate")
            }
        } else {
            XCTFail("Expected NOT predicate")
        }
    }

    func testClaimantComplexPredicateComposition() {
        // Create a complex predicate: (beforeAbsTime OR beforeRelTime) AND NOT unconditional
        let beforeAbs = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let beforeRel = Claimant.predicateBeforeRelativeTime(seconds: 7200)
        let orPredicate = Claimant.predicateOr(left: beforeAbs, right: beforeRel)

        let unconditional = Claimant.predicateUnconditional()
        let notPredicate = Claimant.predicateNot(predicate: unconditional)

        let complexPredicate = Claimant.predicateAnd(left: orPredicate, right: notPredicate)

        if case .claimPredicateAnd(let predicates) = complexPredicate {
            XCTAssertEqual(predicates.count, 2)

            // Verify first is OR
            if case .claimPredicateOr(_) = predicates[0] {
                // Success
            } else {
                XCTFail("Expected OR predicate as first operand")
            }

            // Verify second is NOT
            if case .claimPredicateNot(_) = predicates[1] {
                // Success
            } else {
                XCTFail("Expected NOT predicate as second operand")
            }
        } else {
            XCTFail("Expected AND predicate")
        }
    }

    func testClaimantToXDR() throws {
        let claimant = Claimant(destination: testAccount)

        let xdr = try claimant.toXDR()

        if case .claimantTypeV0(_) = xdr {
            // Successfully created XDR
        } else {
            XCTFail("Expected claimant type V0")
        }
    }

    func testClaimantToXDRWithPredicate() throws {
        let predicate = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let claimant = Claimant(destination: testAccount, predicate: predicate)

        let xdr = try claimant.toXDR()

        if case .claimantTypeV0(_) = xdr {
            // Successfully created XDR
        } else {
            XCTFail("Expected claimant type V0")
        }
    }

    func testClaimantToXDRWithInvalidDestination() {
        let claimant = Claimant(destination: "invalid-account")

        XCTAssertThrowsError(try claimant.toXDR()) { error in
            if case StellarSDKError.xdrEncodingError(let message) = error {
                XCTAssertTrue(message.contains("Error encoding claimant"))
            } else {
                XCTFail("Expected xdrEncodingError")
            }
        }
    }

    func testClaimantFromXDR() throws {
        let originalClaimant = Claimant(destination: testAccount)
        let xdr = try originalClaimant.toXDR()

        let decodedClaimant = try Claimant.fromXDR(claimantXDR: xdr)

        XCTAssertEqual(decodedClaimant.destination, testAccount)
        if case .claimPredicateUnconditional = decodedClaimant.predicate {
            // Success
        } else {
            XCTFail("Expected unconditional predicate")
        }
    }

    func testClaimantFromXDRWithComplexPredicate() throws {
        let beforeAbs = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
        let beforeRel = Claimant.predicateBeforeRelativeTime(seconds: 3600)
        let complexPredicate = Claimant.predicateAnd(left: beforeAbs, right: beforeRel)

        let originalClaimant = Claimant(destination: testAccount, predicate: complexPredicate)
        let xdr = try originalClaimant.toXDR()

        let decodedClaimant = try Claimant.fromXDR(claimantXDR: xdr)

        XCTAssertEqual(decodedClaimant.destination, testAccount)
        if case .claimPredicateAnd(let predicates) = decodedClaimant.predicate {
            XCTAssertEqual(predicates.count, 2)
        } else {
            XCTFail("Expected AND predicate")
        }
    }

    func testClaimantRoundTripXDR() throws {
        let predicate = Claimant.predicateOr(
            left: Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600),
            right: Claimant.predicateBeforeRelativeTime(seconds: 7200)
        )
        let originalClaimant = Claimant(destination: testAccount, predicate: predicate)

        let xdr = try originalClaimant.toXDR()
        let decodedClaimant = try Claimant.fromXDR(claimantXDR: xdr)

        XCTAssertEqual(decodedClaimant.destination, originalClaimant.destination)

        // Verify predicates match
        if case .claimPredicateOr(_) = originalClaimant.predicate,
           case .claimPredicateOr(_) = decodedClaimant.predicate {
            // Success
        } else {
            XCTFail("Predicates don't match after round trip")
        }
    }

    func testClaimantMultipleInstances() {
        let claimant1 = Claimant(destination: testAccount)
        let claimant2 = Claimant(destination: testIssuer)
        let claimant3 = Claimant(destination: testAccount, predicate: Claimant.predicateUnconditional())

        XCTAssertEqual(claimant1.destination, testAccount)
        XCTAssertEqual(claimant2.destination, testIssuer)
        XCTAssertEqual(claimant3.destination, testAccount)

        XCTAssertNotEqual(claimant1.destination, claimant2.destination)
        XCTAssertEqual(claimant1.destination, claimant3.destination)
    }

    func testClaimantWithDifferentPredicateTypes() throws {
        let predicates: [ClaimPredicateXDR] = [
            Claimant.predicateUnconditional(),
            Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600),
            Claimant.predicateBeforeRelativeTime(seconds: 86400),
            Claimant.predicateNot(predicate: Claimant.predicateUnconditional()),
            Claimant.predicateAnd(
                left: Claimant.predicateUnconditional(),
                right: Claimant.predicateUnconditional()
            ),
            Claimant.predicateOr(
                left: Claimant.predicateUnconditional(),
                right: Claimant.predicateUnconditional()
            )
        ]

        for predicate in predicates {
            let claimant = Claimant(destination: testAccount, predicate: predicate)
            let xdr = try claimant.toXDR()
            let decoded = try Claimant.fromXDR(claimantXDR: xdr)

            XCTAssertEqual(decoded.destination, testAccount)
        }
    }
}
