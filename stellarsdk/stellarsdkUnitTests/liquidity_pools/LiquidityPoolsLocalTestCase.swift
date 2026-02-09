//
//  LiquidityPoolsLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LiquidityPoolsLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var responsesMock: LiquidityPoolsResponsesMock?
    var mockRegistered = false

    override func setUp() {
        super.setUp()

        ServerMock.removeAll()
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }

        responsesMock = LiquidityPoolsResponsesMock()
    }

    override func tearDown() {
        responsesMock = nil
        super.tearDown()
    }

    func testGetLiquidityPool() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let poolJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
            },
            "operations": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/operations{?cursor,limit,order}",
              "templated": true
            },
            "trades": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/trades{?cursor,limit,order}",
              "templated": true
            },
            "transactions": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/transactions{?cursor,limit,order}",
              "templated": true
            }
          },
          "id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "paging_token": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "fee_bp": 30,
          "type": "constant_product",
          "total_trustlines": "300",
          "total_shares": "5000",
          "reserves": [
            {
              "amount": "1000.0000005",
              "asset": "EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S"
            },
            {
              "amount": "2000.0000000",
              "asset": "PHP:GBUQWP3BOUZX34TOND2QV7QQ7K7VJTG6VSE7WMLBTMDJLLAW7YKGU6EP"
            }
          ],
          "last_modified_ledger": 7877447,
          "last_modified_time": "2021-11-18T03:47:47Z"
        }
        """

        responsesMock?.addLiquidityPool(poolId: poolId, response: poolJson)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)
        switch response {
        case .success(let pool):
            XCTAssertEqual(pool.poolId, poolId)
            XCTAssertEqual(pool.fee, 30)
            XCTAssertEqual(pool.type, "constant_product")
            XCTAssertEqual(pool.totalTrustlines, "300")
            XCTAssertEqual(pool.totalShares, "5000")
            XCTAssertEqual(pool.reserves.count, 2)
            XCTAssertEqual(pool.reserves[0].amount, "1000.0000005")
            XCTAssertEqual(pool.reserves[1].amount, "2000.0000000")
            XCTAssertEqual(pool.lastModifiedLedger, 7877447)
            XCTAssertEqual(pool.lastModifiedTime, "2021-11-18T03:47:47Z")
            XCTAssertEqual(pool.pagingToken, poolId)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetLiquidityPool()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testGetLiquidityPools() async {
        let accountId = "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
        let poolsJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools?account=GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B&cursor=&limit=10&order=asc"
            },
            "next": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools?account=GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B&cursor=dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7&limit=10&order=asc"
            },
            "prev": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools?account=GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B&cursor=dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7&limit=10&order=desc"
            }
          },
          "_embedded": {
            "records": [
              {
                "_links": {
                  "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
                  },
                  "transactions": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/transactions{?cursor,limit,order}",
                    "templated": true
                  },
                  "operations": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/operations{?cursor,limit,order}",
                    "templated": true
                  }
                },
                "id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
                "paging_token": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "300",
                "total_shares": "5000",
                "reserves": [
                  {
                    "amount": "1000.0000005",
                    "asset": "EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S"
                  },
                  {
                    "amount": "2000.0000000",
                    "asset": "PHP:GBUQWP3BOUZX34TOND2QV7QQ7K7VJTG6VSE7WMLBTMDJLLAW7YKGU6EP"
                  }
                ],
                "last_modified_ledger": 7877447,
                "last_modified_time": "2021-11-18T03:47:47Z"
              },
              {
                "_links": {
                  "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/ae7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac8"
                  },
                  "transactions": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/ae7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac8/transactions{?cursor,limit,order}",
                    "templated": true
                  },
                  "operations": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/ae7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac8/operations{?cursor,limit,order}",
                    "templated": true
                  }
                },
                "id": "ae7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac8",
                "paging_token": "ae7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac8",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "200",
                "total_shares": "3000",
                "reserves": [
                  {
                    "amount": "500.0000000",
                    "asset": "native"
                  },
                  {
                    "amount": "1500.0000000",
                    "asset": "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
                  }
                ],
                "last_modified_ledger": 7877448,
                "last_modified_time": "2021-11-18T03:47:52Z"
              }
            ]
          }
        }
        """

        responsesMock?.addLiquidityPools(key: accountId, response: poolsJson)

        let response = await sdk.liquidityPools.getLiquidityPools(account: accountId)
        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
            XCTAssertEqual(page.records.count, 2)

            let firstPool = page.records[0]
            XCTAssertEqual(firstPool.poolId, "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7")
            XCTAssertEqual(firstPool.fee, 30)
            XCTAssertEqual(firstPool.type, "constant_product")
            XCTAssertEqual(firstPool.totalShares, "5000")
            XCTAssertEqual(firstPool.reserves.count, 2)

            let secondPool = page.records[1]
            XCTAssertEqual(secondPool.poolId, "ae7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac8")
            XCTAssertEqual(secondPool.totalShares, "3000")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetLiquidityPools()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testLiquidityPoolResponse() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let poolJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
            },
            "operations": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/operations{?cursor,limit,order}",
              "templated": true
            },
            "trades": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/trades{?cursor,limit,order}",
              "templated": true
            },
            "transactions": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/transactions{?cursor,limit,order}",
              "templated": true
            }
          },
          "id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "paging_token": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "fee_bp": 30,
          "type": "constant_product",
          "total_trustlines": "300",
          "total_shares": "5000",
          "reserves": [
            {
              "amount": "1000.0000005",
              "asset": "EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S"
            },
            {
              "amount": "2000.0000000",
              "asset": "PHP:GBUQWP3BOUZX34TOND2QV7QQ7K7VJTG6VSE7WMLBTMDJLLAW7YKGU6EP"
            }
          ],
          "last_modified_ledger": 7877447,
          "last_modified_time": "2021-11-18T03:47:47Z"
        }
        """

        responsesMock?.addLiquidityPool(poolId: poolId, response: poolJson)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)
        switch response {
        case .success(let pool):
            XCTAssertNotNil(pool.links)
            XCTAssertEqual(pool.poolId, poolId)
            XCTAssertEqual(pool.pagingToken, poolId)
            XCTAssertEqual(pool.fee, 30)
            XCTAssertEqual(pool.type, "constant_product")
            XCTAssertEqual(pool.totalTrustlines, "300")
            XCTAssertEqual(pool.totalShares, "5000")
            XCTAssertEqual(pool.lastModifiedLedger, 7877447)
            XCTAssertEqual(pool.lastModifiedTime, "2021-11-18T03:47:47Z")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testLiquidityPoolResponse()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testLiquidityPoolReserves() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let poolJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
            },
            "transactions": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/transactions{?cursor,limit,order}",
              "templated": true
            },
            "operations": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/operations{?cursor,limit,order}",
              "templated": true
            }
          },
          "id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "paging_token": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
          "fee_bp": 30,
          "type": "constant_product",
          "total_trustlines": "300",
          "total_shares": "5000",
          "reserves": [
            {
              "amount": "1000.0000005",
              "asset": "EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S"
            },
            {
              "amount": "2000.0000000",
              "asset": "PHP:GBUQWP3BOUZX34TOND2QV7QQ7K7VJTG6VSE7WMLBTMDJLLAW7YKGU6EP"
            }
          ],
          "last_modified_ledger": 7877447,
          "last_modified_time": "2021-11-18T03:47:47Z"
        }
        """

        responsesMock?.addLiquidityPool(poolId: poolId, response: poolJson)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)
        switch response {
        case .success(let pool):
            XCTAssertEqual(pool.reserves.count, 2)

            let reserve0 = pool.reserves[0]
            XCTAssertEqual(reserve0.amount, "1000.0000005")
            XCTAssertTrue(reserve0.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(reserve0.asset.code, "EURT")
            XCTAssertEqual(reserve0.asset.issuer?.accountId, "GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S")

            let reserve1 = pool.reserves[1]
            XCTAssertEqual(reserve1.amount, "2000.0000000")
            XCTAssertTrue(reserve1.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(reserve1.asset.code, "PHP")
            XCTAssertEqual(reserve1.asset.issuer?.accountId, "GBUQWP3BOUZX34TOND2QV7QQ7K7VJTG6VSE7WMLBTMDJLLAW7YKGU6EP")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testLiquidityPoolReserves()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testLiquidityPoolTrades() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let tradesJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/trades?cursor=&limit=10&order=asc"
            },
            "next": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/trades?cursor=107449468024365057-0&limit=10&order=asc"
            },
            "prev": {
              "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/trades?cursor=107449468024365057-0&limit=10&order=desc"
            }
          },
          "_embedded": {
            "records": [
              {
                "_links": {
                  "self": {
                    "href": ""
                  },
                  "base": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B"
                  },
                  "counter": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
                  },
                  "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/107449468024365057"
                  }
                },
                "id": "107449468024365057-0",
                "paging_token": "107449468024365057-0",
                "ledger_close_time": "2019-07-26T09:17:02Z",
                "offer_id": "0",
                "trade_type": "liquidity_pool",
                "liquidity_pool_fee_bp": 30,
                "base_liquidity_pool_id": "",
                "base_offer_id": "0",
                "base_account": "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B",
                "base_amount": "100.0000000",
                "base_asset_type": "credit_alphanum4",
                "base_asset_code": "EURT",
                "base_asset_issuer": "GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S",
                "counter_liquidity_pool_id": "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7",
                "counter_offer_id": "0",
                "counter_account": "",
                "counter_amount": "200.0000000",
                "counter_asset_type": "credit_alphanum4",
                "counter_asset_code": "PHP",
                "counter_asset_issuer": "GBUQWP3BOUZX34TOND2QV7QQ7K7VJTG6VSE7WMLBTMDJLLAW7YKGU6EP",
                "base_is_seller": true,
                "price": {
                  "n": "2",
                  "d": "1"
                }
              }
            ]
          }
        }
        """

        responsesMock?.addLiquidityPoolTrades(poolId: poolId, response: tradesJson)

        let response = await sdk.liquidityPools.getLiquidityPoolTrades(poolId: poolId)
        switch response {
        case .success(let tradesResponse):
            XCTAssertNotNil(tradesResponse.links)
            XCTAssertEqual(tradesResponse.records.count, 1)

            let trade = tradesResponse.records[0]
            XCTAssertEqual(trade.id, "107449468024365057-0")
            XCTAssertEqual(trade.pagingToken, "107449468024365057-0")
            XCTAssertEqual(trade.tradeType, "liquidity_pool")
            XCTAssertEqual(trade.liquidityPoolFeeBp, 30)
            XCTAssertEqual(trade.baseAccount, "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B")
            XCTAssertEqual(trade.baseAmount, "100.0000000")
            XCTAssertEqual(trade.counterLiquidityPoolId, "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7")
            XCTAssertEqual(trade.counterAmount, "200.0000000")
            XCTAssertEqual(trade.baseIsSeller, true)
            XCTAssertNotNil(trade.price)
            XCTAssertEqual(trade.price.n, "2")
            XCTAssertEqual(trade.price.d, "1")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testLiquidityPoolTrades()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }
}
