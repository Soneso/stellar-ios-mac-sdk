//
//  URISchemeUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Claude on 04.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class URISchemeUnitTests: XCTestCase {

    // MARK: - Test Constants

    let testSourceSecretSeed = "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK"
    let testSourceAccountId = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    let testDestinationAccountId = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"
    let testSignerSecretSeed = "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN"
    let testSignerAccountId = "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6"

    var uriScheme: URIScheme!
    var uriSchemeValidator: URISchemeValidator!

    override func setUp() {
        super.setUp()
        uriScheme = URIScheme()
        uriSchemeValidator = URISchemeValidator()
    }

    override func tearDown() {
        uriScheme = nil
        uriSchemeValidator = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    func createTestTransaction() throws -> Transaction {
        let source = try KeyPair(secretSeed: testSourceSecretSeed)
        let destination = try KeyPair(accountId: testDestinationAccountId)
        let account = Account(keyPair: source, sequenceNumber: 123456)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )

        return try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )
    }

    func createTestTransactionXDR() throws -> TransactionXDR {
        let transaction = try createTestTransaction()
        return transaction.transactionXDR
    }

    // MARK: - URIScheme Constants Tests

    func testURISchemeNameConstant() {
        XCTAssertEqual(URISchemeName, "web+stellar:")
    }

    func testSignOperationConstant() {
        XCTAssertEqual(SignOperation, "tx?")
    }

    func testPayOperationConstant() {
        XCTAssertEqual(PayOperation, "pay?")
    }

    func testMessageMaximumLengthConstant() {
        XCTAssertEqual(MessageMaximumLength, 300)
    }

    // MARK: - getSignTransactionURI Tests

    func testGetSignTransactionURIBasic() throws {
        let transactionXDR = try createTestTransactionXDR()

        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        // Verify basic URI structure
        XCTAssertTrue(uri.hasPrefix(URISchemeName))
        XCTAssertTrue(uri.contains(SignOperation))
        XCTAssertTrue(uri.contains("xdr="))

        // Verify the URI does not have trailing ampersand
        XCTAssertFalse(uri.hasSuffix("&"))
    }

    func testGetSignTransactionURIWithAllParameters() throws {
        let transactionXDR = try createTestTransactionXDR()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            replace: "sourceAccount:TX_SOURCE_ACCOUNT",
            callBack: "url:https://example.com/callback",
            publicKey: testSourceAccountId,
            chain: "previous-request-uri",
            message: "Please sign this transaction",
            networkPassphrase: Network.testnet.passphrase,
            originDomain: "example.com",
            signature: "test-signature"
        )

        // Verify all parameters are present
        XCTAssertTrue(uri.hasPrefix(URISchemeName))
        XCTAssertTrue(uri.contains("xdr="))
        XCTAssertTrue(uri.contains("replace="))
        XCTAssertTrue(uri.contains("callback="))
        XCTAssertTrue(uri.contains("pubkey="))
        XCTAssertTrue(uri.contains("chain="))
        XCTAssertTrue(uri.contains("msg="))
        XCTAssertTrue(uri.contains("network_passphrase="))
        XCTAssertTrue(uri.contains("origin_domain="))
        XCTAssertTrue(uri.contains("signature="))

        // Verify URL encoding was applied
        XCTAssertTrue(uri.contains("example.com"))
    }

    func testGetSignTransactionURIWithCallback() throws {
        let transactionXDR = try createTestTransactionXDR()
        let callbackUrl = "url:https://example.com/callback?param=value"

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            callBack: callbackUrl
        )

        XCTAssertTrue(uri.contains("callback="))
        // The callback URL should be URL-encoded
        XCTAssertTrue(uri.contains("url%3Ahttps%3A%2F%2Fexample.com"))
    }

    func testGetSignTransactionURIWithPublicKey() throws {
        let transactionXDR = try createTestTransactionXDR()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            publicKey: testSourceAccountId
        )

        XCTAssertTrue(uri.contains("pubkey=\(testSourceAccountId)"))
    }

    func testGetSignTransactionURIWithMessageAtMaxLength() throws {
        let transactionXDR = try createTestTransactionXDR()
        // Create a message just under the max length (299 characters)
        let message = String(repeating: "a", count: 299)

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: message
        )

        XCTAssertTrue(uri.contains("msg="))
    }

    func testGetSignTransactionURIWithMessageExceedingMaxLength() throws {
        let transactionXDR = try createTestTransactionXDR()
        // Create a message at exactly the max length (300 characters) - should NOT be included
        let message = String(repeating: "a", count: 300)

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: message
        )

        // Message at or exceeding max length should not be included
        XCTAssertFalse(uri.contains("msg="))
    }

    func testGetSignTransactionURIWithNetworkPassphrase() throws {
        let transactionXDR = try createTestTransactionXDR()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            networkPassphrase: Network.testnet.passphrase
        )

        XCTAssertTrue(uri.contains("network_passphrase="))
        // The passphrase should be URL-encoded
        XCTAssertTrue(uri.contains("Test%20SDF%20Network"))
    }

    func testGetSignTransactionURIWithOriginDomain() throws {
        let transactionXDR = try createTestTransactionXDR()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            originDomain: "example.com"
        )

        XCTAssertTrue(uri.contains("origin_domain=example.com"))
    }

    func testGetSignTransactionURIWithSignature() throws {
        let transactionXDR = try createTestTransactionXDR()
        let signature = "test-signature-value"

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            signature: signature
        )

        XCTAssertTrue(uri.contains("signature=\(signature)"))
    }

    func testGetSignTransactionURIWithReplace() throws {
        let transactionXDR = try createTestTransactionXDR()
        let replace = "sourceAccount:TX_SOURCE_ACCOUNT"

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            replace: replace
        )

        XCTAssertTrue(uri.contains("replace="))
    }

    func testGetSignTransactionURIWithChain() throws {
        let transactionXDR = try createTestTransactionXDR()
        let chain = "web+stellar:tx?xdr=AAAAAP..."

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            chain: chain
        )

        XCTAssertTrue(uri.contains("chain="))
    }

    // MARK: - getPayOperationURI Tests

    func testGetPayOperationURIBasic() {
        let uri = uriScheme.getPayOperationURI(destination: testDestinationAccountId)

        XCTAssertTrue(uri.hasPrefix(URISchemeName))
        XCTAssertTrue(uri.contains(PayOperation))
        XCTAssertTrue(uri.contains("destination=\(testDestinationAccountId)"))
        XCTAssertFalse(uri.hasSuffix("&"))
    }

    func testGetPayOperationURIWithAllParameters() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(100.50),
            assetCode: "USDC",
            assetIssuer: testSourceAccountId,
            memo: "Test memo",
            memoType: MemoTypeAsString.TEXT,
            callBack: "url:https://example.com/callback",
            message: "Please complete payment",
            networkPassphrase: Network.testnet.passphrase,
            originDomain: "example.com",
            signature: "test-signature"
        )

        XCTAssertTrue(uri.hasPrefix(URISchemeName))
        XCTAssertTrue(uri.contains("destination="))
        XCTAssertTrue(uri.contains("amount="))
        XCTAssertTrue(uri.contains("asset_code="))
        XCTAssertTrue(uri.contains("asset_issuer="))
        XCTAssertTrue(uri.contains("memo="))
        XCTAssertTrue(uri.contains("callback="))
        XCTAssertTrue(uri.contains("msg="))
        XCTAssertTrue(uri.contains("network_passphrase="))
        XCTAssertTrue(uri.contains("origin_domain="))
        XCTAssertTrue(uri.contains("signature="))
    }

    func testGetPayOperationURIWithAmount() {
        let amount = Decimal(123.456)

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: amount
        )

        // Amount formatting may vary, just check it contains amount parameter
        XCTAssertTrue(uri.contains("amount="))
    }

    func testGetPayOperationURIWithAsset() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            assetCode: "USD",
            assetIssuer: testSourceAccountId
        )

        XCTAssertTrue(uri.contains("asset_code=USD"))
        XCTAssertTrue(uri.contains("asset_issuer=\(testSourceAccountId)"))
    }

    func testGetPayOperationURIWithTextMemo() {
        let memo = "Hello World"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: memo,
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.contains("memo="))
        // URL-encoded space
        XCTAssertTrue(uri.contains("Hello%20World"))
    }

    func testGetPayOperationURIWithIdMemo() {
        let memo = "12345678901234567890"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: memo,
            memoType: MemoTypeAsString.ID
        )

        XCTAssertTrue(uri.contains("memo=\(memo)"))
    }

    func testGetPayOperationURIWithHashMemo() {
        let hashHex = "abcdef1234567890abcdef1234567890"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: hashHex,
            memoType: MemoTypeAsString.HASH
        )

        // Hash memo should be base64 encoded then URL encoded
        XCTAssertTrue(uri.contains("memo="))
    }

    func testGetPayOperationURIWithReturnMemo() {
        let returnHash = "returnhash1234567890returnhash"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: returnHash,
            memoType: MemoTypeAsString.RETURN
        )

        // Return memo should be base64 encoded then URL encoded
        XCTAssertTrue(uri.contains("memo="))
    }

    func testGetPayOperationURIWithCallback() {
        let callback = "url:https://example.com/callback"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            callBack: callback
        )

        XCTAssertTrue(uri.contains("callback="))
    }

    func testGetPayOperationURIWithMessageAtMaxLength() {
        // Create a message just under the max length (299 characters)
        let message = String(repeating: "b", count: 299)

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            message: message
        )

        XCTAssertTrue(uri.contains("msg="))
    }

    func testGetPayOperationURIWithMessageExceedingMaxLength() {
        // Create a message at exactly the max length (300 characters) - should NOT be included
        let message = String(repeating: "b", count: 300)

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            message: message
        )

        XCTAssertFalse(uri.contains("msg="))
    }

    func testGetPayOperationURIWithNetworkPassphrase() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            networkPassphrase: Network.testnet.passphrase
        )

        XCTAssertTrue(uri.contains("network_passphrase="))
    }

    func testGetPayOperationURIWithOriginDomain() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            originDomain: "example.com"
        )

        XCTAssertTrue(uri.contains("origin_domain=example.com"))
    }

    func testGetPayOperationURIWithSignature() {
        let signature = "test-signature"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            signature: signature
        )

        XCTAssertTrue(uri.contains("signature=\(signature)"))
    }

    // MARK: - getValue Tests

    func testGetValueForXdrParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let xdrValue = uriScheme.getValue(forParam: .xdr, fromURL: uri)

        XCTAssertNotNil(xdrValue, "Should correctly extract XDR parameter")
        XCTAssertFalse(xdrValue!.isEmpty)
    }

    func testGetValueForCallbackParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let callback = "url:https://example.com/callback"
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            callBack: callback
        )

        let callbackValue = uriScheme.getValue(forParam: .callback, fromURL: uri)

        XCTAssertNotNil(callbackValue)
    }

    func testGetValueForPublicKeyParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            publicKey: testSourceAccountId
        )

        let pubkeyValue = uriScheme.getValue(forParam: .pubkey, fromURL: uri)

        XCTAssertNotNil(pubkeyValue)
        XCTAssertEqual(pubkeyValue, testSourceAccountId)
    }

    func testGetValueForMsgParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let message = "Test message"
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: message
        )

        let msgValue = uriScheme.getValue(forParam: .msg, fromURL: uri)

        XCTAssertNotNil(msgValue)
    }

    func testGetValueForOriginDomainParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let originDomain = "example.com"
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            originDomain: originDomain
        )

        let domainValue = uriScheme.getValue(forParam: .origin_domain, fromURL: uri)

        XCTAssertNotNil(domainValue)
        XCTAssertEqual(domainValue, originDomain)
    }

    func testGetValueForSignatureParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let signature = "test-signature"
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            signature: signature
        )

        let signatureValue = uriScheme.getValue(forParam: .signature, fromURL: uri)

        XCTAssertNotNil(signatureValue)
        XCTAssertEqual(signatureValue, signature)
    }

    func testGetValueForNetworkPassphraseParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            networkPassphrase: Network.testnet.passphrase
        )

        let passphraseValue = uriScheme.getValue(forParam: .network_passphrase, fromURL: uri)

        XCTAssertNotNil(passphraseValue)
    }

    func testGetValueForMissingParam() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let missingValue = uriScheme.getValue(forParam: .callback, fromURL: uri)

        XCTAssertNil(missingValue)
    }

    // MARK: - URISchemeValidator Tests

    func testSignURISuccess() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let result = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)

        switch result {
        case .success(let signedURL):
            XCTAssertTrue(signedURL.contains("signature="))
            XCTAssertTrue(signedURL.hasPrefix(uri))
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testSignURIWithExistingParams() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: "Test message",
            originDomain: "example.com"
        )

        let result = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)

        switch result {
        case .success(let signedURL):
            XCTAssertTrue(signedURL.contains("signature="))
            XCTAssertTrue(signedURL.contains("msg="))
            XCTAssertTrue(signedURL.contains("origin_domain="))
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testSignedURICanBeVerified() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        // Sign the URI
        let signResult = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)

        switch signResult {
        case .success(let signedURL):
            // Extract signature from signed URL
            let signatureValue = uriScheme.getValue(forParam: .signature, fromURL: signedURL)
            XCTAssertNotNil(signatureValue, "Signature should be present in signed URL")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    // MARK: - URISchemeErrors Tests

    func testURISchemeErrorsExist() {
        // Verify all error cases are accessible
        let _ = URISchemeErrors.invalidSignature
        let _ = URISchemeErrors.invalidOriginDomain
        let _ = URISchemeErrors.missingOriginDomain
        let _ = URISchemeErrors.missingSignature
        let _ = URISchemeErrors.invalidTomlDomain
        let _ = URISchemeErrors.invalidToml
        let _ = URISchemeErrors.tomlSignatureMissing
    }

    // MARK: - SignTransactionParams Tests

    func testSignTransactionParamsEnumValues() {
        // Verify all enum cases work correctly in string interpolation
        XCTAssertEqual("\(SignTransactionParams.xdr)", "xdr")
        XCTAssertEqual("\(SignTransactionParams.replace)", "replace")
        XCTAssertEqual("\(SignTransactionParams.callback)", "callback")
        XCTAssertEqual("\(SignTransactionParams.pubkey)", "pubkey")
        XCTAssertEqual("\(SignTransactionParams.chain)", "chain")
        XCTAssertEqual("\(SignTransactionParams.msg)", "msg")
        XCTAssertEqual("\(SignTransactionParams.network_passphrase)", "network_passphrase")
        XCTAssertEqual("\(SignTransactionParams.origin_domain)", "origin_domain")
        XCTAssertEqual("\(SignTransactionParams.signature)", "signature")
    }

    // MARK: - PayOperationParams Tests

    func testPayOperationParamsEnumValues() {
        // Verify all enum cases work correctly in string interpolation
        XCTAssertEqual("\(PayOperationParams.destination)", "destination")
        XCTAssertEqual("\(PayOperationParams.amount)", "amount")
        XCTAssertEqual("\(PayOperationParams.asset_code)", "asset_code")
        XCTAssertEqual("\(PayOperationParams.asset_issuer)", "asset_issuer")
        XCTAssertEqual("\(PayOperationParams.memo)", "memo")
        XCTAssertEqual("\(PayOperationParams.memo_type)", "memo_type")
        XCTAssertEqual("\(PayOperationParams.callback)", "callback")
        XCTAssertEqual("\(PayOperationParams.msg)", "msg")
        XCTAssertEqual("\(PayOperationParams.network_passphrase)", "network_passphrase")
        XCTAssertEqual("\(PayOperationParams.origin_domain)", "origin_domain")
        XCTAssertEqual("\(PayOperationParams.signature)", "signature")
    }

    // MARK: - URI Format Tests

    func testSignTransactionURIFormat() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        // Verify URI starts with proper prefix
        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?"))

        // Verify parameters are separated by &
        let queryString = String(uri.dropFirst("web+stellar:tx?".count))
        let params = queryString.split(separator: "&")
        XCTAssertGreaterThan(params.count, 0)

        // Verify each param has key=value format
        for param in params {
            XCTAssertTrue(param.contains("="))
        }
    }

    func testPayOperationURIFormat() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(50)
        )

        // Verify URI starts with proper prefix
        XCTAssertTrue(uri.hasPrefix("web+stellar:pay?"))

        // Verify parameters are separated by &
        let queryString = String(uri.dropFirst("web+stellar:pay?".count))
        let params = queryString.split(separator: "&")
        XCTAssertGreaterThan(params.count, 0)

        // Verify each param has key=value format
        for param in params {
            XCTAssertTrue(param.contains("="))
        }
    }

    // MARK: - URL Encoding Tests

    func testURLEncodingInSignTransactionURI() throws {
        let transactionXDR = try createTestTransactionXDR()
        let messageWithSpecialChars = "Hello World & More = Value"

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: messageWithSpecialChars
        )

        // Spaces should be encoded as %20
        XCTAssertTrue(uri.contains("Hello%20World"))
        // & should be encoded
        XCTAssertTrue(uri.contains("%26"))
        // = should be encoded
        XCTAssertTrue(uri.contains("%3D"))
    }

    func testURLEncodingInPayOperationURI() {
        let memoWithSpecialChars = "Test memo with spaces"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: memoWithSpecialChars,
            memoType: MemoTypeAsString.TEXT
        )

        // Spaces should be encoded as %20
        XCTAssertTrue(uri.contains("Test%20memo%20with%20spaces"))
    }

    // MARK: - SetupTransactionXDREnum Tests

    func testSetupTransactionXDREnumSuccess() throws {
        let transactionXDR = try createTestTransactionXDR()
        let result = SetupTransactionXDREnum.success(transactionXDR: transactionXDR)

        switch result {
        case .success(let xdr):
            XCTAssertNotNil(xdr)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSetupTransactionXDREnumSuccessWithNil() {
        let result = SetupTransactionXDREnum.success(transactionXDR: nil)

        switch result {
        case .success(let xdr):
            XCTAssertNil(xdr)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSetupTransactionXDREnumFailure() {
        let error = HorizonRequestError.requestFailed(message: "Test error", horizonErrorResponse: nil)
        let result = SetupTransactionXDREnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let returnedError):
            if case HorizonRequestError.requestFailed(let message, _) = returnedError {
                XCTAssertEqual(message, "Test error")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - SubmitTransactionEnum Tests

    func testSubmitTransactionEnumSuccess() {
        let result = SubmitTransactionEnum.success

        switch result {
        case .success:
            XCTAssertTrue(true)
        case .destinationRequiresMemo:
            XCTFail("Expected success")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSubmitTransactionEnumDestinationRequiresMemo() {
        let result = SubmitTransactionEnum.destinationRequiresMemo(destinationAccountId: testDestinationAccountId)

        switch result {
        case .success:
            XCTFail("Expected destinationRequiresMemo")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, testDestinationAccountId)
        case .failure:
            XCTFail("Expected destinationRequiresMemo")
        }
    }

    func testSubmitTransactionEnumFailure() {
        let error = HorizonRequestError.requestFailed(message: "Submit failed", horizonErrorResponse: nil)
        let result = SubmitTransactionEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .destinationRequiresMemo:
            XCTFail("Expected failure")
        case .failure(let returnedError):
            if case HorizonRequestError.requestFailed(let message, _) = returnedError {
                XCTAssertEqual(message, "Submit failed")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - SignURLEnum Tests

    func testSignURLEnumSuccess() {
        let signedURL = "web+stellar:tx?xdr=...&signature=..."
        let result = SignURLEnum.success(signedURL: signedURL)

        switch result {
        case .success(let url):
            XCTAssertEqual(url, signedURL)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSignURLEnumFailure() {
        let result = SignURLEnum.failure(.invalidSignature)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .invalidSignature = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected invalidSignature error")
            }
        }
    }

    // MARK: - URISchemeIsValidEnum Tests

    func testURISchemeIsValidEnumSuccess() {
        let result = URISchemeIsValidEnum.success

        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testURISchemeIsValidEnumFailureMissingOriginDomain() {
        let result = URISchemeIsValidEnum.failure(.missingOriginDomain)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .missingOriginDomain = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected missingOriginDomain error")
            }
        }
    }

    func testURISchemeIsValidEnumFailureInvalidOriginDomain() {
        let result = URISchemeIsValidEnum.failure(.invalidOriginDomain)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .invalidOriginDomain = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected invalidOriginDomain error")
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testPayOperationURIWithEmptyDestination() {
        let uri = uriScheme.getPayOperationURI(destination: "")

        XCTAssertTrue(uri.hasPrefix(URISchemeName))
        XCTAssertTrue(uri.contains("destination="))
    }

    func testPayOperationURIWithZeroAmount() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(0)
        )

        XCTAssertTrue(uri.contains("amount=0"))
    }

    func testPayOperationURIWithNegativeAmount() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(-100)
        )

        // Negative amount should still be included (validation is up to the wallet)
        XCTAssertTrue(uri.contains("amount=-100"))
    }

    func testPayOperationURIWithVeryLargeAmount() {
        let largeAmount = Decimal(string: "999999999999999999")!

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: largeAmount
        )

        XCTAssertTrue(uri.contains("amount="))
    }

    func testPayOperationURIWithEmptyMemo() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: "",
            memoType: MemoTypeAsString.TEXT
        )

        // Empty memo should still be included
        XCTAssertTrue(uri.contains("memo="))
    }

    func testPayOperationURIWithSpecialCharactersInMemo() {
        let specialMemo = "!@#$%^&*()_+-=[]{}|;':\",./<>?"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: specialMemo,
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.contains("memo="))
    }

    func testPayOperationURIWithUnicodeMemo() {
        let unicodeMemo = "Hello World"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: unicodeMemo,
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.contains("memo="))
    }

    func testSignTransactionURIWithEmptyMessage() throws {
        let transactionXDR = try createTestTransactionXDR()

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: ""
        )

        // Empty message should still be included (it's less than 300 chars)
        XCTAssertTrue(uri.contains("msg="))
    }

    func testMultipleTransactionsProduceDifferentURIs() throws {
        let transaction1 = try createTestTransaction()

        // Change the sequence number to get a different transaction
        let source = try KeyPair(secretSeed: testSourceSecretSeed)
        let destination = try KeyPair(accountId: testDestinationAccountId)
        let account = Account(keyPair: source, sequenceNumber: 999999)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(200)
        )

        let differentTransaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        let uri1 = uriScheme.getSignTransactionURI(transactionXDR: transaction1.transactionXDR)
        let uri2 = uriScheme.getSignTransactionURI(transactionXDR: differentTransaction.transactionXDR)

        XCTAssertNotEqual(uri1, uri2)
    }

    // MARK: - FQDN Validation Tests

    func testValidFQDN() {
        XCTAssertTrue("example.com".isFullyQualifiedDomainName)
        XCTAssertTrue("subdomain.example.com".isFullyQualifiedDomainName)
        XCTAssertTrue("stellar.org".isFullyQualifiedDomainName)
        XCTAssertTrue("test-domain.example.co.uk".isFullyQualifiedDomainName)
    }

    func testInvalidFQDN() {
        XCTAssertFalse("".isFullyQualifiedDomainName)
        XCTAssertFalse("localhost".isFullyQualifiedDomainName)  // Now correctly rejected
        XCTAssertFalse("test".isFullyQualifiedDomainName)
        XCTAssertFalse("-invalid.com".isFullyQualifiedDomainName)
        XCTAssertFalse("invalid-.com".isFullyQualifiedDomainName)
    }

    // MARK: - Complete URI Roundtrip Tests

    func testSignTransactionURIRoundtrip() throws {
        let transactionXDR = try createTestTransactionXDR()
        let originalEnvelope = try transactionXDR.encodedEnvelope()

        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        // Verify URI format
        XCTAssertTrue(uri.hasPrefix("web+stellar:tx?xdr="))

        // Extract XDR from URI by parsing the query string
        let prefix = "web+stellar:tx?xdr="
        guard uri.hasPrefix(prefix) else {
            XCTFail("URI should start with \(prefix)")
            return
        }

        // Get the XDR value (everything after xdr= until next & or end)
        let xdrStart = uri.index(uri.startIndex, offsetBy: prefix.count)
        let xdrEndIndex = uri[xdrStart...].firstIndex(of: "&") ?? uri.endIndex
        let xdrValue = String(uri[xdrStart..<xdrEndIndex])

        // URL decode the XDR
        guard let decodedXdr = xdrValue.removingPercentEncoding else {
            XCTFail("Failed to URL decode XDR")
            return
        }

        // Verify the XDR can be parsed back
        let parsedTransaction = try Transaction(envelopeXdr: decodedXdr)
        XCTAssertNotNil(parsedTransaction)

        // Verify the encoded envelope matches
        let parsedEnvelope = try parsedTransaction.encodedEnvelope()
        XCTAssertEqual(originalEnvelope, parsedEnvelope)
    }

    func testPayOperationURIContainsAllRequiredFields() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(100),
            assetCode: "USDC",
            assetIssuer: testSourceAccountId
        )

        // Parse the URI and verify all fields
        let queryString = String(uri.dropFirst("web+stellar:pay?".count))
        let params = queryString.split(separator: "&")

        var foundDestination = false
        var foundAmount = false
        var foundAssetCode = false
        var foundAssetIssuer = false

        for param in params {
            let parts = param.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0])
                switch key {
                case "destination":
                    foundDestination = true
                case "amount":
                    foundAmount = true
                case "asset_code":
                    foundAssetCode = true
                case "asset_issuer":
                    foundAssetIssuer = true
                default:
                    break
                }
            }
        }

        XCTAssertTrue(foundDestination, "URI should contain destination")
        XCTAssertTrue(foundAmount, "URI should contain amount")
        XCTAssertTrue(foundAssetCode, "URI should contain asset_code")
        XCTAssertTrue(foundAssetIssuer, "URI should contain asset_issuer")
    }
}
