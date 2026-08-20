//
//  Sep24FeeAmountQueryTestCase.swift
//  stellarsdkTests
//
//  Copyright © Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Verifies that the amount of a SEP-24 fee request reaches the anchor as a plain
/// decimal, never in scientific notation.
class Sep24FeeAmountQueryTestCase: XCTestCase {

    let interactiveServer = "127.0.0.1"

    var interactiveService: InteractiveService!

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)
        ServerMock.removeAll()
        interactiveService = InteractiveService(serviceAddress: "http://\(interactiveServer)")
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    func testSmallAmountIsSentAsPlainDecimal() async {
        // 123 stroops, an ordinary amount, which String(Double) spells "1.23e-05".
        let request = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 0.0000123)
        let query = await feeQuery(for: request)

        XCTAssertEqual("0.0000123", amountValue(in: query))
        assertNoExponent(in: query)
        XCTAssertEqual(true, query?.contains("amount=0.0000123"), query ?? "no query captured")
    }

    func testOneStroopIsSentAsPlainDecimal() async {
        let request = Sep24FeeRequest(operation: "withdraw", assetCode: "USD", amount: 0.0000001)
        let query = await feeQuery(for: request)

        XCTAssertEqual("0.0000001", amountValue(in: query))
        assertNoExponent(in: query)
    }

    func testLargeAmountIsSentAsPlainDecimal() async {
        // String(Double) spells this "1e+21".
        let request = Sep24FeeRequest(operation: "deposit", type: "SEPA", assetCode: "USD", amount: 1e21)
        let query = await feeQuery(for: request)

        XCTAssertEqual("1000000000000000000000", amountValue(in: query))
        assertNoExponent(in: query)
    }

    func testWholeAmountIsSentWithoutADecimalPoint() async {
        let request = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 10.0)
        let query = await feeQuery(for: request)

        XCTAssertEqual("10", amountValue(in: query))
    }

    // MARK: - Helpers

    /// Runs a fee request against a mock that captures the outgoing query string.
    private func feeQuery(for request: Sep24FeeRequest) async -> String? {
        var capturedQuery: String?
        let mock = RequestMock(host: interactiveServer,
                               path: "/fee",
                               httpMethod: "GET",
                               mockHandler: { mock, urlRequest in
                                   capturedQuery = urlRequest.url?.query
                                   mock.statusCode = 200
                                   return "{ \"fee\": 0.013 }"
                               })
        ServerMock.add(mock: mock)
        defer { ServerMock.remove(mock: mock) }

        let responseEnum = await interactiveService.fee(request: request)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
        XCTAssertNotNil(capturedQuery, "the fee request did not reach the mock")
        return capturedQuery
    }

    private func amountValue(in query: String?) -> String? {
        guard let query = query,
              let components = URLComponents(string: "http://\(interactiveServer)/fee?\(query)") else {
            return nil
        }
        return components.queryItems?.first(where: { $0.name == "amount" })?.value
    }

    private func assertNoExponent(in query: String?, file: StaticString = #filePath, line: UInt = #line) {
        guard let amount = amountValue(in: query) else {
            XCTFail("no amount in query \(query ?? "nil")", file: file, line: line)
            return
        }
        XCTAssertFalse(amount.contains("e"), "exponent in amount \(amount)", file: file, line: line)
        XCTAssertFalse(amount.contains("E"), "exponent in amount \(amount)", file: file, line: line)
    }
}
