//
//  CraftedEnvelopeUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Envelopes with asset codes that `Asset.fromXDR(assetXDR:)` rejects or with a sequence number
/// of `Int64.min` produce errors on every path that decodes an untrusted envelope.
final class CraftedEnvelopeUnitTests: XCTestCase {

    private let sourceSeed = "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK"
    private let otherAccountId = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    func testAlphanum4CodeOfNulBytes() async throws {
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0, 0, 0, 0])), issuer: try issuer()))
        try await assertRejected(try transaction(.paymentOp(payment(asset))), expecting: isAssetDecodingError)
    }

    func testAlphanum4CodeOfFFBytes() async throws {
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0xFF, 0xFF, 0xFF, 0xFF])), issuer: try issuer()))
        try await assertRejected(try transaction(.paymentOp(payment(asset))), expecting: isAssetDecodingError)
    }

    func testAlphanum12CodeOfThreeCharacters() async throws {
        let code = Data("ABC".utf8) + Data(repeating: 0, count: 9)
        let asset = AssetXDR.alphanum12(Alpha12XDR(assetCode: WrappedData12(code), issuer: try issuer()))
        try await assertRejected(try transaction(.paymentOp(payment(asset))), expecting: isAssetDecodingError)
    }

    func testPathPaymentWithInvalidPathAsset() async throws {
        let pathAsset = AssetXDR.alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0, 0, 0, 0])), issuer: try issuer()))
        let op = PathPaymentOperationXDR(sendAsset: .native, sendMax: 100, destination: .ed25519(try issuer().bytes),
                                         destinationAsset: .native, destinationAmount: 100, path: [.native, pathAsset])
        try await assertRejected(try transaction(.pathPaymentStrictReceiveOp(op)), expecting: isAssetDecodingError)
    }

    func testSequenceNumberInt64Min() async throws {
        let tx = try transaction(.paymentOp(payment(.native)), seqNum: Int64.min)
        try await assertRejected(tx) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else { return false }
            return message == "Invalid transaction sequence number -9223372036854775808: no account sequence number precedes it"
        }
    }

    func testFeeBumpEnvelopeWithInvalidInnerAsset() throws {
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0xFF, 0xFF, 0xFF, 0xFF])), issuer: try issuer()))
        let inner = try transaction(.paymentOp(payment(asset)))
        let feeBump = FeeBumpTransactionXDR(sourceAccount: .ed25519(try issuer().bytes),
                                            innerTx: .v1(try inner.toEnvelopeV1XDR()), fee: 200)
        XCTAssertThrowsError(try Transaction(envelopeXdr: try feeBump.encodedEnvelope())) { error in
            XCTAssertTrue(isAssetDecodingError(error), "\(error)")
        }
    }

    func testEveryAssetCarryingOperationRejectsInvalidAssetCode() throws {
        let bad = AssetXDR.alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0, 0, 0, 0])), issuer: try issuer()))
        let account = try issuer()
        let path = PathPaymentOperationXDR(sendAsset: .native, sendMax: 1, destination: .ed25519(account.bytes),
                                           destinationAsset: bad, destinationAmount: 1, path: [])
        let offer = ManageOfferOperationXDR(selling: .native, buying: bad, amount: 1, price: PriceXDR(n: 1, d: 1), offerID: 0)
        let bodies: [OperationBodyXDR] = [
            .paymentOp(try payment(bad)), .pathPaymentStrictReceiveOp(path), .pathPaymentStrictSendOp(path),
            .manageSellOfferOp(offer), .manageBuyOfferOp(offer),
            .createPassiveSellOfferOp(CreatePassiveOfferOperationXDR(selling: bad, buying: .native, amount: 1, price: PriceXDR(n: 1, d: 1))),
            .clawbackOp(ClawbackOpXDR(asset: bad, from: .ed25519(account.bytes), amount: 1)),
            .setTrustLineFlagsOp(SetTrustLineFlagsOpXDR(accountID: account, asset: bad, setFlags: 1, clearFlags: 0)),
        ]
        for body in bodies {
            XCTAssertThrowsError(try Transaction(envelopeXdr: try transaction(body).encodedEnvelope()), "\(body)") { error in
                XCTAssertTrue(isAssetDecodingError(error), "\(error)")
            }
        }
    }

    func testValidImportStillDecodesAssets() throws {
        let usd = AssetXDR.alphanum4(Alpha4XDR(assetCode: WrappedData4(Data("USD".utf8) + Data([0])), issuer: try issuer()))
        let imported = try Transaction(envelopeXdr: try transaction(.paymentOp(payment(usd)), seqNum: 42).encodedEnvelope())
        let payment = try XCTUnwrap(imported.operations.first as? PaymentOperation)
        XCTAssertEqual(payment.asset.code, "USD")
        XCTAssertEqual(payment.asset.issuer?.accountId, otherAccountId)
        XCTAssertEqual(imported.sourceAccount.sequenceNumber, 42)
    }

    // MARK: - Helpers

    private func issuer() throws -> PublicKey {
        try KeyPair(accountId: otherAccountId).publicKey
    }

    private func payment(_ asset: AssetXDR) throws -> PaymentOperationXDR {
        PaymentOperationXDR(destination: .ed25519(try issuer().bytes), asset: asset, amount: 100)
    }

    private func transaction(_ body: OperationBodyXDR, seqNum: Int64 = 1) throws -> TransactionXDR {
        TransactionXDR(sourceAccount: try KeyPair(secretSeed: sourceSeed).publicKey, seqNum: seqNum,
                       cond: .none, memo: .none, operations: [OperationXDR(body: body)])
    }

    private func isAssetDecodingError(_ error: Error) -> Bool {
        guard case StellarSDKError.xdrDecodingError(let message) = error else { return false }
        return message == "Error decoding asset: invalid data in xdr"
    }

    /// Asserts that both `Transaction` initializers throw the expected error, that SEP-7 signing
    /// fails before any submission, and that `postTransaction` returns Horizon's error result.
    private func assertRejected(_ tx: TransactionXDR, expecting matches: (Error) -> Bool,
                                file: StaticString = #filePath, line: UInt = #line) async throws {
        let xdr = try XCTUnwrap(tx.xdrEncoded, file: file, line: line)
        let envelope = try tx.encodedEnvelope()
        XCTAssertThrowsError(try Transaction(xdr: xdr), file: file, line: line) { error in
            XCTAssertTrue(matches(error), "\(error)", file: file, line: line)
        }
        XCTAssertThrowsError(try Transaction(envelopeXdr: envelope), file: file, line: line) { error in
            XCTAssertTrue(matches(error), "\(error)", file: file, line: line)
        }

        let uri = URIScheme().getSignTransactionURI(transactionXDR: tx)
        let signed = await URIScheme().signAndSubmitTransaction(forURL: uri, signerKeyPair: try KeyPair(secretSeed: sourceSeed))
        guard case .failure(.requestFailed(let message, _)) = signed else {
            return XCTFail("SEP-7 signing did not fail: \(signed)", file: file, line: line)
        }
        XCTAssertEqual(message, "TransactionXDR missing from url!", file: file, line: line)

        // Only the mock answers with status 400, so a bad request result shows the envelope was posted.
        let horizon = RequestMock(host: "horizon-testnet.stellar.org", path: "/transactions", httpMethod: "POST",
                                  statusCode: 400) { _, _ in
            #"{"type":"https://stellar.org/horizon-errors/transaction_malformed","title":"Transaction Malformed","status":400}"#
        }
        ServerMock.add(mock: horizon)
        let posted = await StellarSDK().transactions.postTransaction(transactionEnvelope: envelope)
        ServerMock.remove(mock: horizon)
        guard case .failure(.badRequest) = posted else {
            return XCTFail("postTransaction did not return Horizon's error: \(posted)", file: file, line: line)
        }
    }
}
