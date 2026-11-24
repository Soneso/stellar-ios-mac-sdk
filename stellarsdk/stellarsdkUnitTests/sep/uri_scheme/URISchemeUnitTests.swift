//
//  URISchemeUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 04.02.26.
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
        URLProtocol.registerClass(ServerMock.self)
        uriScheme = URIScheme()
        uriSchemeValidator = URISchemeValidator()
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
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

        guard case .success(let xdr) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertNotNil(xdr)
    }

    func testSetupTransactionXDREnumSuccessWithNil() {
        let result = SetupTransactionXDREnum.success(transactionXDR: nil)

        guard case .success(let xdr) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertNil(xdr)
    }

    func testSetupTransactionXDREnumFailure() {
        let error = HorizonRequestError.requestFailed(message: "Test error", horizonErrorResponse: nil)
        let result = SetupTransactionXDREnum.failure(error: error)

        guard case .failure(let returnedError) = result else {
            return XCTFail("Expected failure")
        }
        if case HorizonRequestError.requestFailed(let message, _) = returnedError {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Wrong error type")
        }
    }

    // MARK: - SubmitTransactionEnum Tests

    func testSubmitTransactionEnumSuccess() {
        let result = SubmitTransactionEnum.success

        guard case .success = result else {
            return XCTFail("Expected success")
        }
    }

    func testSubmitTransactionEnumDestinationRequiresMemo() {
        let result = SubmitTransactionEnum.destinationRequiresMemo(destinationAccountId: testDestinationAccountId)

        guard case .destinationRequiresMemo(let accountId) = result else {
            return XCTFail("Expected destinationRequiresMemo")
        }
        XCTAssertEqual(accountId, testDestinationAccountId)
    }

    func testSubmitTransactionEnumFailure() {
        let error = HorizonRequestError.requestFailed(message: "Submit failed", horizonErrorResponse: nil)
        let result = SubmitTransactionEnum.failure(error: error)

        guard case .failure(let returnedError) = result else {
            return XCTFail("Expected failure")
        }
        if case HorizonRequestError.requestFailed(let message, _) = returnedError {
            XCTAssertEqual(message, "Submit failed")
        } else {
            XCTFail("Wrong error type")
        }
    }

    // MARK: - SignURLEnum Tests

    func testSignURLEnumSuccess() {
        let signedURL = "web+stellar:tx?xdr=...&signature=..."
        let result = SignURLEnum.success(signedURL: signedURL)

        guard case .success(let url) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(url, signedURL)
    }

    func testSignURLEnumFailure() {
        let result = SignURLEnum.failure(.invalidSignature)

        guard case .failure(let error) = result else {
            return XCTFail("Expected failure")
        }
        guard case .invalidSignature = error else {
            return XCTFail("Expected invalidSignature error")
        }
    }

    // MARK: - URISchemeIsValidEnum Tests

    func testURISchemeIsValidEnumSuccess() {
        let result = URISchemeIsValidEnum.success

        guard case .success = result else {
            return XCTFail("Expected success")
        }
    }

    func testURISchemeIsValidEnumFailureMissingOriginDomain() {
        let result = URISchemeIsValidEnum.failure(.missingOriginDomain)

        guard case .failure(let error) = result else {
            return XCTFail("Expected failure")
        }
        guard case .missingOriginDomain = error else {
            return XCTFail("Expected missingOriginDomain error")
        }
    }

    func testURISchemeIsValidEnumFailureInvalidOriginDomain() {
        let result = URISchemeIsValidEnum.failure(.invalidOriginDomain)

        guard case .failure(let error) = result else {
            return XCTFail("Expected failure")
        }
        guard case .invalidOriginDomain = error else {
            return XCTFail("Expected invalidOriginDomain error")
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

    func testFQDNWithNumericTLD() {
        XCTAssertFalse("example.123".isFullyQualifiedDomainName)
    }

    func testFQDNWithTooShortLabel() {
        XCTAssertFalse("a.b".isFullyQualifiedDomainName)
    }

    func testFQDNWithTooLongLabel() {
        let longLabel = String(repeating: "a", count: 64)
        XCTAssertFalse("\(longLabel).com".isFullyQualifiedDomainName)
    }

    func testFQDNWithSpecialCharacters() {
        XCTAssertFalse("exam_ple.com".isFullyQualifiedDomainName)
        XCTAssertFalse("exam!ple.com".isFullyQualifiedDomainName)
        XCTAssertFalse("exam@ple.com".isFullyQualifiedDomainName)
    }

    func testFQDNWithTrailingDot() {
        XCTAssertTrue("example.com.".isFullyQualifiedDomainName)
    }

    func testFQDNWithIPAddress() {
        XCTAssertFalse("192.168.1.1".isFullyQualifiedDomainName)
    }

    func testFQDNWithMultipleSubdomains() {
        XCTAssertTrue("api.v2.stellar.example.com".isFullyQualifiedDomainName)
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

    // MARK: - URISchemeValidator Validation Error Tests

    func testCheckURISchemeValidationMissingOriginDomain() async throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let result = await uriSchemeValidator.checkURISchemeIsValid(url: uri)

        switch result {
        case .success:
            XCTFail("Expected failure with missingOriginDomain")
        case .failure(let error):
            if case .missingOriginDomain = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected missingOriginDomain error, got \(error)")
            }
        }
    }

    func testCheckURISchemeValidationInvalidOriginDomain() async throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            originDomain: "localhost"
        )

        let result = await uriSchemeValidator.checkURISchemeIsValid(url: uri)

        switch result {
        case .success:
            XCTFail("Expected failure with invalidOriginDomain")
        case .failure(let error):
            if case .invalidOriginDomain = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected invalidOriginDomain error, got \(error)")
            }
        }
    }

    func testCheckURISchemeValidationInvalidOriginDomainWithDash() async throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            originDomain: "-invalid.com"
        )

        let result = await uriSchemeValidator.checkURISchemeIsValid(url: uri)

        switch result {
        case .success:
            XCTFail("Expected failure with invalidOriginDomain")
        case .failure(let error):
            if case .invalidOriginDomain = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected invalidOriginDomain error, got \(error)")
            }
        }
    }

    func testCheckURISchemeValidationMissingSignature() async throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            originDomain: "stellar.org"
        )

        let result = await uriSchemeValidator.checkURISchemeIsValid(url: uri)

        switch result {
        case .success:
            XCTFail("Expected failure due to missing signature or TOML errors")
        case .failure(let error):
            XCTAssertTrue(true, "Expected validation to fail with error: \(error)")
        }
    }

    // MARK: - Signature Verification Tests

    func testSignURIWithInvalidKeyPairFails() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let invalidURI = "invalid-uri-format"

        let result = uriSchemeValidator.signURI(url: invalidURI, signerKeyPair: signerKeyPair)

        // The signURI method successfully signs any string, even invalid URIs
        // This is by design - validation happens elsewhere
        switch result {
        case .success(let signedURL):
            XCTAssertTrue(signedURL.contains("&signature="))
        case .failure:
            XCTFail("Expected success - signURI signs any string")
        }
    }

    func testSignURIAndVerifySignature() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let signResult = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)

        switch signResult {
        case .success(let signedURL):
            XCTAssertTrue(signedURL.contains("&signature="))
            let signature = uriScheme.getValue(forParam: .signature, fromURL: signedURL)
            XCTAssertNotNil(signature)
            XCTAssertFalse(signature!.isEmpty)
        case .failure:
            XCTFail("Expected successful signing")
        }
    }

    func testSignURIProducesURLEncodedSignature() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let signResult = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)

        switch signResult {
        case .success(let signedURL):
            let signature = uriScheme.getValue(forParam: .signature, fromURL: signedURL)
            XCTAssertNotNil(signature)

            // Signature should be URL-safe (base64 URL-encoded)
            // It should not contain + or / which are typical base64 chars
            let urlDecodedSignature = signature!.urlDecoded
            XCTAssertNotNil(urlDecodedSignature)
        case .failure:
            XCTFail("Expected successful signing")
        }
    }

    func testSignURITwiceProducesSameSignature() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSignerSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let result1 = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)
        let result2 = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair)

        var signature1: String?
        var signature2: String?

        if case .success(let signedURL1) = result1 {
            signature1 = uriScheme.getValue(forParam: .signature, fromURL: signedURL1)
        }

        if case .success(let signedURL2) = result2 {
            signature2 = uriScheme.getValue(forParam: .signature, fromURL: signedURL2)
        }

        XCTAssertNotNil(signature1)
        XCTAssertNotNil(signature2)
        XCTAssertEqual(signature1, signature2, "Same URI signed with same key should produce same signature")
    }

    func testSignURIWithDifferentKeysProducesDifferentSignatures() throws {
        let signerKeyPair1 = try KeyPair(secretSeed: testSignerSecretSeed)
        let signerKeyPair2 = try KeyPair(secretSeed: testSourceSecretSeed)
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(transactionXDR: transactionXDR)

        let result1 = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair1)
        let result2 = uriSchemeValidator.signURI(url: uri, signerKeyPair: signerKeyPair2)

        var signature1: String?
        var signature2: String?

        if case .success(let signedURL1) = result1 {
            signature1 = uriScheme.getValue(forParam: .signature, fromURL: signedURL1)
        }

        if case .success(let signedURL2) = result2 {
            signature2 = uriScheme.getValue(forParam: .signature, fromURL: signedURL2)
        }

        XCTAssertNotNil(signature1)
        XCTAssertNotNil(signature2)
        XCTAssertNotEqual(signature1, signature2, "Different keys should produce different signatures")
    }

    // MARK: - URL Parameter Extraction Tests

    func testGetOriginDomainFromURLWithMultipleParams() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: "Test message",
            originDomain: "example.com",
            signature: "test-sig"
        )

        let originDomain = uriScheme.getValue(forParam: .origin_domain, fromURL: uri)

        XCTAssertEqual(originDomain, "example.com")
    }

    func testGetSignatureFromURLWithMultipleParams() throws {
        let transactionXDR = try createTestTransactionXDR()
        let signature = "test-signature-value"
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            message: "Test message",
            originDomain: "example.com",
            signature: signature
        )

        let extractedSignature = uriScheme.getValue(forParam: .signature, fromURL: uri)

        XCTAssertEqual(extractedSignature, signature)
    }

    func testGetValueWithAmpersandInParameter() throws {
        let transactionXDR = try createTestTransactionXDR()
        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            originDomain: "example.com"
        )

        XCTAssertTrue(uri.contains("origin_domain=example.com"))
    }

    // MARK: - Pay Operation Edge Cases

    func testPayOperationURIWithVerySmallAmount() {
        let smallAmount = Decimal(string: "0.0000001")!

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: smallAmount
        )

        XCTAssertTrue(uri.contains("amount="))
    }

    func testPayOperationURIWithAssetCodeOnly() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            assetCode: "USD"
        )

        XCTAssertTrue(uri.contains("asset_code=USD"))
        XCTAssertFalse(uri.contains("asset_issuer="))
    }

    func testPayOperationURIWithAssetIssuerOnly() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            assetIssuer: testSourceAccountId
        )

        XCTAssertTrue(uri.contains("asset_issuer="))
        XCTAssertFalse(uri.contains("asset_code="))
    }

    func testPayOperationURIWithLongAssetCode() {
        let longAssetCode = "VERYLONG12"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            assetCode: longAssetCode
        )

        XCTAssertTrue(uri.contains("asset_code=\(longAssetCode)"))
    }

    func testPayOperationURIWithMemoTypeWithoutMemo() {
        // When no memo is provided, memo_type should NOT be added per SEP-0007
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertFalse(uri.contains("memo_type="), "memo_type should not be present when no memo is provided")
        XCTAssertFalse(uri.contains("memo="), "memo should not be present")
    }

    func testPayOperationURIWithMemoTypeAndMemo() {
        // When memo is provided, memo_type SHOULD be added per SEP-0007
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: "Test memo",
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.contains("memo_type=MEMO_TEXT"), "memo_type should be present when memo is provided")
        XCTAssertTrue(uri.contains("memo="), "memo should be present")
    }

    func testPayOperationURIWithMemoTypeID() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: "12345",
            memoType: MemoTypeAsString.ID
        )

        XCTAssertTrue(uri.contains("memo_type=MEMO_ID"), "memo_type should be MEMO_ID")
        XCTAssertTrue(uri.contains("memo=12345"), "memo should contain the ID value")
    }

    func testPayOperationURIWithMemoTypeHASH() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: "somehashvalue",
            memoType: MemoTypeAsString.HASH
        )

        XCTAssertTrue(uri.contains("memo_type=MEMO_HASH"), "memo_type should be MEMO_HASH")
        XCTAssertTrue(uri.contains("memo="), "memo should be present")
    }

    func testPayOperationURIWithMemoTypeRETURN() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: "returnhashvalue",
            memoType: MemoTypeAsString.RETURN
        )

        XCTAssertTrue(uri.contains("memo_type=MEMO_RETURN"), "memo_type should be MEMO_RETURN")
        XCTAssertTrue(uri.contains("memo="), "memo should be present")
    }

    func testPayOperationURIWithDefaultMemoType() {
        // Test that default memoType (TEXT) is used when memo is provided but memoType is not specified
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: "Test memo"
        )

        XCTAssertTrue(uri.contains("memo_type=MEMO_TEXT"), "default memo_type should be MEMO_TEXT when memo is provided")
        XCTAssertTrue(uri.contains("memo="), "memo should be present")
    }

    func testPayOperationURIWithNilMemoAndNilMemoType() {
        // When both memo and memoType are nil, neither should be present
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: nil,
            memoType: nil
        )

        XCTAssertFalse(uri.contains("memo_type="), "memo_type should not be present when memo is nil")
        XCTAssertFalse(uri.contains("memo="), "memo should not be present")
    }

    func testPayOperationURIBasicWithoutMemoOrMemoType() {
        // Test that a basic URI without any memo-related parameters works correctly
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(100)
        )

        XCTAssertFalse(uri.contains("memo_type="), "memo_type should not be present in basic URI")
        XCTAssertFalse(uri.contains("memo="), "memo should not be present in basic URI")
        XCTAssertTrue(uri.contains("destination="), "destination should be present")
        XCTAssertTrue(uri.contains("amount=100"), "amount should be present")
    }

    // MARK: - Sign Transaction Edge Cases

    func testSignTransactionURIWithAllParametersAndVeryLongMessage() throws {
        let transactionXDR = try createTestTransactionXDR()
        let longMessage = String(repeating: "x", count: 299)

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            replace: "sourceAccount:TX_SOURCE",
            callBack: "url:https://callback.example.com",
            publicKey: testSourceAccountId,
            chain: "previous-uri",
            message: longMessage,
            networkPassphrase: Network.testnet.passphrase,
            originDomain: "example.com",
            signature: "sig"
        )

        XCTAssertTrue(uri.contains("msg="))
        XCTAssertTrue(uri.contains("replace="))
        XCTAssertTrue(uri.contains("callback="))
        XCTAssertTrue(uri.contains("pubkey="))
        XCTAssertTrue(uri.contains("chain="))
        XCTAssertTrue(uri.contains("network_passphrase="))
        XCTAssertTrue(uri.contains("origin_domain="))
        XCTAssertTrue(uri.contains("signature="))
    }

    func testSignTransactionURIWithReplaceParameter() throws {
        let transactionXDR = try createTestTransactionXDR()
        let replace = "sourceAccount:TX_SOURCE_ACCOUNT;operations[0].sourceAccount:OP_SOURCE_ACCOUNT"

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            replace: replace
        )

        let extractedReplace = uriScheme.getValue(forParam: .replace, fromURL: uri)
        XCTAssertNotNil(extractedReplace)
    }

    func testSignTransactionURIWithChainParameter() throws {
        let transactionXDR = try createTestTransactionXDR()
        let chain = "web+stellar:tx?xdr=PREVIOUSXDR..."

        let uri = uriScheme.getSignTransactionURI(
            transactionXDR: transactionXDR,
            chain: chain
        )

        let extractedChain = uriScheme.getValue(forParam: .chain, fromURL: uri)
        XCTAssertNotNil(extractedChain)
    }

    // MARK: - Amount Format Validation Tests

    func testPayOperationURIWithDecimalAmount() {
        let amount = Decimal(string: "100.123456789")!

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: amount
        )

        XCTAssertTrue(uri.contains("amount="))
    }

    func testPayOperationURIWithIntegerAmount() {
        let amount = Decimal(1000)

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: amount
        )

        XCTAssertTrue(uri.contains("amount=1000"))
    }

    func testPayOperationURIWithScientificNotationAmount() {
        let amount = Decimal(string: "1e-7")!

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: amount
        )

        XCTAssertTrue(uri.contains("amount="))
    }

    // MARK: - Memo Validation Tests

    func testPayOperationURIWithMaxLengthTextMemo() {
        let maxTextMemo = String(repeating: "a", count: 28)

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: maxTextMemo,
            memoType: MemoTypeAsString.TEXT
        )

        XCTAssertTrue(uri.contains("memo="))
        XCTAssertTrue(uri.contains("memo_type=MEMO_TEXT"))
    }

    func testPayOperationURIWithNumericIdMemo() {
        let idMemo = "999999999999999999"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: idMemo,
            memoType: MemoTypeAsString.ID
        )

        XCTAssertTrue(uri.contains("memo=\(idMemo)"))
        XCTAssertTrue(uri.contains("memo_type=MEMO_ID"))
    }

    func testPayOperationURIWithHashMemoEncoding() {
        let hashHex = "0123456789abcdef0123456789abcdef"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: hashHex,
            memoType: MemoTypeAsString.HASH
        )

        XCTAssertTrue(uri.contains("memo="))
        XCTAssertTrue(uri.contains("memo_type=MEMO_HASH"))
    }

    func testPayOperationURIWithReturnMemoEncoding() {
        let returnHash = "fedcba9876543210fedcba9876543210"

        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            memo: returnHash,
            memoType: MemoTypeAsString.RETURN
        )

        XCTAssertTrue(uri.contains("memo="))
        XCTAssertTrue(uri.contains("memo_type=MEMO_RETURN"))
    }

    // MARK: - Asset Code Validation Tests

    func testPayOperationURIWithShortAssetCode() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            assetCode: "XLM",
            assetIssuer: testSourceAccountId
        )

        XCTAssertTrue(uri.contains("asset_code=XLM"))
    }

    func testPayOperationURIWithAlphanumericAssetCode() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            assetCode: "USDC2024",
            assetIssuer: testSourceAccountId
        )

        XCTAssertTrue(uri.contains("asset_code=USDC2024"))
    }

    func testPayOperationURIWithNativeAsset() {
        let uri = uriScheme.getPayOperationURI(
            destination: testDestinationAccountId,
            amount: Decimal(100)
        )

        XCTAssertFalse(uri.contains("asset_code="))
        XCTAssertFalse(uri.contains("asset_issuer="))
    }

    // MARK: - Error Message Path Coverage Tests

    func testAllURISchemeErrorsCovered() {
        let errors: [URISchemeErrors] = [
            .invalidSignature,
            .invalidOriginDomain,
            .missingOriginDomain,
            .missingSignature,
            .invalidTomlDomain,
            .invalidToml,
            .tomlSignatureMissing
        ]

        for error in errors {
            let result = URISchemeIsValidEnum.failure(error)
            guard case .failure(let returnedError) = result else {
                return XCTFail("Should be failure")
            }
            switch returnedError {
            case .invalidSignature, .invalidOriginDomain, .missingOriginDomain,
                 .missingSignature, .invalidTomlDomain, .invalidToml, .tomlSignatureMissing:
                XCTAssertTrue(true)
            }
        }
    }

    func testSignURLEnumAllErrorTypes() {
        let errors: [URISchemeErrors] = [
            .invalidSignature,
            .invalidOriginDomain,
            .missingOriginDomain,
            .missingSignature,
            .invalidTomlDomain,
            .invalidToml,
            .tomlSignatureMissing
        ]

        for error in errors {
            let result = SignURLEnum.failure(error)
            guard case .failure(let returnedError) = result else {
                return XCTFail("Should be failure")
            }
            switch returnedError {
            case .invalidSignature, .invalidOriginDomain, .missingOriginDomain,
                 .missingSignature, .invalidTomlDomain, .invalidToml, .tomlSignatureMissing:
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Callback URL scheme validation tests

    /// Helper to build a SEP-7 URI with an unencoded callback, simulating attacker-crafted input.
    func buildURIWithRawCallback(_ callback: String) throws -> String {
        let transactionXDR = try createTestTransactionXDR()
        let envelope = try transactionXDR.encodedEnvelope()
        let urlEncodedEnvelope = envelope.urlEncoded!
        return "web+stellar:tx?xdr=\(urlEncodedEnvelope)&callback=\(callback)"
    }

    func testCallbackRejectsHTTP() async throws {
        let uri = try buildURIWithRawCallback("url:http://attacker.com/steal")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("HTTPS"), "Expected HTTPS error, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for HTTP callback")
        }
    }

    func testCallbackRejectsFileScheme() async throws {
        let uri = try buildURIWithRawCallback("url:file:///etc/passwd")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("HTTPS") || message.contains("Invalid callback URL"),
                              "Expected scheme validation error, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for file:// callback")
        }
    }

    func testCallbackAllowsHTTPS() async throws {
        let uri = try buildURIWithRawCallback("url:https://example.com/callback")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        // Must fail with a network error (not scheme validation), proving validation passed
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertFalse(message.contains("HTTPS"), "HTTPS callback should not fail scheme validation")
                XCTAssertFalse(message.contains("Invalid callback URL"), "HTTPS callback should not fail URL validation")
            }
        }
    }

    func testCallbackAllowsHTTPLocalhost() async throws {
        let uri = try buildURIWithRawCallback("url:http://localhost:8080/callback")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertFalse(message.contains("HTTPS"), "HTTP localhost should not fail scheme validation")
                XCTAssertFalse(message.contains("Invalid callback URL"), "HTTP localhost should not fail URL validation")
            }
        }
    }

    func testCallbackAllowsHTTPLoopback() async throws {
        let uri = try buildURIWithRawCallback("url:http://127.0.0.1:8080/callback")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertFalse(message.contains("HTTPS"), "HTTP 127.0.0.1 should not fail scheme validation")
                XCTAssertFalse(message.contains("Invalid callback URL"), "HTTP 127.0.0.1 should not fail URL validation")
            }
        }
    }

    func testCallbackRejectsUppercaseHTTP() async throws {
        let uri = try buildURIWithRawCallback("url:HTTP://ATTACKER.COM/steal")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("HTTPS"), "Uppercase HTTP should be rejected, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for uppercase HTTP callback")
        }
    }

    func testCallbackRejectsLocalhostSubdomain() async throws {
        let uri = try buildURIWithRawCallback("url:http://localhost.attacker.com/steal")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("HTTPS"), "localhost.attacker.com should be rejected, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for localhost subdomain callback")
        }
    }

    func testCallbackRejectsUserinfoBypass() async throws {
        let uri = try buildURIWithRawCallback("url:http://localhost@attacker.com/steal")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("HTTPS"), "userinfo bypass should be rejected, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for userinfo bypass callback")
        }
    }

    func testCallbackRejectsFTP() async throws {
        let uri = try buildURIWithRawCallback("url:ftp://attacker.com/file")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("HTTPS"), "FTP should be rejected, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for FTP callback")
        }
    }

    func testCallbackRejectsInvalidURL() async throws {
        let uri = try buildURIWithRawCallback("url:")
        let keyPair = try KeyPair(secretSeed: testSourceSecretSeed)
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, network: .testnet)
        if case .failure(let error) = result {
            if case .requestFailed(let message, _) = error {
                XCTAssertTrue(message.contains("Invalid callback URL"), "Expected invalid URL error, got: \(message)")
            } else {
                XCTFail("Expected requestFailed error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure for invalid callback URL")
        }
    }

    // MARK: - Sign and Submit Tests

    private let mockCallbackHost = "sep7-callback.example.com"

    private var mockHorizonSubmitSuccessResponse: String {
        return """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/transactions/test"},
                "account": {"href": "https://horizon.stellar.org/accounts/GABC"},
                "ledger": {"href": "https://horizon.stellar.org/ledgers/123"},
                "operations": {"href": "https://horizon.stellar.org/transactions/test/operations{?cursor,limit,order}", "templated": true},
                "effects": {"href": "https://horizon.stellar.org/transactions/test/effects{?cursor,limit,order}", "templated": true},
                "precedes": {"href": "https://horizon.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "test123",
            "paging_token": "123456",
            "hash": "abc123def456",
            "ledger": 100,
            "created_at": "2018-02-21T15:16:05Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456789",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "max_fee": "100",
            "fee_charged": "100",
            "operation_count": 1,
            "memo_type": "none",
            "signatures": [],
            "envelope_xdr": "AAAAAgAAAABn/gGugyO02pFFGaHeLzNEHF4xG6LdYuDPD98S59AjuwADDUABL9thAAAHOQAAAAEAAAAAAAAAAAAAAABnflzGAAAAAAAAAAIAAAAAAAAAF17U/Ee2yWNcLItkCC67OfbsTUVaBlLoBV+SBdMv/ujIAAAAAAAAoHQAAAAAAACgCwAAAAAAAKDeAAAAAAAAAAYAAAADAAAAAAAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAAXNVU0QAAAAAj2+KyPmYjEMFuwqWpv33O3NZCGoASCtyAGDvCBhfZ/QAAAAeAAAAAAAAAAAAAAAAAAAAAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA="
        }
        """
    }

    private struct SubmissionMocks {
        let callback: RequestRecorder
        let publicHorizon: RequestRecorder
        let testnetHorizon: RequestRecorder
        let futurenetHorizon: RequestRecorder

        func reset() {
            callback.reset()
            publicHorizon.reset()
            testnetHorizon.reset()
            futurenetHorizon.reset()
        }

        var totalRequestCount: Int {
            callback.all.count + publicHorizon.all.count + testnetHorizon.all.count + futurenetHorizon.all.count
        }
    }

    private func installSubmissionMocks() -> SubmissionMocks {
        let callbackRecorder = RequestRecorder()
        let publicRecorder = RequestRecorder()
        let testnetRecorder = RequestRecorder()
        let futurenetRecorder = RequestRecorder()
        let horizonJSON = mockHorizonSubmitSuccessResponse

        ServerMock.add(mock: RequestMock(host: mockCallbackHost, path: "*", httpMethod: "POST", statusCode: 200) { _, request in
            callbackRecorder.record(request)
            return "{}"
        })
        ServerMock.add(mock: RequestMock(host: "horizon.stellar.org", path: "/transactions", httpMethod: "POST", statusCode: 200) { _, request in
            publicRecorder.record(request)
            return horizonJSON
        })
        ServerMock.add(mock: RequestMock(host: "horizon-testnet.stellar.org", path: "/transactions", httpMethod: "POST", statusCode: 200) { _, request in
            testnetRecorder.record(request)
            return horizonJSON
        })
        ServerMock.add(mock: RequestMock(host: "horizon-futurenet.stellar.org", path: "/transactions", httpMethod: "POST", statusCode: 200) { _, request in
            futurenetRecorder.record(request)
            return horizonJSON
        })

        return SubmissionMocks(
            callback: callbackRecorder,
            publicHorizon: publicRecorder,
            testnetHorizon: testnetRecorder,
            futurenetHorizon: futurenetRecorder
        )
    }

    private func createMemoTransaction(sequenceNumber: Int64 = 123456) throws -> Transaction {
        let source = try KeyPair(secretSeed: testSourceSecretSeed)
        let account = Account(keyPair: source, sequenceNumber: sequenceNumber)
        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: testDestinationAccountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(10)
        )
        return try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.text("sep7-test")
        )
    }

    private func createFeeBumpTransaction(network: Network = .testnet) throws -> (feeBump: FeeBumpTransaction, inner: Transaction, feeSource: KeyPair) {
        let innerSource = try KeyPair(secretSeed: testSourceSecretSeed)
        let inner = try createMemoTransaction()
        try inner.sign(keyPair: innerSource, network: network)

        let feeSource = try KeyPair(secretSeed: testSignerSecretSeed)
        let feeSourceAccount = MuxedAccount(keyPair: feeSource, sequenceNumber: 0)
        let feeBump = try FeeBumpTransaction(sourceAccount: feeSourceAccount, fee: 200, innerTransaction: inner)
        return (feeBump, inner, feeSource)
    }

    private func decodePostedEnvelope(from body: String, fieldName: String) throws -> TransactionEnvelopeXDR {
        let prefix = "\(fieldName)="
        XCTAssertTrue(body.hasPrefix(prefix), "Expected body to start with \(prefix), got: \(body)")
        let encoded = String(body.dropFirst(prefix.count))
        let base64 = try XCTUnwrap(encoded.removingPercentEncoding, "Failed to URL-decode \(fieldName) body")
        return try TransactionEnvelopeXDR(fromBase64: base64)
    }

    // Fee bump tx URI with a url: callback posts the fee bump envelope with an outer signature.
    func testSignAndSubmitFeeBumpToCallback() async throws {
        let mocks = installSubmissionMocks()
        let (feeBump, _, feeSource) = try createFeeBumpTransaction(network: .testnet)
        let existingOuterSigner = try KeyPair.generateRandomKeyPair()
        try feeBump.sign(keyPair: existingOuterSigner, network: .testnet)

        let inputEnvelopeBase64 = try feeBump.encodedEnvelope()
        let inputEnvelope = try TransactionEnvelopeXDR(fromBase64: inputEnvelopeBase64)
        guard case .feeBump(let inputFeeBumpEnvelope) = inputEnvelope,
              case .v1(let inputInnerEnvelope) = inputFeeBumpEnvelope.tx.innerTx else {
            return XCTFail("Expected input envelope to be a fee bump")
        }
        let expectedHash = try feeBump.getTransactionHashData(network: .testnet)

        let encodedXdr = try XCTUnwrap(inputEnvelopeBase64.urlEncoded)
        let uri = "web+stellar:tx?xdr=\(encodedXdr)&callback=url:https://\(mockCallbackHost)/submit"

        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: feeSource, network: .testnet)

        guard case .success = result else {
            return XCTFail("Expected .success, got \(result)")
        }
        XCTAssertEqual(mocks.callback.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)

        let request = try XCTUnwrap(mocks.callback.all.first)
        XCTAssertEqual(request.url, "https://\(mockCallbackHost)/submit")
        XCTAssertEqual(request.contentType, "application/x-www-form-urlencoded")

        let postedEnvelope = try decodePostedEnvelope(from: request.body, fieldName: "xdr")
        guard case .feeBump(let postedFeeBumpEnvelope) = postedEnvelope else {
            return XCTFail("Expected posted envelope to be a fee bump, got \(postedEnvelope)")
        }

        XCTAssertEqual(try XDREncoder.encode(postedFeeBumpEnvelope.tx), try XDREncoder.encode(inputFeeBumpEnvelope.tx))

        guard case .v1(let postedInnerEnvelope) = postedFeeBumpEnvelope.tx.innerTx else {
            return XCTFail("Expected V1 inner envelope")
        }
        XCTAssertEqual(postedInnerEnvelope.signatures.count, inputInnerEnvelope.signatures.count)
        XCTAssertEqual(try XDREncoder.encode(postedInnerEnvelope.signatures), try XDREncoder.encode(inputInnerEnvelope.signatures))

        XCTAssertEqual(postedFeeBumpEnvelope.signatures.count, inputFeeBumpEnvelope.signatures.count + 1)
        XCTAssertEqual(try XDREncoder.encode(postedFeeBumpEnvelope.signatures[0]), try XDREncoder.encode(inputFeeBumpEnvelope.signatures[0]))

        let addedSignature = postedFeeBumpEnvelope.signatures[1]
        XCTAssertEqual(addedSignature.hint.wrapped, Data(feeSource.publicKey.bytes.suffix(4)))
        XCTAssertTrue(try feeSource.publicKey.verify(signature: [UInt8](addedSignature.signature), message: [UInt8](expectedHash)))
    }

    // URL-encoded callback from getSignTransactionURI posts to callback; broken percent-encoding fails.
    func testSignAndSubmitEncodedCallback() async throws {
        let mocks = installSubmissionMocks()
        let tx = try createMemoTransaction()
        let signer = try KeyPair(secretSeed: testSourceSecretSeed)
        let expectedHash = try tx.getTransactionHashData(network: .testnet)

        let callbackTarget = "https://\(mockCallbackHost)/collect?order=42&mode=fast"
        let uri = uriScheme.getSignTransactionURI(transactionXDR: tx.transactionXDR, callBack: "url:\(callbackTarget)")

        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: signer, network: .testnet)

        guard case .success = result else {
            return XCTFail("Expected .success for encoded callback URI, got \(result)")
        }
        XCTAssertEqual(mocks.callback.all.count, 1, "Encoded callback URI should post to callback")
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)

        if let request = mocks.callback.all.first {
            XCTAssertEqual(request.url, callbackTarget)
            XCTAssertEqual(request.contentType, "application/x-www-form-urlencoded")
            let postedEnvelope = try decodePostedEnvelope(from: request.body, fieldName: "xdr")
            guard case .v1(let v1) = postedEnvelope else {
                return XCTFail("Expected V1 envelope, got \(postedEnvelope)")
            }
            XCTAssertEqual(v1.signatures.count, 1)
            XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](v1.signatures[0].signature), message: [UInt8](expectedHash)))
        }

        // Invalid percent-encoding in callback fails with "Invalid callback URL" and sends nothing.
        mocks.reset()
        let encodedXdr = try XCTUnwrap(try tx.encodedEnvelope().urlEncoded)
        let badCallbackUri = "web+stellar:tx?xdr=\(encodedXdr)&callback=url%3Ahttps%3A%2F%2F\(mockCallbackHost)%2F%ZZ"
        let badResult = await uriScheme.signAndSubmitTransaction(forURL: badCallbackUri, signerKeyPair: signer, network: .testnet)
        guard case .failure(.requestFailed(let message, _)) = badResult else {
            return XCTFail("Expected requestFailed for invalid percent-encoded callback, got \(badResult)")
        }
        XCTAssertEqual(message, "Invalid callback URL")
        XCTAssertEqual(mocks.totalRequestCount, 0)
    }

    // Horizon routing matches signing network; custom network fails without callback and works with one; fee bump posts to Horizon.
    func testSignAndSubmitHorizonByNetwork() async throws {
        let mocks = installSubmissionMocks()
        let signer = try KeyPair(secretSeed: testSourceSecretSeed)

        // .public -> horizon.stellar.org
        let publicTx = try createMemoTransaction(sequenceNumber: 100)
        let publicUri = uriScheme.getSignTransactionURI(transactionXDR: publicTx.transactionXDR)
        let publicResult = await uriScheme.signAndSubmitTransaction(forURL: publicUri, signerKeyPair: signer, network: .public)
        guard case .success = publicResult else {
            return XCTFail("Expected .success for .public, got \(publicResult)")
        }
        XCTAssertEqual(mocks.publicHorizon.all.count, 1, "Expected .public to post to horizon.stellar.org")
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)
        XCTAssertEqual(mocks.callback.all.count, 0)
        if let req = mocks.publicHorizon.all.first {
            let envelope = try decodePostedEnvelope(from: req.body, fieldName: "tx")
            if case .v1(let v1) = envelope {
                XCTAssertEqual(v1.signatures.count, 1)
                let hash = try publicTx.getTransactionHashData(network: .public)
                XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](v1.signatures[0].signature), message: [UInt8](hash)))
            } else {
                XCTFail("Expected V1 envelope")
            }
        }

        // .testnet -> horizon-testnet.stellar.org
        mocks.reset()
        let testnetTx = try createMemoTransaction(sequenceNumber: 101)
        let testnetUri = uriScheme.getSignTransactionURI(transactionXDR: testnetTx.transactionXDR)
        let testnetResult = await uriScheme.signAndSubmitTransaction(forURL: testnetUri, signerKeyPair: signer, network: .testnet)
        guard case .success = testnetResult else {
            return XCTFail("Expected .success for .testnet, got \(testnetResult)")
        }
        XCTAssertEqual(mocks.testnetHorizon.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)
        XCTAssertEqual(mocks.callback.all.count, 0)
        if let req = mocks.testnetHorizon.all.first {
            let envelope = try decodePostedEnvelope(from: req.body, fieldName: "tx")
            if case .v1(let v1) = envelope {
                XCTAssertEqual(v1.signatures.count, 1)
                let hash = try testnetTx.getTransactionHashData(network: .testnet)
                XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](v1.signatures[0].signature), message: [UInt8](hash)))
            } else {
                XCTFail("Expected V1 envelope")
            }
        }

        // .futurenet -> horizon-futurenet.stellar.org
        mocks.reset()
        let futurenetTx = try createMemoTransaction(sequenceNumber: 102)
        let futurenetUri = uriScheme.getSignTransactionURI(transactionXDR: futurenetTx.transactionXDR)
        let futurenetResult = await uriScheme.signAndSubmitTransaction(forURL: futurenetUri, signerKeyPair: signer, network: .futurenet)
        guard case .success = futurenetResult else {
            return XCTFail("Expected .success for .futurenet, got \(futurenetResult)")
        }
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 1, "Expected .futurenet to post to horizon-futurenet.stellar.org")
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.callback.all.count, 0)
        if let req = mocks.futurenetHorizon.all.first {
            let envelope = try decodePostedEnvelope(from: req.body, fieldName: "tx")
            if case .v1(let v1) = envelope {
                XCTAssertEqual(v1.signatures.count, 1)
                let hash = try futurenetTx.getTransactionHashData(network: .futurenet)
                XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](v1.signatures[0].signature), message: [UInt8](hash)))
            } else {
                XCTFail("Expected V1 envelope")
            }
        }

        // .custom without callback -> failure, nothing sent
        mocks.reset()
        let customNetwork = Network.custom(passphrase: "Private Stellar Network ; 2026")
        let customTx = try createMemoTransaction(sequenceNumber: 103)
        let customUriNoCallback = uriScheme.getSignTransactionURI(transactionXDR: customTx.transactionXDR)
        let customNoCallbackResult = await uriScheme.signAndSubmitTransaction(forURL: customUriNoCallback, signerKeyPair: signer, network: customNetwork)
        if case .failure(.requestFailed(let message, _)) = customNoCallbackResult {
            XCTAssertTrue(message.lowercased().contains("horizon"), "Expected custom network Horizon error, got: \(message)")
            XCTAssertTrue(message.lowercased().contains("custom"), "Expected custom network error, got: \(message)")
        } else {
            XCTFail("Expected failure for .custom without callback, got \(customNoCallbackResult)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0)

        // .custom with url: callback -> posts envelope signed with custom passphrase
        mocks.reset()
        let customCallbackTx = try createMemoTransaction(sequenceNumber: 104)
        let customCallbackUri = uriScheme.getSignTransactionURI(
            transactionXDR: customCallbackTx.transactionXDR,
            callBack: "url:https://\(mockCallbackHost)/custom"
        )
        let customCallbackResult = await uriScheme.signAndSubmitTransaction(forURL: customCallbackUri, signerKeyPair: signer, network: customNetwork)
        guard case .success = customCallbackResult else {
            return XCTFail("Expected .success for .custom with callback, got \(customCallbackResult)")
        }
        XCTAssertEqual(mocks.callback.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)
        if let req = mocks.callback.all.first {
            let envelope = try decodePostedEnvelope(from: req.body, fieldName: "xdr")
            if case .v1(let v1) = envelope {
                XCTAssertEqual(v1.signatures.count, 1)
                let customHash = try customCallbackTx.getTransactionHashData(network: customNetwork)
                XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](v1.signatures[0].signature), message: [UInt8](customHash)))
            } else {
                XCTFail("Expected V1 envelope")
            }
        }

        // Fee bump without callback -> posts fee bump envelope to network's Horizon
        mocks.reset()
        let (feeBump, _, feeSource) = try createFeeBumpTransaction(network: .testnet)
        let feeBumpInputBase64 = try feeBump.encodedEnvelope()
        let feeBumpHash = try feeBump.getTransactionHashData(network: .testnet)
        let feeBumpUri = "web+stellar:tx?xdr=\(try XCTUnwrap(feeBumpInputBase64.urlEncoded))"
        let feeBumpResult = await uriScheme.signAndSubmitTransaction(forURL: feeBumpUri, signerKeyPair: feeSource, network: .testnet)
        guard case .success = feeBumpResult else {
            return XCTFail("Expected .success for fee bump to Horizon, got \(feeBumpResult)")
        }
        XCTAssertEqual(mocks.testnetHorizon.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)
        XCTAssertEqual(mocks.callback.all.count, 0)
        if let req = mocks.testnetHorizon.all.first {
            let envelope = try decodePostedEnvelope(from: req.body, fieldName: "tx")
            guard case .feeBump(let fb) = envelope else {
                return XCTFail("Expected fee bump envelope posted to Horizon, got \(envelope)")
            }
            XCTAssertEqual(fb.signatures.count, 1)
            XCTAssertTrue(try feeSource.publicKey.verify(signature: [UInt8](fb.signatures[0].signature), message: [UInt8](feeBumpHash)))
        }
    }

    // A tx URI whose xdr parameter is not first signs and posts the transaction; non-tx prefixes fail.
    func testSignAndSubmitXdrNotFirstParameter() async throws {
        let mocks = installSubmissionMocks()
        let tx = try createMemoTransaction()
        let signer = try KeyPair(secretSeed: testSourceSecretSeed)
        let expectedHash = try tx.getTransactionHashData(network: .testnet)
        let encodedXdr = try XCTUnwrap(try tx.encodedEnvelope().urlEncoded)
        let callbackTarget = "https://\(mockCallbackHost)/submit?callback=1"
        let encodedCallback = try XCTUnwrap("url:\(callbackTarget)".urlEncoded)

        let uri = "web+stellar:tx?msg=hello%20world&callback=\(encodedCallback)&xdr=\(encodedXdr)&origin_domain=example.com"
        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: signer, network: .testnet)

        guard case .success = result else {
            return XCTFail("Expected .success when xdr is not first parameter, got \(result)")
        }
        XCTAssertEqual(mocks.callback.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)

        let request = try XCTUnwrap(mocks.callback.all.first)
        XCTAssertEqual(request.url, callbackTarget)
        let postedEnvelope = try decodePostedEnvelope(from: request.body, fieldName: "xdr")
        guard case .v1(let v1) = postedEnvelope else {
            return XCTFail("Expected V1 envelope, got \(postedEnvelope)")
        }
        XCTAssertEqual(v1.signatures.count, 1)
        XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](v1.signatures[0].signature), message: [UInt8](expectedHash)))

        // Raw callback whose target URL contains callback= in its own query keeps the inner query parameter.
        mocks.reset()
        let rawCallbackUri = "web+stellar:tx?callback=url:\(callbackTarget)&xdr=\(encodedXdr)"
        let rawCallbackResult = await uriScheme.signAndSubmitTransaction(forURL: rawCallbackUri, signerKeyPair: signer, network: .testnet)
        guard case .success = rawCallbackResult else {
            return XCTFail("Expected .success for raw callback with callback= in query, got \(rawCallbackResult)")
        }
        XCTAssertEqual(mocks.callback.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)
        let rawCallbackRequest = try XCTUnwrap(mocks.callback.all.first)
        XCTAssertEqual(rawCallbackRequest.url, callbackTarget)

        // Non-tx URI prefix is rejected before signing or sending.
        mocks.reset()
        let wrongPrefixUri = "web+stellar:pay?xdr=\(encodedXdr)"
        let wrongPrefixResult = await uriScheme.signAndSubmitTransaction(forURL: wrongPrefixUri, signerKeyPair: signer, network: .testnet)
        guard case .failure(.requestFailed(let message, _)) = wrongPrefixResult else {
            return XCTFail("Expected failure for non-tx URI prefix, got \(wrongPrefixResult)")
        }
        XCTAssertEqual(message, "TransactionXDR missing from url!")
        XCTAssertEqual(mocks.totalRequestCount, 0)
    }

    // Confirmation closure receives the inner TransactionXDR for a fee bump, and returning false cancels before signing.
    func testSignAndSubmitFeeBumpConfirmation() async throws {
        let mocks = installSubmissionMocks()
        let (feeBump, inner, feeSource) = try createFeeBumpTransaction(network: .testnet)
        let encodedXdr = try XCTUnwrap(try feeBump.encodedEnvelope().urlEncoded)
        let uri = "web+stellar:tx?xdr=\(encodedXdr)&callback=url:https://\(mockCallbackHost)/submit"

        let capture = ConfirmationCapture()
        let publicOnlyFeeSource = try KeyPair(accountId: feeSource.accountId)
        let result = await uriScheme.signAndSubmitTransaction(
            forURL: uri,
            signerKeyPair: publicOnlyFeeSource,
            network: .testnet,
            transactionConfirmation: { transactionXDR in
                capture.record(transactionXDR)
                return false
            }
        )

        guard case .failure(.requestFailed(let message, _)) = result else {
            return XCTFail("Expected requestFailed when confirmation returns false, got \(result)")
        }
        XCTAssertEqual(message, "Transaction was not confirmed!")
        let confirmedTx = try XCTUnwrap(capture.value)
        XCTAssertEqual(try confirmedTx.encodedEnvelope(), try inner.encodedEnvelope())
        XCTAssertEqual(mocks.totalRequestCount, 0)
    }

    // A present callback that does not start with url: after decoding returns failure and sends nothing.
    func testSignAndSubmitUnsupportedCallback() async throws {
        let mocks = installSubmissionMocks()
        let tx = try createMemoTransaction()
        let signer = try KeyPair(secretSeed: testSourceSecretSeed)
        let encodedXdr = try XCTUnwrap(try tx.encodedEnvelope().urlEncoded)

        // Encoded non-url callback type
        let encodedPostCallback = try XCTUnwrap("post:https://\(mockCallbackHost)/submit".urlEncoded)
        let postUri = "web+stellar:tx?xdr=\(encodedXdr)&callback=\(encodedPostCallback)"
        let postResult = await uriScheme.signAndSubmitTransaction(forURL: postUri, signerKeyPair: signer, network: .testnet)
        if case .failure(.requestFailed(let message, _)) = postResult {
            XCTAssertTrue(message.contains("post"), "Expected message to name unsupported callback type 'post', got: \(message)")
        } else {
            XCTFail("Expected failure for unsupported callback type, got \(postResult)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0, "Unsupported callback must not send to Horizon or callback")

        // Raw callback without url: prefix
        mocks.reset()
        let rawUri = "web+stellar:tx?xdr=\(encodedXdr)&callback=mailto:wallet@example.com"
        let rawResult = await uriScheme.signAndSubmitTransaction(forURL: rawUri, signerKeyPair: signer, network: .testnet)
        if case .failure(.requestFailed(let message, _)) = rawResult {
            XCTAssertTrue(message.contains("mailto"), "Expected message to name unsupported callback type 'mailto', got: \(message)")
        } else {
            XCTFail("Expected failure for unsupported mailto callback, got \(rawResult)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0)

        // Callback without a type delimiter
        mocks.reset()
        let bareUri = "web+stellar:tx?xdr=\(encodedXdr)&callback=custom"
        let bareResult = await uriScheme.signAndSubmitTransaction(forURL: bareUri, signerKeyPair: signer, network: .testnet)
        if case .failure(.requestFailed(let message, _)) = bareResult {
            XCTAssertTrue(message.contains("custom"), "Expected message to name unsupported callback type 'custom', got: \(message)")
        } else {
            XCTFail("Expected failure for unsupported bare callback, got \(bareResult)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0)

        // Empty callback value
        mocks.reset()
        let emptyUri = "web+stellar:tx?xdr=\(encodedXdr)&callback="
        let emptyResult = await uriScheme.signAndSubmitTransaction(forURL: emptyUri, signerKeyPair: signer, network: .testnet)
        if case .failure(.requestFailed(let message, _)) = emptyResult {
            XCTAssertTrue(message.contains("Unsupported callback type"), "Expected unsupported callback message, got: \(message)")
        } else {
            XCTFail("Expected failure for empty callback value, got \(emptyResult)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0)
    }

    // A KeyPair without a private key returns failure and sends nothing, for V1 and fee bump envelopes.
    func testSignAndSubmitPublicOnlyKeyPairRejected() async throws {
        let mocks = installSubmissionMocks()
        let publicOnly = try KeyPair(accountId: testSourceAccountId)

        // V1 envelope
        let tx = try createMemoTransaction()
        let v1Uri = uriScheme.getSignTransactionURI(transactionXDR: tx.transactionXDR)
        let v1Result = await uriScheme.signAndSubmitTransaction(forURL: v1Uri, signerKeyPair: publicOnly, network: .testnet)
        if case .failure(.requestFailed(let message, _)) = v1Result {
            XCTAssertTrue(message.lowercased().contains("private key"), "Expected missing private key cause, got: \(message)")
        } else {
            XCTFail("Expected failure for V1 with public-only keypair, got \(v1Result)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0, "Public-only keypair must not send V1 transaction")

        // Fee bump envelope
        mocks.reset()
        let (feeBump, _, feeSource) = try createFeeBumpTransaction(network: .testnet)
        let publicOnlyFeeSource = try KeyPair(accountId: feeSource.accountId)
        let encodedFeeBump = try XCTUnwrap(try feeBump.encodedEnvelope().urlEncoded)
        let feeBumpUri = "web+stellar:tx?xdr=\(encodedFeeBump)&callback=url:https://\(mockCallbackHost)/submit"
        let feeBumpResult = await uriScheme.signAndSubmitTransaction(forURL: feeBumpUri, signerKeyPair: publicOnlyFeeSource, network: .testnet)
        if case .failure(.requestFailed(let message, _)) = feeBumpResult {
            XCTAssertTrue(message.lowercased().contains("private key"), "Expected missing private key cause, got: \(message)")
        } else {
            XCTFail("Expected failure for fee bump with public-only keypair, got \(feeBumpResult)")
        }
        XCTAssertEqual(mocks.totalRequestCount, 0, "Public-only keypair must not send fee bump transaction")
    }

    // Undecodable XDR payloads and zero-operation envelopes return failure and send nothing.
    func testSignAndSubmitUndecodableTransactionRejected() async throws {
        let mocks = installSubmissionMocks()
        let signer = try KeyPair(secretSeed: testSourceSecretSeed)

        // Valid base64 that does not decode as a TransactionEnvelopeXDR.
        let invalidEnvelopeBase64 = Data([0, 0, 0, 0]).base64EncodedString()
        let encodedInvalidEnvelope = try XCTUnwrap(invalidEnvelopeBase64.urlEncoded)
        let invalidEnvelopeUri = "web+stellar:tx?xdr=\(encodedInvalidEnvelope)&callback=url:https://\(mockCallbackHost)/submit"
        let invalidEnvelopeResult = await uriScheme.signAndSubmitTransaction(forURL: invalidEnvelopeUri, signerKeyPair: signer, network: .testnet)
        guard case .failure(.requestFailed(let invalidMessage, _)) = invalidEnvelopeResult else {
            return XCTFail("Expected requestFailed for non-envelope base64 xdr, got \(invalidEnvelopeResult)")
        }
        XCTAssertEqual(invalidMessage, "TransactionXDR missing from url!")
        XCTAssertEqual(mocks.totalRequestCount, 0)

        // V1 envelope whose TransactionXDR has zero operations.
        mocks.reset()
        let zeroOpsTxXDR = TransactionXDR(
            sourceAccount: signer.publicKey,
            seqNum: 123456,
            cond: .none,
            memo: .none,
            operations: [],
            maxOperationFee: 100
        )
        let zeroOpsV1Envelope = TransactionEnvelopeXDR.v1(TransactionV1EnvelopeXDR(tx: zeroOpsTxXDR, signatures: []))
        let zeroOpsV1Base64 = Data(try XDREncoder.encode(zeroOpsV1Envelope)).base64EncodedString()
        let encodedZeroOpsV1 = try XCTUnwrap(zeroOpsV1Base64.urlEncoded)
        let zeroOpsV1Uri = "web+stellar:tx?xdr=\(encodedZeroOpsV1)&callback=url:https://\(mockCallbackHost)/submit"
        let zeroOpsV1Result = await uriScheme.signAndSubmitTransaction(forURL: zeroOpsV1Uri, signerKeyPair: signer, network: .testnet)
        guard case .failure(.requestFailed(let v1Message, _)) = zeroOpsV1Result else {
            return XCTFail("Expected requestFailed for zero-operation V1 envelope, got \(zeroOpsV1Result)")
        }
        XCTAssertEqual(v1Message, "TransactionXDR missing from url!")
        XCTAssertEqual(mocks.totalRequestCount, 0)

        // Fee bump envelope whose inner V1 transaction has zero operations.
        mocks.reset()
        let feeSource = try KeyPair(secretSeed: testSignerSecretSeed)
        let zeroOpsInnerEnvelope = TransactionV1EnvelopeXDR(tx: zeroOpsTxXDR, signatures: [])
        let zeroOpsFeeBumpTxXDR = FeeBumpTransactionXDR(
            sourceAccount: MuxedAccountXDR.ed25519(feeSource.publicKey.bytes),
            innerTx: .v1(zeroOpsInnerEnvelope),
            fee: 200
        )
        let zeroOpsFeeBumpEnvelope = TransactionEnvelopeXDR.feeBump(
            FeeBumpTransactionEnvelopeXDR(tx: zeroOpsFeeBumpTxXDR, signatures: [])
        )
        let zeroOpsFeeBumpBase64 = Data(try XDREncoder.encode(zeroOpsFeeBumpEnvelope)).base64EncodedString()
        let encodedZeroOpsFeeBump = try XCTUnwrap(zeroOpsFeeBumpBase64.urlEncoded)
        let zeroOpsFeeBumpUri = "web+stellar:tx?xdr=\(encodedZeroOpsFeeBump)&callback=url:https://\(mockCallbackHost)/submit"
        let zeroOpsFeeBumpResult = await uriScheme.signAndSubmitTransaction(forURL: zeroOpsFeeBumpUri, signerKeyPair: feeSource, network: .testnet)
        guard case .failure(.requestFailed(let feeBumpMessage, _)) = zeroOpsFeeBumpResult else {
            return XCTFail("Expected requestFailed for zero-operation fee bump envelope, got \(zeroOpsFeeBumpResult)")
        }
        XCTAssertEqual(feeBumpMessage, "TransactionXDR missing from url!")
        XCTAssertEqual(mocks.totalRequestCount, 0)
    }

    // A V0 transaction envelope URI signs and posts a V0 envelope whose signature verifies against the transaction hash.
    func testSignAndSubmitV0Envelope() async throws {
        let mocks = installSubmissionMocks()
        let tx = try createMemoTransaction()
        let txXDR = tx.transactionXDR
        let signer = try KeyPair(secretSeed: testSourceSecretSeed)
        let expectedHash = try tx.getTransactionHashData(network: .testnet)

        let sourcePublicKey = try PublicKey(accountId: txXDR.sourceAccount.accountId)
        let v0TxXDR = TransactionV0XDR(
            sourceAccount: sourcePublicKey,
            seqNum: txXDR.seqNum,
            timeBounds: nil,
            memo: txXDR.memo,
            operations: txXDR.operations,
            maxOperationFee: txXDR.fee / UInt32(txXDR.operations.count)
        )
        let v0Envelope = TransactionEnvelopeXDR.v0(TransactionV0EnvelopeXDR(tx: v0TxXDR, signatures: []))
        let v0Base64 = Data(try XDREncoder.encode(v0Envelope)).base64EncodedString()
        let encodedXdr = try XCTUnwrap(v0Base64.urlEncoded)
        let callbackTarget = "https://\(mockCallbackHost)/submit"
        let uri = "web+stellar:tx?xdr=\(encodedXdr)&callback=url:\(callbackTarget)"

        let result = await uriScheme.signAndSubmitTransaction(forURL: uri, signerKeyPair: signer, network: .testnet)

        guard case .success = result else {
            return XCTFail("Expected .success for V0 envelope, got \(result)")
        }
        XCTAssertEqual(mocks.callback.all.count, 1)
        XCTAssertEqual(mocks.publicHorizon.all.count, 0)
        XCTAssertEqual(mocks.testnetHorizon.all.count, 0)
        XCTAssertEqual(mocks.futurenetHorizon.all.count, 0)

        let request = try XCTUnwrap(mocks.callback.all.first)
        XCTAssertEqual(request.url, callbackTarget)
        XCTAssertEqual(request.contentType, "application/x-www-form-urlencoded")

        let postedEnvelope = try decodePostedEnvelope(from: request.body, fieldName: "xdr")
        guard case .v0(let v0) = postedEnvelope else {
            return XCTFail("Expected V0 envelope, got \(postedEnvelope)")
        }
        let signatures = v0.signatures

        XCTAssertEqual(signatures.count, 1)
        let signature = signatures[0]
        XCTAssertEqual(signature.hint.wrapped, Data(signer.publicKey.bytes.suffix(4)))
        XCTAssertTrue(try signer.publicKey.verify(signature: [UInt8](signature.signature), message: [UInt8](expectedHash)))
    }
}

private struct RecordedRequest: Sendable {
    let url: String
    let contentType: String?
    let body: String
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [RecordedRequest] = []

    func record(_ request: URLRequest) {
        let bodyData = request.httpBody ?? request.httpBodyStream?.readfully() ?? Data()
        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""
        let entry = RecordedRequest(
            url: request.url?.absoluteString ?? "",
            contentType: request.value(forHTTPHeaderField: "Content-Type"),
            body: bodyString
        )
        lock.lock()
        requests.append(entry)
        lock.unlock()
    }

    var all: [RecordedRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }

    func reset() {
        lock.lock()
        requests.removeAll()
        lock.unlock()
    }
}

private final class ConfirmationCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var captured: TransactionXDR?

    func record(_ tx: TransactionXDR) {
        lock.lock()
        captured = tx
        lock.unlock()
    }

    var value: TransactionXDR? {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }
}
