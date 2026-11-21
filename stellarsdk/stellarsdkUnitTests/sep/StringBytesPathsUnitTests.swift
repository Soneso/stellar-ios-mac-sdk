//
//  StringBytesPathsUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// SEP-7, SEP-10 and Horizon paths that decode a transaction whose text memo holds bytes that
/// are not valid UTF-8.
final class StringBytesPathsUnitTests: XCTestCase {

    /// A V1 testnet envelope with the text memo ff fe 20 61 62 63 and its hash.
    private let memoEnvelope = "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    private let memoHash = "afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9"

    private let invalid = Data([0xff, 0xfe, 0x20, 0x61, 0x62, 0x63])
    private let authHost = "string-bytes.auth.example.com"

    private var challengeMock: StringBytesChallengeMock?

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        challengeMock = nil
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - SEP-7

    func testSep7HandsTheTransactionOverWithItsBytes() async throws {
        let encoded = try XCTUnwrap(memoEnvelope.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
        let url = URISchemeName + SignOperation + "xdr=" + encoded
        let received = ReceivedTransaction()
        let result = await URIScheme().signAndSubmitTransaction(forURL: url, signerKeyPair: try KeyPair.generateRandomKeyPair(),
                                                                network: .testnet) { transactionXDR in
            received.set(transactionXDR)
            return false
        }
        guard case .failure(let error) = result, case .requestFailed(let message, _) = error else {
            return XCTFail("expected the unconfirmed transaction to fail, got \(result)")
        }
        XCTAssertEqual(message, "Transaction was not confirmed!")
        let transactionXDR = try XCTUnwrap(received.get())
        XCTAssertEqual(try transactionXDR.encodedEnvelope(), memoEnvelope)
        XCTAssertEqual(try transactionXDR.hash(network: .testnet).base16EncodedString(), memoHash)
    }

    // MARK: - SEP-10

    func testSep10ChallengeWithAnInvalidTextMemoFailsTheMemoTypeCheck() async throws {
        let server = try KeyPair.generateRandomKeyPair()
        let client = try KeyPair.generateRandomKeyPair()
        let now = UInt64(Date().timeIntervalSince1970)
        let operation = ManageDataOperation(sourceAccountId: client.accountId, name: "\(authHost) auth",
                                            data: Data(repeating: 0x61, count: 64))
        let challenge = try Transaction(sourceAccount: Account(keyPair: server, sequenceNumber: -1), operations: [operation],
                                        memoXDR: .text(invalid),
                                        preconditions: TransactionPreconditions(timeBounds: TimeBounds(minTime: now, maxTime: now + 300)))
        try challenge.sign(keyPair: server, network: .testnet)
        challengeMock = StringBytesChallengeMock(host: authHost, challenge: try challenge.encodedEnvelope())

        let webAuthenticator = WebAuthenticator(authEndpoint: "https://\(authHost)/auth", network: .testnet,
                                                serverSigningKey: server.accountId, serverHomeDomain: authHost)
        let response = await webAuthenticator.jwtToken(forUserAccount: client.accountId, signers: [client])
        guard case .failure(let error) = response, case .validationErrorError(let validationError) = error else {
            return XCTFail("expected a challenge validation error, got \(response)")
        }
        XCTAssertEqual(validationError, .invalidMemoType)
    }

    // MARK: - Horizon

    func testHorizonTextMemoComesFromMemoBytes() throws {
        let live = try decodeHorizon(TransactionResponse.self, liveRecord(memo: liveMemo, memoBytes: "//4gYWJj"))
        XCTAssertEqual(live.memoBytes, invalid)
        XCTAssertEqual(live.memo, Memo.text("\u{FFFD}\u{FFFD} abc"))
        XCTAssertEqual(live.transactionEnvelope.xdrEncoded, liveEnvelope)
        XCTAssertEqual(try live.transactionEnvelope.txHash(network: .testnet).base16EncodedString(), live.transactionHash)

        let allInvalid = try decodeHorizon(TransactionResponse.self,
                                           liveRecord(memo: String(repeating: #"\ufffd"#, count: 28),
                                                      memoBytes: "/////////////////////////////////////w=="))
        XCTAssertEqual(allInvalid.memoBytes, Data(repeating: 0xff, count: 28))
        XCTAssertEqual(allInvalid.memo, Memo.text(String(repeating: "\u{FFFD}", count: 28)))

        let cut = try decodeHorizon(TransactionResponse.self,
                                    liveRecord(memo: String(repeating: "a", count: 27) + #"\ufffd"#,
                                               memoBytes: "YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhww=="))
        XCTAssertEqual(cut.memoBytes, Data(repeating: 0x61, count: 27) + Data([0xc3]))
        XCTAssertEqual(cut.memo, Memo.text(String(repeating: "a", count: 27) + "\u{FFFD}"))
    }

    func testHorizonMemoBytesThatAreNotBase64FailTheRecord() throws {
        XCTAssertThrowsError(try decodeHorizon(TransactionResponse.self, liveRecord(memo: liveMemo, memoBytes: "//4gYWJj!"))) { error in
            guard let horizonError = error as? HorizonRequestError,
                  case .parsingResponseFailed(let message) = horizonError else {
                return XCTFail("expected parsingResponseFailed, got \(error)")
            }
            XCTAssertEqual(message, "Invalid base64 in memo_bytes")
        }
    }

    func testHorizonAccountTransactionsPageDecodes() throws {
        let page = try decodeHorizon(PageResponse<TransactionResponse>.self, livePage)
        XCTAssertEqual(page.records.map { $0.transactionHash },
                       ["b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777",
                        "b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816"])
        XCTAssertEqual(page.records.first?.memo, Memo.none)
        XCTAssertNil(page.records.first?.memoBytes)
        XCTAssertEqual(page.records.last?.memoBytes, invalid)
    }

    // MARK: - Helpers

    private func decodeHorizon<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        return try decoder.decode(type, from: Data(json.utf8))
    }

    /// The `memo` field Horizon writes for ff fe 20 61 62 63, as JSON text.
    private let liveMemo = #"\ufffd\ufffd abc"#

    /// The envelope of testnet transaction b7fb286b, whose text memo holds ff fe 20 61 62 63.
    private let liveEnvelope = "AAAAAgAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAA+gAWPV9AAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAb//iBhYmMAAAAAAAEAAAAAAAAAAQAAAACkQeBd9iE/juL6rqj0VVFw2v8aYlIFPrDcDVEpm7RX1AAAAAAAAAAAAJiWgAAAAAAAAAABPX5PMAAAAEAqERgvj65qzoHGjnHgWnfheLjxKwOqWTLzvu/v3OwwOi2Qkejhk2V7ODCcq9/yVZ0M6rvDcOIIUrlecenAIGYP"

    /// Testnet transaction b7fb286b as Horizon returned it, with the given `memo` and `memo_bytes`.
    private func liveRecord(memo: String, memoBytes: String) -> String {
        return #"""
        {"memo":"\#(memo)","memo_bytes":"\#(memoBytes)","_links":{"self":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816"},"account":{"href":"https://horizon-testnet.stellar.org/accounts/GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB"},"ledger":{"href":"https://horizon-testnet.stellar.org/ledgers/5830015"},"operations":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816/operations{?cursor,limit,order}","templated":true},"effects":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816/effects{?cursor,limit,order}","templated":true},"precedes":{"href":"https://horizon-testnet.stellar.org/transactions?order=asc&cursor=25039723760209920"},"succeeds":{"href":"https://horizon-testnet.stellar.org/transactions?order=desc&cursor=25039723760209920"},"transaction":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816"}},"id":"b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816","paging_token":"25039723760209920","successful":true,"hash":"b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816","ledger":5830015,"created_at":"2026-11-20T11:21:55Z","source_account":"GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB","source_account_sequence":"25039715170254849","fee_account":"GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB","fee_charged":"100","max_fee":"1000","operation_count":1,"envelope_xdr":"AAAAAgAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAA+gAWPV9AAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAb//iBhYmMAAAAAAAEAAAAAAAAAAQAAAACkQeBd9iE/juL6rqj0VVFw2v8aYlIFPrDcDVEpm7RX1AAAAAAAAAAAAJiWgAAAAAAAAAABPX5PMAAAAEAqERgvj65qzoHGjnHgWnfheLjxKwOqWTLzvu/v3OwwOi2Qkejhk2V7ODCcq9/yVZ0M6rvDcOIIUrlecenAIGYP","result_xdr":"AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=","fee_meta_xdr":"AAAAAgAAAAMAWPV9AAAAAAAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAABdIdugAAFj1fQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAWPV/AAAAAAAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAABdIduecAFj1fQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==","memo_type":"text","signatures":["KhEYL4+uas6Bxo5x4Fp34Xi48SsDqlky877v79zsMDotkJHo4ZNlezgwnKvf8lWdDOq7w3DiCFK5XnHpwCBmDw=="],"preconditions":{"timebounds":{"min_time":"0"}}}
        """#
    }

    /// The transactions page of testnet account GCSEDYC5...JVWQ as Horizon returned it.
    private var livePage: String {
        return #"""
        {"_links":{"self":{"href":"https://horizon-testnet.stellar.org/accounts/GCSEDYC56YQT7DXC7KXKR5CVKFYNV7Y2MJJAKPVQ3QGVCKM3WRL5JVWQ/transactions?cursor=&limit=10&order=asc"},"next":{"href":"https://horizon-testnet.stellar.org/accounts/GCSEDYC56YQT7DXC7KXKR5CVKFYNV7Y2MJJAKPVQ3QGVCKM3WRL5JVWQ/transactions?cursor=25039723760209920&limit=10&order=asc"},"prev":{"href":"https://horizon-testnet.stellar.org/accounts/GCSEDYC56YQT7DXC7KXKR5CVKFYNV7Y2MJJAKPVQ3QGVCKM3WRL5JVWQ/transactions?cursor=25039719465238528&limit=10&order=desc"}},"_embedded":{"records":[{"_links":{"self":{"href":"https://horizon-testnet.stellar.org/transactions/b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777"},"account":{"href":"https://horizon-testnet.stellar.org/accounts/GC4R3JXARIZ3SZK6XDHRXEDBOWLXL3QGKI5QCPFR45Z7F7LPG6AJEW2J"},"ledger":{"href":"https://horizon-testnet.stellar.org/ledgers/5830014"},"operations":{"href":"https://horizon-testnet.stellar.org/transactions/b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777/operations{?cursor,limit,order}","templated":true},"effects":{"href":"https://horizon-testnet.stellar.org/transactions/b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777/effects{?cursor,limit,order}","templated":true},"precedes":{"href":"https://horizon-testnet.stellar.org/transactions?order=asc&cursor=25039719465238528"},"succeeds":{"href":"https://horizon-testnet.stellar.org/transactions?order=desc&cursor=25039719465238528"},"transaction":{"href":"https://horizon-testnet.stellar.org/transactions/b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777"}},"id":"b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777","paging_token":"25039719465238528","successful":true,"hash":"b3be73ac7464a7db40877c694a171b4b035437b4a954c435b798178948c7d777","ledger":5830014,"created_at":"2026-11-20T11:21:50Z","source_account":"GC4R3JXARIZ3SZK6XDHRXEDBOWLXL3QGKI5QCPFR45Z7F7LPG6AJEW2J","source_account_sequence":"25000321730215943","fee_account":"GC4R3JXARIZ3SZK6XDHRXEDBOWLXL3QGKI5QCPFR45Z7F7LPG6AJEW2J","fee_charged":"100","max_fee":"1000000","operation_count":1,"envelope_xdr":"AAAAAgAAAAC5HabgijO5ZV64zxuQYXWXde4GUjsBPLHnc/L9bzeAkgAPQkAAWNGpAAAABwAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAABB90WssODNIgi6BHveqzxTRmIpvAFRyVNM+Hm2GVuCcAAAAAAAAAACkQeBd9iE/juL6rqj0VVFw2v8aYlIFPrDcDVEpm7RX1AAAABdIdugAAAAAAAAAAAJvN4CSAAAAQMUWNbC+v5btJyYSJjQ2S2MKREAfk6OLiBkCVkSCytKay1O4UH4SXuFG+WobzSy22hSyZCavCMDUUG9oyKw4Dg2GVuCcAAAAQJVyCQmX7r0cdSvzmraBpHYiODke3RAMCBunjS0sLNuBpAeHw50z2CAsCZrrdAaP96FFqwHb8UDUDRZ1V2mMpA8=","result_xdr":"AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=","fee_meta_xdr":"AAAAAgAAAAMAWPJNAAAAAAAAAAC5HabgijO5ZV64zxuQYXWXde4GUjsBPLHnc/L9bzeAkgAAAAA8M14oAFjRqQAAAAYAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADAAAAAABY8k0AAAAAawAdWQAAAAAAAAABAFj1fgAAAAAAAAAAuR2m4IozuWVeuM8bkGF1l3XuBlI7ATyx53Py/W83gJIAAAAAPDNdxABY0akAAAAGAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAwAAAAAAWPJNAAAAAGsAHVkAAAAA","memo_type":"none","signatures":["xRY1sL6/lu0nJhImNDZLYwpEQB+To4uIGQJWRILK0prLU7hQfhJe4Ub5ahvNLLbaFLJkJq8IwNRQb2jIrDgODQ==","lXIJCZfuvRx1K/OatoGkdiI4OR7dEAwIG6eNLSws24GkB4fDnTPYICwJmut0Bo/3oUWrAdvxQNQNFnVXaYykDw=="],"preconditions":{"timebounds":{"min_time":"0"}}},\#(liveRecord(memo: liveMemo, memoBytes: "//4gYWJj"))]}}
        """#
    }
}

/// The transaction a SEP-7 confirmation closure receives.
private final class ReceivedTransaction: @unchecked Sendable {
    private let lock = NSLock()
    private var transactionXDR: TransactionXDR?

    func set(_ value: TransactionXDR) {
        lock.lock()
        defer { lock.unlock() }
        transactionXDR = value
    }

    func get() -> TransactionXDR? {
        lock.lock()
        defer { lock.unlock() }
        return transactionXDR
    }
}

/// Serves one SEP-10 challenge at `/auth` of the given host.
private final class StringBytesChallengeMock: ResponsesMock {
    private let host: String
    private let challenge: String

    init(host: String, challenge: String) {
        self.host = host
        self.challenge = challenge
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, _ in
            mock.statusCode = 200
            return self.map { #"{"transaction": "\#($0.challenge)"}"# }
        }
        return RequestMock(host: host, path: "/auth", httpMethod: "GET", mockHandler: handler)
    }
}
