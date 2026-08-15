//
//  ClaimableBalanceRoutingUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Christian Rogobete.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The routes and the claimable balance id spelling the services put on the wire.
final class ClaimableBalanceRoutingUnitTests: XCTestCase {

    /// Records the path of every request the mock server is asked to serve.
    private final class PathRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var paths = [String]()

        func record(_ path: String) {
            lock.lock()
            defer { lock.unlock() }
            paths.append(path)
        }

        var recorded: [String] {
            lock.lock()
            defer { lock.unlock() }
            return paths
        }
    }

    /// Holds the error a stream hands its receiver, which arrives outside the test's isolation.
    private final class ErrorBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Error?

        func store(_ error: Error?) {
            lock.lock()
            defer { lock.unlock() }
            stored = error
        }

        var error: Error? {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
    }

    private let hashHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
    private let strKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
    private let invalidId = "not a claimable balance id"

    private var horizonHex: String { "00000000" + hashHex }

    /// Every spelling of the same id, the strkey among them.
    private var spellings: [String] { [strKey, hashHex, "00" + hashHex, horizonHex, hashHex.uppercased()] }

    private var sdk: StellarSDK!

    override func setUp() {
        super.setUp()
        sdk = StellarSDK()
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    /// Serves `body` for any request and hands back the recorder holding the paths asked for.
    ///
    /// The mock matches every path, so a request for a route the SDK should never build is
    /// recorded here rather than escaping to the network.
    private func recordRequests(serving body: String) -> PathRecorder {
        let recorder = PathRecorder()
        ServerMock.add(mock: RequestMock(host: "horizon-testnet.stellar.org",
                                        path: "*",
                                        httpMethod: "GET",
                                        mockHandler: { _, request in
            recorder.record(request.url?.path ?? "")
            return body
        }))
        return recorder
    }

    private var claimableBalanceJson: String {
        """
        {
          "_links": {
            "self": {"href": "https://horizon-testnet.stellar.org/claimable_balances/\(horizonHex)"}
          },
          "id": "\(horizonHex)",
          "paging_token": "12884905984-\(horizonHex)",
          "asset": "native",
          "amount": "12.3000000",
          "sponsor": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
          "last_modified_ledger": 7877447,
          "last_modified_time": "2021-11-18T03:47:47Z",
          "claimants": [
            {
              "destination": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
              "predicate": {"unconditional": true}
            }
          ]
        }
        """
    }

    private var emptyPageJson: String {
        """
        {
          "_links": {
            "self": {"href": "https://horizon-testnet.stellar.org/claimable_balances"}
          },
          "_embedded": {"records": []}
        }
        """
    }

    // MARK: - The id every claimable balance route carries

    func testGetClaimableBalanceAsksForTheHorizonHexOfEverySpelling() async {
        for spelling in spellings {
            let recorder = recordRequests(serving: claimableBalanceJson)
            let response = await sdk.claimableBalances.getClaimableBalance(balanceId: spelling)
            guard case .success(let details) = response else {
                XCTFail("expected success for spelling \(spelling), got \(response)")
                ServerMock.removeAll()
                continue
            }
            XCTAssertEqual(details.balanceId, horizonHex)
            XCTAssertEqual(recorder.recorded, ["/claimable_balances/\(horizonHex)"], "spelling: \(spelling)")
            ServerMock.removeAll()
        }
    }

    func testGetOperationsForClaimableBalanceAsksForTheHorizonHexOfEverySpelling() async {
        for spelling in spellings {
            let recorder = recordRequests(serving: emptyPageJson)
            let response = await sdk.operations.getOperations(forClaimableBalance: spelling)
            guard case .success = response else {
                XCTFail("expected success for spelling \(spelling), got \(response)")
                ServerMock.removeAll()
                continue
            }
            XCTAssertEqual(recorder.recorded, ["/claimable_balances/\(horizonHex)/operations"], "spelling: \(spelling)")
            ServerMock.removeAll()
        }
    }

    func testGetTransactionsForClaimableBalanceAsksForTheHorizonHexOfEverySpelling() async {
        for spelling in spellings {
            let recorder = recordRequests(serving: emptyPageJson)
            let response = await sdk.transactions.getTransactions(forClaimableBalance: spelling)
            guard case .success = response else {
                XCTFail("expected success for spelling \(spelling), got \(response)")
                ServerMock.removeAll()
                continue
            }
            XCTAssertEqual(recorder.recorded, ["/claimable_balances/\(horizonHex)/transactions"], "spelling: \(spelling)")
            ServerMock.removeAll()
        }
    }

    func testTransactionsStreamUsesTheClaimableBalancesRoute() {
        for spelling in spellings {
            let streamItem = sdk.transactions.stream(for: .transactionsForClaimableBalance(claimableBalanceId: spelling, cursor: nil))
            XCTAssertEqual(streamItem.requestUrl,
                           "\(StellarSDK.testNetUrl)/claimable_balances/\(horizonHex)/transactions",
                           "spelling: \(spelling)")
        }
    }

    func testOperationsStreamUsesTheClaimableBalancesRoute() {
        for spelling in spellings {
            let streamItem = sdk.operations.stream(for: .operationsForClaimableBalance(claimableBalanceId: spelling, cursor: nil))
            XCTAssertEqual(streamItem.requestUrl,
                           "\(StellarSDK.testNetUrl)/claimable_balances/\(horizonHex)/operations",
                           "spelling: \(spelling)")
        }
    }

    func testStreamsCarryTheCursor() {
        let transactions = sdk.transactions.stream(for: .transactionsForClaimableBalance(claimableBalanceId: strKey, cursor: "now"))
        XCTAssertEqual(transactions.requestUrl,
                       "\(StellarSDK.testNetUrl)/claimable_balances/\(horizonHex)/transactions?cursor=now")

        let operations = sdk.operations.stream(for: .operationsForClaimableBalance(claimableBalanceId: strKey, cursor: "now"))
        XCTAssertEqual(operations.requestUrl,
                       "\(StellarSDK.testNetUrl)/claimable_balances/\(horizonHex)/operations?cursor=now")
    }

    // MARK: - An id naming no claimable balance

    private func assertBadRequest(_ error: HorizonRequestError, line: UInt = #line) {
        guard case .badRequest(let message, let horizonErrorResponse) = error else {
            XCTFail("expected a badRequest error, got \(error)", line: line)
            return
        }
        XCTAssertNil(horizonErrorResponse, line: line)
        XCTAssertEqual(message,
                       "claimable balance id must be a 58 character strkey (B...), or hex of the bare id (64 characters), which a discriminant may prefix to 66 or 72 characters; 26 characters given",
                       line: line)
    }

    func testGetClaimableBalanceRejectsAnIdNamingNoBalance() async {
        let recorder = recordRequests(serving: claimableBalanceJson)
        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: invalidId)
        guard case .failure(let error) = response else {
            return XCTFail("expected a failure, got \(response)")
        }
        assertBadRequest(error)
        XCTAssertEqual(recorder.recorded, [], "no request may be sent for an id naming no balance")
    }

    func testGetOperationsForClaimableBalanceRejectsAnIdNamingNoBalance() async {
        let recorder = recordRequests(serving: emptyPageJson)
        let response = await sdk.operations.getOperations(forClaimableBalance: invalidId)
        guard case .failure(let error) = response else {
            return XCTFail("expected a failure, got \(response)")
        }
        assertBadRequest(error)
        XCTAssertEqual(recorder.recorded, [], "no request may be sent for an id naming no balance")
    }

    func testGetTransactionsForClaimableBalanceRejectsAnIdNamingNoBalance() async {
        let recorder = recordRequests(serving: emptyPageJson)
        let response = await sdk.transactions.getTransactions(forClaimableBalance: invalidId)
        guard case .failure(let error) = response else {
            return XCTFail("expected a failure, got \(response)")
        }
        assertBadRequest(error)
        XCTAssertEqual(recorder.recorded, [], "no request may be sent for an id naming no balance")
    }

    func testTransactionsStreamReportsAnIdNamingNoBalance() {
        let received = XCTestExpectation(description: "the stream reports the id")
        let box = ErrorBox()
        let streamItem = sdk.transactions.stream(for: .transactionsForClaimableBalance(claimableBalanceId: invalidId, cursor: nil))
        streamItem.onReceive { response in
            guard case .error(let error) = response else { return }
            box.store(error)
            received.fulfill()
        }
        XCTAssertNil(box.error, "the error arrives the way the stream callbacks do, not inside onReceive")
        wait(for: [received], timeout: 1)
        streamItem.closeStream()

        guard let horizonError = box.error as? HorizonRequestError else {
            return XCTFail("expected a Horizon error, got \(String(describing: box.error))")
        }
        assertBadRequest(horizonError)
    }

    func testOperationsStreamReportsAnIdNamingNoBalance() {
        let received = XCTestExpectation(description: "the stream reports the id")
        let box = ErrorBox()
        let streamItem = sdk.operations.stream(for: .operationsForClaimableBalance(claimableBalanceId: invalidId, cursor: nil))
        streamItem.onReceive { response in
            guard case .error(let error) = response else { return }
            box.store(error)
            received.fulfill()
        }
        XCTAssertNil(box.error, "the error arrives the way the stream callbacks do, not inside onReceive")
        wait(for: [received], timeout: 1)
        streamItem.closeStream()

        guard let horizonError = box.error as? HorizonRequestError else {
            return XCTFail("expected a Horizon error, got \(String(describing: box.error))")
        }
        assertBadRequest(horizonError)
    }

    // MARK: - The resolver the routes share

    func testResolverAcceptsEverySpelling() throws {
        for spelling in spellings {
            XCTAssertEqual(try ServiceHelper.claimableBalanceIdHorizonHex(spelling), horizonHex, "spelling: \(spelling)")
        }
    }

    func testResolverReportsTheReasonAnIdIsRejected() {
        XCTAssertThrowsError(try ServiceHelper.claimableBalanceIdHorizonHex(invalidId)) { error in
            guard let horizonError = error as? HorizonRequestError else {
                return XCTFail("expected a Horizon error, got \(error)")
            }
            assertBadRequest(horizonError)
        }

        let brokenStrKey = String(strKey.dropLast() + "T")
        XCTAssertThrowsError(try ServiceHelper.claimableBalanceIdHorizonHex(brokenStrKey)) { error in
            guard case HorizonRequestError.badRequest(let message, _) = error else {
                return XCTFail("expected a badRequest error, got \(error)")
            }
            XCTAssertEqual(message, "claimable balance id \"\(brokenStrKey)\" is not a well formed strkey")
        }
    }
}
