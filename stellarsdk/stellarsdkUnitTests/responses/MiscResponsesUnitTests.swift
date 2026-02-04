//
//  MiscResponsesUnitTests.swift
//  stellarsdkTests
//
//  Created by Claude Code
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MiscResponsesUnitTests: XCTestCase {

    // MARK: - FeeChargedResponse Tests

    func testParseFeeChargedResponse() throws {
        let jsonResponse = """
        {
            "max": "100000",
            "min": "100",
            "mode": "100",
            "p10": "100",
            "p20": "100",
            "p30": "100",
            "p40": "100",
            "p50": "100",
            "p60": "100",
            "p70": "100",
            "p80": "100",
            "p90": "100",
            "p95": "200",
            "p99": "1000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeeChargedResponse.self, from: jsonData)

        XCTAssertEqual(response.max, "100000")
        XCTAssertEqual(response.min, "100")
        XCTAssertEqual(response.mode, "100")
        XCTAssertEqual(response.p10, "100")
        XCTAssertEqual(response.p20, "100")
        XCTAssertEqual(response.p30, "100")
        XCTAssertEqual(response.p40, "100")
        XCTAssertEqual(response.p50, "100")
        XCTAssertEqual(response.p60, "100")
        XCTAssertEqual(response.p70, "100")
        XCTAssertEqual(response.p80, "100")
        XCTAssertEqual(response.p90, "100")
        XCTAssertEqual(response.p95, "200")
        XCTAssertEqual(response.p99, "1000")
    }

    func testParseFeeChargedResponseWithHighValues() throws {
        let jsonResponse = """
        {
            "max": "9999999999",
            "min": "1",
            "mode": "500000",
            "p10": "10000",
            "p20": "20000",
            "p30": "30000",
            "p40": "40000",
            "p50": "50000",
            "p60": "60000",
            "p70": "70000",
            "p80": "80000",
            "p90": "90000",
            "p95": "95000",
            "p99": "99000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeeChargedResponse.self, from: jsonData)

        XCTAssertEqual(response.max, "9999999999")
        XCTAssertEqual(response.min, "1")
        XCTAssertEqual(response.mode, "500000")
        XCTAssertEqual(response.p50, "50000")
        XCTAssertEqual(response.p99, "99000")
    }

    // MARK: - MaxFeeResponse Tests

    func testParseMaxFeeResponse() throws {
        let jsonResponse = """
        {
            "max": "500000",
            "min": "100",
            "mode": "100",
            "p10": "100",
            "p20": "100",
            "p30": "100",
            "p40": "100",
            "p50": "100",
            "p60": "100",
            "p70": "100",
            "p80": "150",
            "p90": "200",
            "p95": "300",
            "p99": "500"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(MaxFeeResponse.self, from: jsonData)

        XCTAssertEqual(response.max, "500000")
        XCTAssertEqual(response.min, "100")
        XCTAssertEqual(response.mode, "100")
        XCTAssertEqual(response.p10, "100")
        XCTAssertEqual(response.p20, "100")
        XCTAssertEqual(response.p30, "100")
        XCTAssertEqual(response.p40, "100")
        XCTAssertEqual(response.p50, "100")
        XCTAssertEqual(response.p60, "100")
        XCTAssertEqual(response.p70, "100")
        XCTAssertEqual(response.p80, "150")
        XCTAssertEqual(response.p90, "200")
        XCTAssertEqual(response.p95, "300")
        XCTAssertEqual(response.p99, "500")
    }

    // MARK: - FeeStatsResponse Tests

    func testParseFeeStatsResponse() throws {
        let jsonResponse = """
        {
            "last_ledger": "12345678",
            "last_ledger_base_fee": "100",
            "ledger_capacity_usage": "0.47",
            "fee_charged": {
                "max": "100000",
                "min": "100",
                "mode": "100",
                "p10": "100",
                "p20": "100",
                "p30": "100",
                "p40": "100",
                "p50": "100",
                "p60": "100",
                "p70": "100",
                "p80": "100",
                "p90": "100",
                "p95": "200",
                "p99": "1000"
            },
            "max_fee": {
                "max": "500000",
                "min": "100",
                "mode": "100",
                "p10": "100",
                "p20": "100",
                "p30": "100",
                "p40": "100",
                "p50": "100",
                "p60": "100",
                "p70": "100",
                "p80": "150",
                "p90": "200",
                "p95": "300",
                "p99": "500"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeeStatsResponse.self, from: jsonData)

        XCTAssertEqual(response.lastLedger, "12345678")
        XCTAssertEqual(response.lastLedgerBaseFee, "100")
        XCTAssertEqual(response.ledgerCapacityUsage, "0.47")

        // Verify nested fee_charged
        XCTAssertEqual(response.feeCharged.max, "100000")
        XCTAssertEqual(response.feeCharged.min, "100")
        XCTAssertEqual(response.feeCharged.mode, "100")
        XCTAssertEqual(response.feeCharged.p50, "100")
        XCTAssertEqual(response.feeCharged.p99, "1000")

        // Verify nested max_fee
        XCTAssertEqual(response.maxFee.max, "500000")
        XCTAssertEqual(response.maxFee.min, "100")
        XCTAssertEqual(response.maxFee.mode, "100")
        XCTAssertEqual(response.maxFee.p80, "150")
        XCTAssertEqual(response.maxFee.p99, "500")
    }

    func testParseFeeStatsResponseWithHighCapacityUsage() throws {
        let jsonResponse = """
        {
            "last_ledger": "99999999",
            "last_ledger_base_fee": "100",
            "ledger_capacity_usage": "0.98",
            "fee_charged": {
                "max": "1000000",
                "min": "500",
                "mode": "750",
                "p10": "550",
                "p20": "600",
                "p30": "650",
                "p40": "700",
                "p50": "750",
                "p60": "800",
                "p70": "850",
                "p80": "900",
                "p90": "950",
                "p95": "975",
                "p99": "999"
            },
            "max_fee": {
                "max": "2000000",
                "min": "1000",
                "mode": "1500",
                "p10": "1100",
                "p20": "1200",
                "p30": "1300",
                "p40": "1400",
                "p50": "1500",
                "p60": "1600",
                "p70": "1700",
                "p80": "1800",
                "p90": "1900",
                "p95": "1950",
                "p99": "1999"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeeStatsResponse.self, from: jsonData)

        XCTAssertEqual(response.lastLedger, "99999999")
        XCTAssertEqual(response.ledgerCapacityUsage, "0.98")
        XCTAssertEqual(response.feeCharged.max, "1000000")
        XCTAssertEqual(response.maxFee.max, "2000000")
    }

    // MARK: - HealthCheckResponse Tests

    func testParseHealthCheckResponseHealthy() throws {
        let jsonResponse = """
        {
            "database_connected": true,
            "core_up": true,
            "core_synced": true
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertTrue(response.databaseConnected)
        XCTAssertTrue(response.coreUp)
        XCTAssertTrue(response.coreSynced)
        XCTAssertTrue(response.isHealthy)
    }

    func testParseHealthCheckResponseDatabaseNotConnected() throws {
        let jsonResponse = """
        {
            "database_connected": false,
            "core_up": true,
            "core_synced": true
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertFalse(response.databaseConnected)
        XCTAssertTrue(response.coreUp)
        XCTAssertTrue(response.coreSynced)
        XCTAssertFalse(response.isHealthy)
    }

    func testParseHealthCheckResponseCoreDown() throws {
        let jsonResponse = """
        {
            "database_connected": true,
            "core_up": false,
            "core_synced": false
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertTrue(response.databaseConnected)
        XCTAssertFalse(response.coreUp)
        XCTAssertFalse(response.coreSynced)
        XCTAssertFalse(response.isHealthy)
    }

    func testParseHealthCheckResponseCoreNotSynced() throws {
        let jsonResponse = """
        {
            "database_connected": true,
            "core_up": true,
            "core_synced": false
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertTrue(response.databaseConnected)
        XCTAssertTrue(response.coreUp)
        XCTAssertFalse(response.coreSynced)
        XCTAssertFalse(response.isHealthy)
    }

    func testParseHealthCheckResponseAllUnhealthy() throws {
        let jsonResponse = """
        {
            "database_connected": false,
            "core_up": false,
            "core_synced": false
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertFalse(response.databaseConnected)
        XCTAssertFalse(response.coreUp)
        XCTAssertFalse(response.coreSynced)
        XCTAssertFalse(response.isHealthy)
    }

    // MARK: - LiquidityPoolPriceResponse Tests

    func testParseLiquidityPoolPriceResponse() throws {
        let jsonResponse = """
        {
            "n": 1,
            "d": 2
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(LiquidityPoolPriceResponse.self, from: jsonData)

        XCTAssertEqual(response.n, 1)
        XCTAssertEqual(response.d, 2)
    }

    func testParseLiquidityPoolPriceResponseWithLargeValues() throws {
        let jsonResponse = """
        {
            "n": 2147483647,
            "d": 1000000
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(LiquidityPoolPriceResponse.self, from: jsonData)

        XCTAssertEqual(response.n, 2147483647)
        XCTAssertEqual(response.d, 1000000)
    }

    func testParseLiquidityPoolPriceResponseWithEqualValues() throws {
        let jsonResponse = """
        {
            "n": 1,
            "d": 1
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(LiquidityPoolPriceResponse.self, from: jsonData)

        XCTAssertEqual(response.n, 1)
        XCTAssertEqual(response.d, 1)
    }

    // MARK: - OrderbookOfferResponse Tests

    func testParseOrderbookOfferResponse() throws {
        let jsonResponse = """
        {
            "price_r": {
                "n": 100,
                "d": 10
            },
            "price": "10.0000000",
            "amount": "500.0000000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OrderbookOfferResponse.self, from: jsonData)

        XCTAssertEqual(response.priceR.numerator, 100)
        XCTAssertEqual(response.priceR.denominator, 10)
        XCTAssertEqual(response.price, "10.0000000")
        XCTAssertEqual(response.amount, "500.0000000")
    }

    func testParseOrderbookOfferResponseWithSmallPrice() throws {
        let jsonResponse = """
        {
            "price_r": {
                "n": 1,
                "d": 1000000
            },
            "price": "0.0000010",
            "amount": "10000000.0000000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OrderbookOfferResponse.self, from: jsonData)

        XCTAssertEqual(response.priceR.numerator, 1)
        XCTAssertEqual(response.priceR.denominator, 1000000)
        XCTAssertEqual(response.price, "0.0000010")
        XCTAssertEqual(response.amount, "10000000.0000000")
    }

    // MARK: - OrderbookResponse Tests

    func testParseOrderbookResponse() throws {
        let jsonResponse = """
        {
            "bids": [
                {
                    "price_r": {
                        "n": 100,
                        "d": 10
                    },
                    "price": "10.0000000",
                    "amount": "500.0000000"
                },
                {
                    "price_r": {
                        "n": 95,
                        "d": 10
                    },
                    "price": "9.5000000",
                    "amount": "250.0000000"
                }
            ],
            "asks": [
                {
                    "price_r": {
                        "n": 105,
                        "d": 10
                    },
                    "price": "10.5000000",
                    "amount": "300.0000000"
                }
            ],
            "base": {
                "asset_type": "native"
            },
            "counter": {
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GCZJM35NKGVK47BB4SPBDV25477PEZZ73PGY5E7EIZTJ6OUKZURKQBZ7T"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OrderbookResponse.self, from: jsonData)

        // Verify bids
        XCTAssertEqual(response.bids.count, 2)
        XCTAssertEqual(response.bids[0].price, "10.0000000")
        XCTAssertEqual(response.bids[0].amount, "500.0000000")
        XCTAssertEqual(response.bids[1].price, "9.5000000")
        XCTAssertEqual(response.bids[1].amount, "250.0000000")

        // Verify asks
        XCTAssertEqual(response.asks.count, 1)
        XCTAssertEqual(response.asks[0].price, "10.5000000")
        XCTAssertEqual(response.asks[0].amount, "300.0000000")

        // Verify selling (base) asset
        XCTAssertEqual(response.selling.assetType, "native")
        XCTAssertNil(response.selling.assetCode)
        XCTAssertNil(response.selling.assetIssuer)

        // Verify buying (counter) asset
        XCTAssertEqual(response.buying.assetType, "credit_alphanum4")
        XCTAssertEqual(response.buying.assetCode, "USD")
        XCTAssertEqual(response.buying.assetIssuer, "GCZJM35NKGVK47BB4SPBDV25477PEZZ73PGY5E7EIZTJ6OUKZURKQBZ7T")
    }

    func testParseOrderbookResponseEmptyBidsAndAsks() throws {
        let jsonResponse = """
        {
            "bids": [],
            "asks": [],
            "base": {
                "asset_type": "credit_alphanum12",
                "asset_code": "SILVERTOKEN",
                "asset_issuer": "GCNY5OXYSY4FKHOPT2SPOQZAOEIGXB5LBYW3HVU3OWSTQITS65M5RCNY"
            },
            "counter": {
                "asset_type": "native"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OrderbookResponse.self, from: jsonData)

        XCTAssertEqual(response.bids.count, 0)
        XCTAssertEqual(response.asks.count, 0)
        XCTAssertEqual(response.selling.assetType, "credit_alphanum12")
        XCTAssertEqual(response.selling.assetCode, "SILVERTOKEN")
        XCTAssertEqual(response.buying.assetType, "native")
    }

    func testParseOrderbookResponseMultipleBidsAndAsks() throws {
        let jsonResponse = """
        {
            "bids": [
                {
                    "price_r": {"n": 100, "d": 10},
                    "price": "10.0000000",
                    "amount": "100.0000000"
                },
                {
                    "price_r": {"n": 99, "d": 10},
                    "price": "9.9000000",
                    "amount": "200.0000000"
                },
                {
                    "price_r": {"n": 98, "d": 10},
                    "price": "9.8000000",
                    "amount": "300.0000000"
                }
            ],
            "asks": [
                {
                    "price_r": {"n": 101, "d": 10},
                    "price": "10.1000000",
                    "amount": "150.0000000"
                },
                {
                    "price_r": {"n": 102, "d": 10},
                    "price": "10.2000000",
                    "amount": "250.0000000"
                }
            ],
            "base": {
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GDVKY2GU2DRXWTBETVJWWNPAG4BNNYW6ZZ7ROVZ3CQBLIZAKP5QX5G5P"
            },
            "counter": {
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GCZJM35NKGVK47BB4SPBDV25477PEZZ73PGY5E7EIZTJ6OUKZURKQBZ7T"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OrderbookResponse.self, from: jsonData)

        XCTAssertEqual(response.bids.count, 3)
        XCTAssertEqual(response.asks.count, 2)

        // Verify first bid
        XCTAssertEqual(response.bids[0].price, "10.0000000")
        XCTAssertEqual(response.bids[0].priceR.numerator, 100)
        XCTAssertEqual(response.bids[0].priceR.denominator, 10)

        // Verify last ask
        XCTAssertEqual(response.asks[1].price, "10.2000000")
        XCTAssertEqual(response.asks[1].amount, "250.0000000")
    }

    // MARK: - TradeAggregationResponse Tests

    func testParseTradeAggregationResponse() throws {
        let jsonResponse = """
        {
            "timestamp": "1609459200000",
            "trade_count": "150",
            "base_volume": "1000000.0000000",
            "counter_volume": "500000.0000000",
            "avg": "0.5000000",
            "high": "0.5500000",
            "low": "0.4500000",
            "open": "0.4800000",
            "close": "0.5200000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TradeAggregationResponse.self, from: jsonData)

        XCTAssertEqual(response.timestamp, "1609459200000")
        XCTAssertEqual(response.tradeCount, "150")
        XCTAssertEqual(response.baseVolume, "1000000.0000000")
        XCTAssertEqual(response.counterVolume, "500000.0000000")
        XCTAssertEqual(response.averagePrice, "0.5000000")
        XCTAssertEqual(response.highPrice, "0.5500000")
        XCTAssertEqual(response.lowPrice, "0.4500000")
        XCTAssertEqual(response.openPrice, "0.4800000")
        XCTAssertEqual(response.closePrice, "0.5200000")
    }

    func testParseTradeAggregationResponseWithHighVolume() throws {
        let jsonResponse = """
        {
            "timestamp": "1696118400000",
            "trade_count": "50000",
            "base_volume": "9999999999.0000000",
            "counter_volume": "4999999999.5000000",
            "avg": "0.5000000",
            "high": "1.0000000",
            "low": "0.0100000",
            "open": "0.5000000",
            "close": "0.5000000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TradeAggregationResponse.self, from: jsonData)

        XCTAssertEqual(response.timestamp, "1696118400000")
        XCTAssertEqual(response.tradeCount, "50000")
        XCTAssertEqual(response.baseVolume, "9999999999.0000000")
        XCTAssertEqual(response.counterVolume, "4999999999.5000000")
        XCTAssertEqual(response.highPrice, "1.0000000")
        XCTAssertEqual(response.lowPrice, "0.0100000")
    }

    func testParseTradeAggregationResponseWithSingleTrade() throws {
        let jsonResponse = """
        {
            "timestamp": "1609459200000",
            "trade_count": "1",
            "base_volume": "100.0000000",
            "counter_volume": "50.0000000",
            "avg": "0.5000000",
            "high": "0.5000000",
            "low": "0.5000000",
            "open": "0.5000000",
            "close": "0.5000000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TradeAggregationResponse.self, from: jsonData)

        XCTAssertEqual(response.tradeCount, "1")
        XCTAssertEqual(response.openPrice, response.closePrice)
        XCTAssertEqual(response.highPrice, response.lowPrice)
        XCTAssertEqual(response.averagePrice, response.openPrice)
    }

    // MARK: - FeeBumpTransactionResponse Tests

    func testParseFeeBumpTransactionResponse() throws {
        let jsonResponse = """
        {
            "hash": "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889",
            "signatures": [
                "MEUCIQC8nDZ8VYfS98PyDTLI7lT76CkxKCnV+VD8+MTVFeCZaAIgE1YOx6dR2G1Qjn9T5lAbvXyh3N1Xj9E/K5KVeVKdXcc="
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeeBumpTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.transactionHash, "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889")
        XCTAssertEqual(response.signatures.count, 1)
        XCTAssertEqual(response.signatures[0], "MEUCIQC8nDZ8VYfS98PyDTLI7lT76CkxKCnV+VD8+MTVFeCZaAIgE1YOx6dR2G1Qjn9T5lAbvXyh3N1Xj9E/K5KVeVKdXcc=")
    }

    func testParseFeeBumpTransactionResponseWithMultipleSignatures() throws {
        let jsonResponse = """
        {
            "hash": "abc123def456abc123def456abc123def456abc123def456abc123def456abc1",
            "signatures": [
                "sig1base64encoded==",
                "sig2base64encoded==",
                "sig3base64encoded=="
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeeBumpTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.transactionHash, "abc123def456abc123def456abc123def456abc123def456abc123def456abc1")
        XCTAssertEqual(response.signatures.count, 3)
        XCTAssertEqual(response.signatures[0], "sig1base64encoded==")
        XCTAssertEqual(response.signatures[1], "sig2base64encoded==")
        XCTAssertEqual(response.signatures[2], "sig3base64encoded==")
    }

    // MARK: - InnerTransactionResponse Tests

    func testParseInnerTransactionResponse() throws {
        let jsonResponse = """
        {
            "hash": "e98869bba8bce08c10b78406202127f3888c25454cd37b02600862452751f526",
            "signatures": [
                "MEQCIBT7n0sIlxklQCExZx/R1+BqcJcRYyKlYP9EeLvVj3c1AiBklSVfKfLJWu9qKS3kKzQqzITJk5JMQD5aIzqUZBJeAg=="
            ],
            "max_fee": "100"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(InnerTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.transactionHash, "e98869bba8bce08c10b78406202127f3888c25454cd37b02600862452751f526")
        XCTAssertEqual(response.signatures.count, 1)
        XCTAssertEqual(response.maxFee, "100")
    }

    func testParseInnerTransactionResponseWithHighFee() throws {
        let jsonResponse = """
        {
            "hash": "abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234",
            "signatures": [
                "signature1==",
                "signature2=="
            ],
            "max_fee": "10000000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(InnerTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.transactionHash, "abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234")
        XCTAssertEqual(response.signatures.count, 2)
        XCTAssertEqual(response.maxFee, "10000000")
    }

    // MARK: - PreconditionsLedgerBoundsResponse Tests

    func testParsePreconditionsLedgerBoundsResponse() throws {
        let jsonResponse = """
        {
            "min_ledger": 1000000,
            "max_ledger": 2000000
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsLedgerBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minLedger, 1000000)
        XCTAssertEqual(response.maxLedger, 2000000)
    }

    func testParsePreconditionsLedgerBoundsResponseWithZeroMin() throws {
        let jsonResponse = """
        {
            "min_ledger": 0,
            "max_ledger": 5000000
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsLedgerBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minLedger, 0)
        XCTAssertEqual(response.maxLedger, 5000000)
    }

    func testParsePreconditionsLedgerBoundsResponseWithZeroMax() throws {
        let jsonResponse = """
        {
            "min_ledger": 1000000,
            "max_ledger": 0
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsLedgerBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minLedger, 1000000)
        XCTAssertEqual(response.maxLedger, 0)
    }

    func testParsePreconditionsLedgerBoundsResponseWithLargeValues() throws {
        let jsonResponse = """
        {
            "min_ledger": 2147483640,
            "max_ledger": 2147483647
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsLedgerBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minLedger, 2147483640)
        XCTAssertEqual(response.maxLedger, 2147483647)
    }

    // MARK: - PreconditionsTimeBoundsResponse Tests

    func testParsePreconditionsTimeBoundsResponse() throws {
        let jsonResponse = """
        {
            "min_time": "1609459200",
            "max_time": "1609545600"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsTimeBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minTime, "1609459200")
        XCTAssertEqual(response.maxTime, "1609545600")
    }

    func testParsePreconditionsTimeBoundsResponseWithMinTimeOnly() throws {
        let jsonResponse = """
        {
            "min_time": "1609459200"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsTimeBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minTime, "1609459200")
        XCTAssertNil(response.maxTime)
    }

    func testParsePreconditionsTimeBoundsResponseWithMaxTimeOnly() throws {
        let jsonResponse = """
        {
            "max_time": "1609545600"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsTimeBoundsResponse.self, from: jsonData)

        XCTAssertNil(response.minTime)
        XCTAssertEqual(response.maxTime, "1609545600")
    }

    func testParsePreconditionsTimeBoundsResponseWithZeroValues() throws {
        let jsonResponse = """
        {
            "min_time": "0",
            "max_time": "0"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsTimeBoundsResponse.self, from: jsonData)

        XCTAssertEqual(response.minTime, "0")
        XCTAssertEqual(response.maxTime, "0")
    }

    func testParsePreconditionsTimeBoundsResponseEmpty() throws {
        let jsonResponse = """
        {}
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PreconditionsTimeBoundsResponse.self, from: jsonData)

        XCTAssertNil(response.minTime)
        XCTAssertNil(response.maxTime)
    }

    // MARK: - SubmitTransactionAsyncResponse Tests

    func testParseSubmitTransactionAsyncResponsePending() throws {
        let jsonResponse = """
        {
            "tx_status": "PENDING",
            "hash": "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SubmitTransactionAsyncResponse.self, from: jsonData)

        XCTAssertEqual(response.txStatus, "PENDING")
        XCTAssertEqual(response.txHash, "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889")
    }

    func testParseSubmitTransactionAsyncResponseDuplicate() throws {
        let jsonResponse = """
        {
            "tx_status": "DUPLICATE",
            "hash": "e98869bba8bce08c10b78406202127f3888c25454cd37b02600862452751f526"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SubmitTransactionAsyncResponse.self, from: jsonData)

        XCTAssertEqual(response.txStatus, "DUPLICATE")
        XCTAssertEqual(response.txHash, "e98869bba8bce08c10b78406202127f3888c25454cd37b02600862452751f526")
    }

    func testParseSubmitTransactionAsyncResponseTryAgainLater() throws {
        let jsonResponse = """
        {
            "tx_status": "TRY_AGAIN_LATER",
            "hash": "abc123def456abc123def456abc123def456abc123def456abc123def456abc1"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SubmitTransactionAsyncResponse.self, from: jsonData)

        XCTAssertEqual(response.txStatus, "TRY_AGAIN_LATER")
        XCTAssertEqual(response.txHash, "abc123def456abc123def456abc123def456abc123def456abc123def456abc1")
    }

    func testParseSubmitTransactionAsyncResponseError() throws {
        let jsonResponse = """
        {
            "tx_status": "ERROR",
            "hash": "def456abc123def456abc123def456abc123def456abc123def456abc123def4"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SubmitTransactionAsyncResponse.self, from: jsonData)

        XCTAssertEqual(response.txStatus, "ERROR")
        XCTAssertEqual(response.txHash, "def456abc123def456abc123def456abc123def456abc123def456abc123def4")
    }

    // MARK: - TransactionPreconditionsResponse Tests

    func testParseTransactionPreconditionsResponseFull() throws {
        let jsonResponse = """
        {
            "timebounds": {
                "min_time": "1609459200",
                "max_time": "1609545600"
            },
            "ledgerbounds": {
                "min_ledger": 1000000,
                "max_ledger": 2000000
            },
            "min_account_sequence": "12345678",
            "min_account_sequence_age": "86400",
            "min_account_sequence_ledger_gap": 100,
            "extra_signers": [
                "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ",
                "GDZX6HCFR3DXSXMHK3CCPGOHBUWRB4CZDEKZ3BKLXQPWFXDYQLVQGRP6"
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TransactionPreconditionsResponse.self, from: jsonData)

        // Verify time bounds
        XCTAssertNotNil(response.timeBounds)
        XCTAssertEqual(response.timeBounds?.minTime, "1609459200")
        XCTAssertEqual(response.timeBounds?.maxTime, "1609545600")

        // Verify ledger bounds
        XCTAssertNotNil(response.ledgerBounds)
        XCTAssertEqual(response.ledgerBounds?.minLedger, 1000000)
        XCTAssertEqual(response.ledgerBounds?.maxLedger, 2000000)

        // Verify sequence constraints
        XCTAssertEqual(response.minAccountSequence, "12345678")
        XCTAssertEqual(response.minAccountSequenceAge, "86400")
        XCTAssertEqual(response.minAccountSequenceLedgerGap, 100)

        // Verify extra signers
        XCTAssertNotNil(response.extraSigners)
        XCTAssertEqual(response.extraSigners?.count, 2)
        XCTAssertEqual(response.extraSigners?[0], "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
        XCTAssertEqual(response.extraSigners?[1], "GDZX6HCFR3DXSXMHK3CCPGOHBUWRB4CZDEKZ3BKLXQPWFXDYQLVQGRP6")
    }

    func testParseTransactionPreconditionsResponseTimeBoundsOnly() throws {
        let jsonResponse = """
        {
            "timebounds": {
                "min_time": "1609459200",
                "max_time": "1609545600"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TransactionPreconditionsResponse.self, from: jsonData)

        XCTAssertNotNil(response.timeBounds)
        XCTAssertEqual(response.timeBounds?.minTime, "1609459200")
        XCTAssertEqual(response.timeBounds?.maxTime, "1609545600")

        XCTAssertNil(response.ledgerBounds)
        XCTAssertNil(response.minAccountSequence)
        XCTAssertNil(response.minAccountSequenceAge)
        XCTAssertNil(response.minAccountSequenceLedgerGap)
        XCTAssertNil(response.extraSigners)
    }

    func testParseTransactionPreconditionsResponseLedgerBoundsOnly() throws {
        let jsonResponse = """
        {
            "ledgerbounds": {
                "min_ledger": 5000000,
                "max_ledger": 6000000
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TransactionPreconditionsResponse.self, from: jsonData)

        XCTAssertNil(response.timeBounds)

        XCTAssertNotNil(response.ledgerBounds)
        XCTAssertEqual(response.ledgerBounds?.minLedger, 5000000)
        XCTAssertEqual(response.ledgerBounds?.maxLedger, 6000000)

        XCTAssertNil(response.minAccountSequence)
        XCTAssertNil(response.minAccountSequenceAge)
        XCTAssertNil(response.minAccountSequenceLedgerGap)
        XCTAssertNil(response.extraSigners)
    }

    func testParseTransactionPreconditionsResponseEmpty() throws {
        let jsonResponse = """
        {}
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TransactionPreconditionsResponse.self, from: jsonData)

        XCTAssertNil(response.timeBounds)
        XCTAssertNil(response.ledgerBounds)
        XCTAssertNil(response.minAccountSequence)
        XCTAssertNil(response.minAccountSequenceAge)
        XCTAssertNil(response.minAccountSequenceLedgerGap)
        XCTAssertNil(response.extraSigners)
    }

    func testParseTransactionPreconditionsResponseWithExtraSignersOnly() throws {
        let jsonResponse = """
        {
            "extra_signers": [
                "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TransactionPreconditionsResponse.self, from: jsonData)

        XCTAssertNil(response.timeBounds)
        XCTAssertNil(response.ledgerBounds)
        XCTAssertNil(response.minAccountSequence)
        XCTAssertNil(response.minAccountSequenceAge)
        XCTAssertNil(response.minAccountSequenceLedgerGap)

        XCTAssertNotNil(response.extraSigners)
        XCTAssertEqual(response.extraSigners?.count, 1)
        XCTAssertEqual(response.extraSigners?[0], "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
    }

    func testParseTransactionPreconditionsResponseWithSequenceConstraints() throws {
        let jsonResponse = """
        {
            "min_account_sequence": "9999999999",
            "min_account_sequence_age": "172800",
            "min_account_sequence_ledger_gap": 500
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TransactionPreconditionsResponse.self, from: jsonData)

        XCTAssertNil(response.timeBounds)
        XCTAssertNil(response.ledgerBounds)

        XCTAssertEqual(response.minAccountSequence, "9999999999")
        XCTAssertEqual(response.minAccountSequenceAge, "172800")
        XCTAssertEqual(response.minAccountSequenceLedgerGap, 500)

        XCTAssertNil(response.extraSigners)
    }
}
