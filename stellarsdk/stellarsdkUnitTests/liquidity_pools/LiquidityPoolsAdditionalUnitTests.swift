//
//  LiquidityPoolsAdditionalUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 04.02.26.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LiquidityPoolsAdditionalUnitTests: XCTestCase {
    let sdk = StellarSDK()
    var mockRegistered = false

    override func setUp() {
        super.setUp()

        ServerMock.removeAll()
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - Error Handling Tests

    func testGetLiquidityPoolNotFound() async {
        _ = LiquidityPoolNotFoundMock()
        let invalidPoolId = "0000000000000000000000000000000000000000000000000000000000000000"

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: invalidPoolId)
        switch response {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .notFound(let message, _):
                XCTAssertTrue(message.contains("Resource Missing") || message.contains("not found"), "Expected 'Resource Missing' or 'not found' in error message")
            default:
                XCTFail("Expected notFound error but got: \(error)")
            }
        }
    }

    func testGetLiquidityPoolMalformedJSON() async {
        let responsesMock = LiquidityPoolsResponsesMock()
        let poolId = "malformed-json-test"
        let malformedJson = """
        {
          "id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "fee_bp": "invalid_number",
          "type": "constant_product"
        """

        responsesMock.addLiquidityPool(poolId: poolId, response: malformedJson)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)
        switch response {
        case .success:
            XCTFail("Expected failure due to malformed JSON")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed:
                XCTAssert(true, "Correctly received parsingResponseFailed error for malformed JSON")
            default:
                XCTFail("Expected parsingResponseFailed but got: \(error)")
            }
        }
    }

    func testGetLiquidityPoolsMalformedJSON() async {
        let responsesMock = LiquidityPoolsResponsesMock()
        let accountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let malformedJson = """
        {
          "_embedded": {
            "records": [
              {
                "id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
                "total_shares": null
              }
            ]
          }
        """

        responsesMock.addLiquidityPools(key: accountId, response: malformedJson)

        let response = await sdk.liquidityPools.getLiquidityPools(account: accountId)
        switch response {
        case .success:
            XCTFail("Expected failure due to malformed JSON")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed:
                XCTAssert(true, "Correctly received parsingResponseFailed error for malformed JSON")
            default:
                XCTFail("Expected parsingResponseFailed but got: \(error)")
            }
        }
    }

    // MARK: - LiquidityPoolDepositOperation Tests

    func testLiquidityPoolDepositOperationConstructor() {
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let maxAmountA = Decimal(string: "1000.5")!
        let maxAmountB = Decimal(string: "2000.75")!
        let minPrice = Price(numerator: 1, denominator: 2)
        let maxPrice = Price(numerator: 3, denominator: 1)

        let operation = LiquidityPoolDepositOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            maxAmountA: maxAmountA,
            maxAmountB: maxAmountB,
            minPrice: minPrice,
            maxPrice: maxPrice
        )

        XCTAssertEqual(operation.sourceAccountId, sourceAccountId)
        XCTAssertEqual(operation.liquidityPoolId, poolId)
        XCTAssertEqual(operation.maxAmountA, maxAmountA)
        XCTAssertEqual(operation.maxAmountB, maxAmountB)
        XCTAssertEqual(operation.minPrice.n, 1)
        XCTAssertEqual(operation.minPrice.d, 2)
        XCTAssertEqual(operation.maxPrice.n, 3)
        XCTAssertEqual(operation.maxPrice.d, 1)
    }

    func testLiquidityPoolDepositOperationToXDR() {
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let maxAmountA = Decimal(string: "100.0000000")!
        let maxAmountB = Decimal(string: "200.0000000")!
        let minPrice = Price(numerator: 1, denominator: 2)
        let maxPrice = Price(numerator: 2, denominator: 1)

        let operation = LiquidityPoolDepositOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            maxAmountA: maxAmountA,
            maxAmountB: maxAmountB,
            minPrice: minPrice,
            maxPrice: maxPrice
        )

        do {
            let operationXDR = try operation.toXDR()

            switch operationXDR.body {
            case .liquidityPoolDeposit(let depositXDR):
                XCTAssertEqual(depositXDR.liquidityPoolID.wrapped.base16EncodedString(), poolId)
                XCTAssertEqual(depositXDR.maxAmountA, 1000000000)
                XCTAssertEqual(depositXDR.maxAmountB, 2000000000)
                XCTAssertEqual(depositXDR.minPrice.n, 1)
                XCTAssertEqual(depositXDR.minPrice.d, 2)
                XCTAssertEqual(depositXDR.maxPrice.n, 2)
                XCTAssertEqual(depositXDR.maxPrice.d, 1)
            default:
                XCTFail("Expected liquidityPoolDeposit operation body")
            }
        } catch {
            XCTFail("Error converting operation to XDR: \(error)")
        }
    }

    func testLiquidityPoolDepositOperationFromXDR() {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let maxAmountA = Decimal(string: "100.0000000")!
        let maxAmountB = Decimal(string: "200.0000000")!
        let minPrice = Price(numerator: 1, denominator: 2)
        let maxPrice = Price(numerator: 2, denominator: 1)

        let operation = LiquidityPoolDepositOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            maxAmountA: maxAmountA,
            maxAmountB: maxAmountB,
            minPrice: minPrice,
            maxPrice: maxPrice
        )

        do {
            let operationXDR = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXDR) as! LiquidityPoolDepositOperation

            XCTAssertEqual(parsedOperation.sourceAccountId, sourceAccountId)
            XCTAssertEqual(parsedOperation.liquidityPoolId, poolId)
            XCTAssertEqual(parsedOperation.maxAmountA, maxAmountA)
            XCTAssertEqual(parsedOperation.maxAmountB, maxAmountB)
            XCTAssertEqual(parsedOperation.minPrice.n, 1)
            XCTAssertEqual(parsedOperation.minPrice.d, 2)
            XCTAssertEqual(parsedOperation.maxPrice.n, 2)
            XCTAssertEqual(parsedOperation.maxPrice.d, 1)
        } catch {
            XCTFail("Error in XDR round-trip: \(error)")
        }
    }

    func testLiquidityPoolDepositOperationWithLAddress() {
        let expectedHex = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let maxAmountA = Decimal(string: "100.0")!
        let maxAmountB = Decimal(string: "200.0")!
        let minPrice = Price(numerator: 1, denominator: 2)
        let maxPrice = Price(numerator: 2, denominator: 1)

        do {
            let lAddress = try expectedHex.encodeLiquidityPoolIdHex()

            let operation = LiquidityPoolDepositOperation(
                sourceAccountId: sourceAccountId,
                liquidityPoolId: lAddress,
                maxAmountA: maxAmountA,
                maxAmountB: maxAmountB,
                minPrice: minPrice,
                maxPrice: maxPrice
            )

            let operationXDR = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXDR) as! LiquidityPoolDepositOperation

            XCTAssertEqual(parsedOperation.liquidityPoolId, expectedHex)
        } catch {
            XCTFail("Error with L-address: \(error)")
        }
    }

    // MARK: - LiquidityPoolWithdrawOperation Tests

    func testLiquidityPoolWithdrawOperationConstructor() {
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let amount = Decimal(string: "500.0")!
        let minAmountA = Decimal(string: "100.0")!
        let minAmountB = Decimal(string: "200.0")!

        let operation = LiquidityPoolWithdrawOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            amount: amount,
            minAmountA: minAmountA,
            minAmountB: minAmountB
        )

        XCTAssertEqual(operation.sourceAccountId, sourceAccountId)
        XCTAssertEqual(operation.liquidityPoolId, poolId)
        XCTAssertEqual(operation.amount, amount)
        XCTAssertEqual(operation.minAmountA, minAmountA)
        XCTAssertEqual(operation.minAmountB, minAmountB)
    }

    func testLiquidityPoolWithdrawOperationToXDR() {
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let amount = Decimal(string: "500.0000000")!
        let minAmountA = Decimal(string: "100.0000000")!
        let minAmountB = Decimal(string: "200.0000000")!

        let operation = LiquidityPoolWithdrawOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            amount: amount,
            minAmountA: minAmountA,
            minAmountB: minAmountB
        )

        do {
            let operationXDR = try operation.toXDR()

            switch operationXDR.body {
            case .liquidityPoolWithdraw(let withdrawXDR):
                XCTAssertEqual(withdrawXDR.liquidityPoolID.wrapped.base16EncodedString(), poolId)
                XCTAssertEqual(withdrawXDR.amount, 5000000000)
                XCTAssertEqual(withdrawXDR.minAmountA, 1000000000)
                XCTAssertEqual(withdrawXDR.minAmountB, 2000000000)
            default:
                XCTFail("Expected liquidityPoolWithdraw operation body")
            }
        } catch {
            XCTFail("Error converting operation to XDR: \(error)")
        }
    }

    func testLiquidityPoolWithdrawOperationFromXDR() {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let amount = Decimal(string: "500.0000000")!
        let minAmountA = Decimal(string: "100.0000000")!
        let minAmountB = Decimal(string: "200.0000000")!

        let operation = LiquidityPoolWithdrawOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            amount: amount,
            minAmountA: minAmountA,
            minAmountB: minAmountB
        )

        do {
            let operationXDR = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXDR) as! LiquidityPoolWithdrawOperation

            XCTAssertEqual(parsedOperation.sourceAccountId, sourceAccountId)
            XCTAssertEqual(parsedOperation.liquidityPoolId, poolId)
            XCTAssertEqual(parsedOperation.amount, amount)
            XCTAssertEqual(parsedOperation.minAmountA, minAmountA)
            XCTAssertEqual(parsedOperation.minAmountB, minAmountB)
        } catch {
            XCTFail("Error in XDR round-trip: \(error)")
        }
    }

    func testLiquidityPoolWithdrawOperationWithLAddress() {
        let expectedHex = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let amount = Decimal(string: "500.0")!
        let minAmountA = Decimal(string: "100.0")!
        let minAmountB = Decimal(string: "200.0")!

        do {
            let lAddress = try expectedHex.encodeLiquidityPoolIdHex()

            let operation = LiquidityPoolWithdrawOperation(
                sourceAccountId: sourceAccountId,
                liquidityPoolId: lAddress,
                amount: amount,
                minAmountA: minAmountA,
                minAmountB: minAmountB
            )

            let operationXDR = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXDR) as! LiquidityPoolWithdrawOperation

            XCTAssertEqual(parsedOperation.liquidityPoolId, expectedHex)
        } catch {
            XCTFail("Error with L-address: \(error)")
        }
    }

    func testLiquidityPoolWithdrawOperationWithZeroAmounts() {
        let sourceAccountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let amount = Decimal(string: "100.0")!
        let minAmountA = Decimal(0)
        let minAmountB = Decimal(0)

        let operation = LiquidityPoolWithdrawOperation(
            sourceAccountId: sourceAccountId,
            liquidityPoolId: poolId,
            amount: amount,
            minAmountA: minAmountA,
            minAmountB: minAmountB
        )

        do {
            let operationXDR = try operation.toXDR()

            switch operationXDR.body {
            case .liquidityPoolWithdraw(let withdrawXDR):
                XCTAssertEqual(withdrawXDR.minAmountA, 0)
                XCTAssertEqual(withdrawXDR.minAmountB, 0)
            default:
                XCTFail("Expected liquidityPoolWithdraw operation body")
            }
        } catch {
            XCTFail("Error with zero amounts: \(error)")
        }
    }
}

// MARK: - Mock Classes

class LiquidityPoolNotFoundMock: ResponsesMock {
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/liquidity_pools/${pool_id}",
                          httpMethod: "GET",
                          mockHandler: handler)
    }
}
