//
//  Sep07DocTest.swift
//  stellarsdkTests
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Tests for SEP-07 documentation examples.
/// Tests URI generation, parameter extraction, signing, and validation
/// using deterministic data (no network calls for most tests).
class Sep07DocTest: XCTestCase {

    let accountId = "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"
    let secretSeed = "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF"

    // MARK: - Quick Example (Snippet 1)

    func testQuickExamplePayUri() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            amount: Decimal(100),
            assetCode: "USDC",
            assetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:pay?"))
        XCTAssertTrue(uri.contains("destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"))
        XCTAssertTrue(uri.contains("amount=100"))
        XCTAssertTrue(uri.contains("asset_code=USDC"))
        XCTAssertTrue(uri.contains("asset_issuer=GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"))
    }

    // MARK: - Transaction Signing URI (Snippet 2)

    func testGenerateSignTransactionUri() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transaction)

        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?xdr="))
        // The XDR should contain some base64-encoded data
        XCTAssertTrue(uri.count > "web+stellar:tx?xdr=".count)
    }

    // MARK: - Transaction URI with All Options (Snippet 3)

    func testGenerateSignTransactionUriWithAllOptions() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            callBack: "url:https://example.com/callback",
            publicKey: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            message: "Please sign to update your account settings",
            networkPassphrase: Network.testnet.passphrase,
            originDomain: "example.com"
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?xdr="))
        XCTAssertTrue(uri.contains("pubkey=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"))
        XCTAssertTrue(uri.contains("origin_domain=example.com"))
    }

    // MARK: - Field Replacement (Snippet 4)

    func testFieldReplacementParameter() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let replaceString = "sourceAccount:X,operations[0].destination:Y"

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            replace: replaceString
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?xdr="))
        XCTAssertTrue(uri.contains("replace="))
    }

    // MARK: - Transaction Chaining (Snippet 5)

    func testTransactionChaining() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let originalUri = "web+stellar:tx?xdr=AAAA...&origin_domain=original.com&signature=..."

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            callBack: "url:https://multisig-coordinator.com/collect",
            chain: originalUri,
            originDomain: "multisig-coordinator.com"
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?xdr="))
        XCTAssertTrue(uri.contains("chain="))
        XCTAssertTrue(uri.contains("origin_domain=multisig-coordinator.com"))
    }

    // MARK: - Multisig Coordination (Snippet 6)

    func testMultisigCoordination() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            callBack: "url:https://multisig-service.example.com/collect",
            message: "Sign to approve the 2-of-3 multisig transaction",
            originDomain: "multisig-service.example.com"
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?xdr="))
        XCTAssertTrue(uri.contains("origin_domain=multisig-service.example.com"))
    }

    // MARK: - Payment Request (Snippet 7)

    func testSimpleXlmPaymentUri() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            amount: Decimal(50.5)
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:pay?"))
        XCTAssertTrue(uri.contains("destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"))
        XCTAssertTrue(uri.contains("amount=50.5"))
        // No asset_code or asset_issuer for native XLM
        XCTAssertFalse(uri.contains("asset_code"))
        XCTAssertFalse(uri.contains("asset_issuer"))
    }

    // MARK: - Payment with Asset and Memo (Snippet 8)

    func testPaymentWithAssetAndMemo() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            amount: Decimal(100),
            assetCode: "USDC",
            assetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            memo: "order-12345",
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.contains("asset_code=USDC"))
        XCTAssertTrue(uri.contains("asset_issuer=GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"))
        XCTAssertTrue(uri.contains("memo="))
        XCTAssertTrue(uri.contains("memo_type=MEMO_TEXT"))
    }

    // MARK: - Payment with Hash Memo (Snippet 9)

    func testPaymentWithHashMemo() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            amount: Decimal(100),
            memo: "my-unique-identifier",
            memoType: MemoTypeAsString.HASH
        )

        XCTAssertTrue(uri.contains("memo_type=MEMO_HASH"))
        XCTAssertTrue(uri.contains("memo="))
    }

    // MARK: - Donation Request (Snippet 10)

    func testDonationRequestNoAmount() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            message: "Support our open source project!"
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:pay?"))
        XCTAssertTrue(uri.contains("destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"))
        XCTAssertFalse(uri.contains("amount="))
        XCTAssertTrue(uri.contains("msg="))
    }

    // MARK: - Signing URIs (Snippet 11)

    func testSignUri() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let validator = URISchemeValidator()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            originDomain: "example.com"
        )

        let signResult = validator.signURI(url: uri, signerKeyPair: keyPair)
        switch signResult {
        case .success(let signedURL):
            XCTAssertTrue(signedURL.contains("signature="))
            XCTAssertTrue(signedURL.contains("origin_domain=example.com"))
        case .failure(let error):
            XCTFail("Signing failed: \(error)")
        }
    }

    // MARK: - Full Validation with Signature (Snippet 12)
    // Note: checkURISchemeIsValid requires network access to fetch stellar.toml
    // This test validates the error handling for missing origin_domain

    func testValidationMissingOriginDomain() async throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let validator = URISchemeValidator()

        // Generate a URI without origin_domain
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transaction)

        let result = await validator.checkURISchemeIsValid(url: uri)
        switch result {
        case .success:
            XCTFail("Should have failed - no origin_domain")
        case .failure(let error):
            XCTAssertEqual(error, URISchemeErrors.missingOriginDomain)
        }
    }

    // MARK: - Signature Verification with signURI (Snippet 13)

    func testSignAndVerifyUri() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let validator = URISchemeValidator()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            originDomain: "example.com"
        )

        let signResult = validator.signURI(url: uri, signerKeyPair: keyPair)
        switch signResult {
        case .success(let signedURL):
            // The signed URL should have signature appended
            XCTAssertTrue(signedURL.contains("&signature="))
        case .failure(let error):
            XCTFail("signURI failed: \(error)")
        }
    }

    // MARK: - Sign and Submit Transaction (Snippet 14)
    // Note: signAndSubmitTransaction requires a valid on-chain transaction.
    // This test verifies the error case for invalid XDR.

    func testSignAndSubmitWithInvalidXdr() async {
        let uriScheme = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)

        let uri = "web+stellar:tx?xdr=invalidxdrdata"

        let result = await uriScheme.signAndSubmitTransaction(
            forURL: uri,
            signerKeyPair: keyPair,
            network: Network.testnet
        )

        switch result {
        case .success:
            XCTFail("Should have failed with invalid XDR")
        case .destinationRequiresMemo:
            XCTFail("Should have failed with invalid XDR")
        case .failure(let error):
            // Expected: TransactionXDR missing from url!
            switch error {
            case .requestFailed(let message, _):
                XCTAssertEqual("TransactionXDR missing from url!", message)
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Extracting URI Parameters (Snippet 15)

    func testExtractParameters() {
        let uriScheme = URIScheme()

        let uri = "web+stellar:tx?xdr=AAAA&pubkey=GABC&origin_domain=example.com&msg=Hello%20World&callback=url%3Ahttps%3A%2F%2Fexample.com"

        let xdr = uriScheme.getValue(forParam: .xdr, fromURL: uri)
        XCTAssertEqual(xdr, "AAAA")

        let pubkey = uriScheme.getValue(forParam: .pubkey, fromURL: uri)
        XCTAssertEqual(pubkey, "GABC")

        let originDomain = uriScheme.getValue(forParam: .origin_domain, fromURL: uri)
        XCTAssertEqual(originDomain, "example.com")

        let msg = uriScheme.getValue(forParam: .msg, fromURL: uri)
        XCTAssertEqual(msg, "Hello%20World")

        // Missing parameter returns nil
        let signature = uriScheme.getValue(forParam: .signature, fromURL: uri)
        XCTAssertNil(signature)

        let chain = uriScheme.getValue(forParam: .chain, fromURL: uri)
        XCTAssertNil(chain)

        let replace = uriScheme.getValue(forParam: .replace, fromURL: uri)
        XCTAssertNil(replace)
    }

    // MARK: - Error Handling (Snippet 17)

    func testValidationErrorCases() async throws {
        let validator = URISchemeValidator()

        // Missing origin_domain
        let uriNoOrigin = "web+stellar:tx?xdr=AAAA"
        let result1 = await validator.checkURISchemeIsValid(url: uriNoOrigin)
        switch result1 {
        case .success:
            XCTFail("Should fail for missing origin_domain")
        case .failure(let error):
            XCTAssertEqual(error, URISchemeErrors.missingOriginDomain)
        }

        // Invalid origin_domain (not a FQDN)
        let uriInvalidDomain = "web+stellar:tx?xdr=AAAA&origin_domain=localhost"
        let result2 = await validator.checkURISchemeIsValid(url: uriInvalidDomain)
        switch result2 {
        case .success:
            XCTFail("Should fail for invalid origin_domain")
        case .failure(let error):
            XCTAssertEqual(error, URISchemeErrors.invalidOriginDomain)
        }
    }

    // MARK: - Transaction confirmation callback

    func testTransactionConfirmationRejection() async throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transaction)

        // Reject the transaction in the confirmation callback
        let result = await uriScheme.signAndSubmitTransaction(
            forURL: uri,
            signerKeyPair: keyPair,
            transactionConfirmation: { _ in
                return false
            }
        )

        switch result {
        case .failure(let error):
            switch error {
            case .requestFailed(let message, _):
                XCTAssertEqual("Transaction was not confirmed!", message)
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        default:
            XCTFail("Expected failure when transaction is not confirmed")
        }
    }

    // MARK: - QR Code URI (Snippet 18)

    func testQrCodeUri() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            amount: Decimal(25),
            memo: "coffee",
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.hasPrefix("web+stellar:pay?"))
        XCTAssertTrue(uri.contains("amount=25"))
        XCTAssertTrue(uri.contains("memo_type=MEMO_TEXT"))
    }

    // MARK: - Payment URI exact match (from existing test pattern)

    func testPaymentUriExactMatch() {
        let uriScheme = URIScheme()

        let uri = uriScheme.getPayOperationURI(
            destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            amount: Decimal(123.21),
            assetCode: "ANA",
            assetIssuer: "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV"
        )

        XCTAssertEqual(
            "web+stellar:pay?destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV&amount=123.21&asset_code=ANA&asset_issuer=GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV",
            uri
        )
    }

    // MARK: - Message length limit

    func testMessageLengthLimit() throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        let account = Account(keyPair: keyPair, sequenceNumber: 100)

        let setOp = try SetOptionsOperation(
            sourceAccountId: keyPair.accountId,
            homeDomain: "www.example.com"
        )

        let transaction = TransactionXDR(
            sourceAccount: keyPair.publicKey,
            seqNum: account.sequenceNumber + 1,
            cond: PreconditionsXDR.none,
            memo: .none,
            operations: [try setOp.toXDR()]
        )

        let uriScheme = URIScheme()

        // Message of exactly 300 chars is dropped (must be < 300)
        let longMessage = String(repeating: "a", count: 300)
        let uriLong = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            message: longMessage
        )
        XCTAssertFalse(uriLong.contains("msg="))

        // Message of 299 chars is included
        let shortMessage = String(repeating: "a", count: 299)
        let uriShort = uriScheme.getSignTransactionURI(
            transactionXDR: transaction,
            message: shortMessage
        )
        XCTAssertTrue(uriShort.contains("msg="))
    }

    // MARK: - Pay URI message length limit

    func testPayUriMessageLengthLimit() {
        let uriScheme = URIScheme()

        // Message of exactly 300 chars is dropped
        let longMessage = String(repeating: "b", count: 300)
        let uriLong = uriScheme.getPayOperationURI(
            destination: accountId,
            message: longMessage
        )
        XCTAssertFalse(uriLong.contains("msg="))

        // Message of 299 chars is included
        let shortMessage = String(repeating: "b", count: 299)
        let uriShort = uriScheme.getPayOperationURI(
            destination: accountId,
            message: shortMessage
        )
        XCTAssertTrue(uriShort.contains("msg="))
    }
}
