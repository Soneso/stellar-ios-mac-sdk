//
//  PaymentPathsResponseUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 04/02/2026.
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Unit tests for PaymentPathResponse and FindPaymentPathsResponse
class PaymentPathsResponseUnitTests: XCTestCase {

    // MARK: - Existing Tests (Relocated)

    func testFindPaymentPathsResponseDecoding() {
        let jsonString = """
        {
            "_embedded": {
                "records": [
                    {
                        "source_asset_type": "credit_alphanum4",
                        "source_asset_code": "USD",
                        "source_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                        "source_amount": "100.0000000",
                        "destination_asset_type": "credit_alphanum4",
                        "destination_asset_code": "EUR",
                        "destination_asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM",
                        "destination_amount": "85.5000000",
                        "path": [
                            {
                                "asset_type": "credit_alphanum4",
                                "asset_code": "BTC",
                                "asset_issuer": "GAUTUYY2THLF7SGITDFMXJVYH3LHDSMGEAKSBU267M2K7A3W543CKUEF"
                            }
                        ]
                    },
                    {
                        "source_asset_type": "native",
                        "source_amount": "50.0000000",
                        "destination_asset_type": "credit_alphanum12",
                        "destination_asset_code": "TESTTOKEN",
                        "destination_asset_issuer": "GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5",
                        "destination_amount": "1000.0000000",
                        "path": []
                    }
                ]
            }
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()
            let response = try decoder.decode(FindPaymentPathsResponse.self, from: jsonData)

            XCTAssertEqual(response.records.count, 2)

            let firstPath = response.records[0]
            XCTAssertEqual(firstPath.sourceAssetType, "credit_alphanum4")
            XCTAssertEqual(firstPath.sourceAssetCode, "USD")
            XCTAssertEqual(firstPath.sourceAssetIssuer, "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX")
            XCTAssertEqual(firstPath.sourceAmount, "100.0000000")
            XCTAssertEqual(firstPath.destinationAssetType, "credit_alphanum4")
            XCTAssertEqual(firstPath.destinationAssetCode, "EUR")
            XCTAssertEqual(firstPath.destinationAssetIssuer, "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM")
            XCTAssertEqual(firstPath.destinationAmount, "85.5000000")
            XCTAssertEqual(firstPath.path.count, 1)
            XCTAssertEqual(firstPath.path[0].assetType, "credit_alphanum4")
            XCTAssertEqual(firstPath.path[0].assetCode, "BTC")

            let secondPath = response.records[1]
            XCTAssertEqual(secondPath.sourceAssetType, "native")
            XCTAssertNil(secondPath.sourceAssetCode)
            XCTAssertNil(secondPath.sourceAssetIssuer)
            XCTAssertEqual(secondPath.sourceAmount, "50.0000000")
            XCTAssertEqual(secondPath.destinationAssetType, "credit_alphanum12")
            XCTAssertEqual(secondPath.destinationAssetCode, "TESTTOKEN")
            XCTAssertEqual(secondPath.destinationAmount, "1000.0000000")
            XCTAssertEqual(secondPath.path.count, 0)
        } catch {
            XCTFail("Failed to decode: \(error)")
        }
    }

    func testFindPaymentPathsResponseInitializer() {
        let path1 = createMockPaymentPath(
            sourceAssetType: "native",
            sourceAmount: "100",
            destinationAssetType: "credit_alphanum4",
            destinationAmount: "10",
            destinationAssetCode: "USD",
            destinationAssetIssuer: "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
        )

        let path2 = createMockPaymentPath(
            sourceAssetType: "credit_alphanum4",
            sourceAmount: "200",
            sourceAssetCode: "EUR",
            sourceAssetIssuer: "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM",
            destinationAssetType: "native",
            destinationAmount: "50"
        )

        let response = FindPaymentPathsResponse(records: [path1, path2])

        XCTAssertEqual(response.records.count, 2)
        XCTAssertEqual(response.records[0].sourceAssetType, "native")
        XCTAssertEqual(response.records[0].sourceAmount, "100")
        XCTAssertEqual(response.records[1].sourceAssetType, "credit_alphanum4")
        XCTAssertEqual(response.records[1].sourceAssetCode, "EUR")
    }

    func testFindPaymentPathsResponseEmpty() {
        let response = FindPaymentPathsResponse(records: [])
        XCTAssertEqual(response.records.count, 0)
    }

    // MARK: - Extended Tests for PaymentPathResponse

    func testPaymentPathResponseWithAllFields() {
        let jsonString = """
        {
            "source_asset_type": "credit_alphanum4",
            "source_asset_code": "USD",
            "source_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "source_amount": "250.7500000",
            "destination_asset_type": "credit_alphanum12",
            "destination_asset_code": "GOLDTOKEN",
            "destination_asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM",
            "destination_amount": "125.3750000",
            "path": [
                {
                    "asset_type": "native"
                },
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "EUR",
                    "asset_issuer": "GAUTUYY2THLF7SGITDFMXJVYH3LHDSMGEAKSBU267M2K7A3W543CKUEF"
                }
            ]
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAssetType, "credit_alphanum4")
            XCTAssertEqual(response.sourceAssetCode, "USD")
            XCTAssertEqual(response.sourceAssetIssuer, "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX")
            XCTAssertEqual(response.sourceAmount, "250.7500000")
            XCTAssertEqual(response.destinationAssetType, "credit_alphanum12")
            XCTAssertEqual(response.destinationAssetCode, "GOLDTOKEN")
            XCTAssertEqual(response.destinationAssetIssuer, "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM")
            XCTAssertEqual(response.destinationAmount, "125.3750000")
            XCTAssertEqual(response.path.count, 2)

            // First intermediate asset is native
            XCTAssertEqual(response.path[0].assetType, "native")
            XCTAssertNil(response.path[0].assetCode)
            XCTAssertNil(response.path[0].assetIssuer)

            // Second intermediate asset is credit_alphanum4
            XCTAssertEqual(response.path[1].assetType, "credit_alphanum4")
            XCTAssertEqual(response.path[1].assetCode, "EUR")
            XCTAssertEqual(response.path[1].assetIssuer, "GAUTUYY2THLF7SGITDFMXJVYH3LHDSMGEAKSBU267M2K7A3W543CKUEF")
        } catch {
            XCTFail("Failed to decode PaymentPathResponse: \(error)")
        }
    }

    func testPaymentPathResponseWithNativeSourceAndDestination() {
        let jsonString = """
        {
            "source_asset_type": "native",
            "source_amount": "100.0000000",
            "destination_asset_type": "native",
            "destination_amount": "100.0000000",
            "path": []
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAssetType, "native")
            XCTAssertNil(response.sourceAssetCode)
            XCTAssertNil(response.sourceAssetIssuer)
            XCTAssertEqual(response.sourceAmount, "100.0000000")
            XCTAssertEqual(response.destinationAssetType, "native")
            XCTAssertNil(response.destinationAssetCode)
            XCTAssertNil(response.destinationAssetIssuer)
            XCTAssertEqual(response.destinationAmount, "100.0000000")
            XCTAssertEqual(response.path.count, 0)
        } catch {
            XCTFail("Failed to decode PaymentPathResponse with native assets: \(error)")
        }
    }

    func testPaymentPathResponseWithMaximumPathLength() {
        // Stellar allows maximum 5 intermediate assets in a path
        let jsonString = """
        {
            "source_asset_type": "native",
            "source_amount": "1000.0000000",
            "destination_asset_type": "credit_alphanum4",
            "destination_asset_code": "USD",
            "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "destination_amount": "500.0000000",
            "path": [
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "EUR",
                    "asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM"
                },
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "GBP",
                    "asset_issuer": "GAUTUYY2THLF7SGITDFMXJVYH3LHDSMGEAKSBU267M2K7A3W543CKUEF"
                },
                {
                    "asset_type": "credit_alphanum12",
                    "asset_code": "SILVERTOKEN",
                    "asset_issuer": "GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5"
                },
                {
                    "asset_type": "native"
                },
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "JPY",
                    "asset_issuer": "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
                }
            ]
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.path.count, 5)

            // Verify all intermediate assets
            XCTAssertEqual(response.path[0].assetCode, "EUR")
            XCTAssertEqual(response.path[1].assetCode, "GBP")
            XCTAssertEqual(response.path[2].assetCode, "SILVERTOKEN")
            XCTAssertEqual(response.path[2].assetType, "credit_alphanum12")
            XCTAssertEqual(response.path[3].assetType, "native")
            XCTAssertNil(response.path[3].assetCode)
            XCTAssertEqual(response.path[4].assetCode, "JPY")
        } catch {
            XCTFail("Failed to decode PaymentPathResponse with max path: \(error)")
        }
    }

    // MARK: - Extended Tests for FindPaymentPathsResponse

    func testFindPaymentPathsResponseWithMultiplePaths() {
        let jsonString = """
        {
            "_embedded": {
                "records": [
                    {
                        "source_asset_type": "native",
                        "source_amount": "100.0000000",
                        "destination_asset_type": "credit_alphanum4",
                        "destination_asset_code": "USD",
                        "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                        "destination_amount": "50.0000000",
                        "path": []
                    },
                    {
                        "source_asset_type": "native",
                        "source_amount": "105.0000000",
                        "destination_asset_type": "credit_alphanum4",
                        "destination_asset_code": "USD",
                        "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                        "destination_amount": "50.0000000",
                        "path": [
                            {
                                "asset_type": "credit_alphanum4",
                                "asset_code": "EUR",
                                "asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM"
                            }
                        ]
                    },
                    {
                        "source_asset_type": "native",
                        "source_amount": "110.0000000",
                        "destination_asset_type": "credit_alphanum4",
                        "destination_asset_code": "USD",
                        "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                        "destination_amount": "50.0000000",
                        "path": [
                            {
                                "asset_type": "credit_alphanum4",
                                "asset_code": "EUR",
                                "asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM"
                            },
                            {
                                "asset_type": "credit_alphanum4",
                                "asset_code": "GBP",
                                "asset_issuer": "GAUTUYY2THLF7SGITDFMXJVYH3LHDSMGEAKSBU267M2K7A3W543CKUEF"
                            }
                        ]
                    }
                ]
            }
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(FindPaymentPathsResponse.self, from: jsonData)

            XCTAssertEqual(response.records.count, 3)

            // First path is direct (no intermediates)
            XCTAssertEqual(response.records[0].sourceAmount, "100.0000000")
            XCTAssertEqual(response.records[0].path.count, 0)

            // Second path has 1 intermediate
            XCTAssertEqual(response.records[1].sourceAmount, "105.0000000")
            XCTAssertEqual(response.records[1].path.count, 1)
            XCTAssertEqual(response.records[1].path[0].assetCode, "EUR")

            // Third path has 2 intermediates
            XCTAssertEqual(response.records[2].sourceAmount, "110.0000000")
            XCTAssertEqual(response.records[2].path.count, 2)
            XCTAssertEqual(response.records[2].path[0].assetCode, "EUR")
            XCTAssertEqual(response.records[2].path[1].assetCode, "GBP")
        } catch {
            XCTFail("Failed to decode FindPaymentPathsResponse with multiple paths: \(error)")
        }
    }

    func testFindPaymentPathsResponseEmptyEmbedded() {
        let jsonString = """
        {
            "_embedded": {
                "records": []
            }
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(FindPaymentPathsResponse.self, from: jsonData)

            XCTAssertEqual(response.records.count, 0)
        } catch {
            XCTFail("Failed to decode empty FindPaymentPathsResponse: \(error)")
        }
    }

    // MARK: - Asset Type Validation Tests

    func testPaymentPathWithCreditAlphanum4Asset() {
        let jsonString = """
        {
            "source_asset_type": "credit_alphanum4",
            "source_asset_code": "USD",
            "source_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "source_amount": "100.0000000",
            "destination_asset_type": "credit_alphanum4",
            "destination_asset_code": "EUR",
            "destination_asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM",
            "destination_amount": "85.0000000",
            "path": []
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAssetType, "credit_alphanum4")
            XCTAssertEqual(response.sourceAssetCode, "USD")
            XCTAssertEqual(response.sourceAssetCode?.count, 3)
            XCTAssertTrue(response.sourceAssetCode!.count <= 4)

            XCTAssertEqual(response.destinationAssetType, "credit_alphanum4")
            XCTAssertEqual(response.destinationAssetCode, "EUR")
            XCTAssertEqual(response.destinationAssetCode?.count, 3)
            XCTAssertTrue(response.destinationAssetCode!.count <= 4)
        } catch {
            XCTFail("Failed to decode credit_alphanum4 path: \(error)")
        }
    }

    func testPaymentPathWithCreditAlphanum12Asset() {
        let jsonString = """
        {
            "source_asset_type": "credit_alphanum12",
            "source_asset_code": "SILVERTOKEN",
            "source_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "source_amount": "500.0000000",
            "destination_asset_type": "credit_alphanum12",
            "destination_asset_code": "GOLDTOKEN",
            "destination_asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM",
            "destination_amount": "250.0000000",
            "path": []
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAssetType, "credit_alphanum12")
            XCTAssertEqual(response.sourceAssetCode, "SILVERTOKEN")
            XCTAssertEqual(response.sourceAssetCode?.count, 11)
            XCTAssertTrue(response.sourceAssetCode!.count > 4 && response.sourceAssetCode!.count <= 12)

            XCTAssertEqual(response.destinationAssetType, "credit_alphanum12")
            XCTAssertEqual(response.destinationAssetCode, "GOLDTOKEN")
            XCTAssertEqual(response.destinationAssetCode?.count, 9)
            XCTAssertTrue(response.destinationAssetCode!.count > 4 && response.destinationAssetCode!.count <= 12)
        } catch {
            XCTFail("Failed to decode credit_alphanum12 path: \(error)")
        }
    }

    func testPaymentPathWithMixedAssetTypes() {
        let jsonString = """
        {
            "source_asset_type": "native",
            "source_amount": "1000.0000000",
            "destination_asset_type": "credit_alphanum12",
            "destination_asset_code": "LONGASSET123",
            "destination_asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM",
            "destination_amount": "100.0000000",
            "path": [
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "USD",
                    "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
                },
                {
                    "asset_type": "native"
                },
                {
                    "asset_type": "credit_alphanum12",
                    "asset_code": "INTERMEDIATE",
                    "asset_issuer": "GAUTUYY2THLF7SGITDFMXJVYH3LHDSMGEAKSBU267M2K7A3W543CKUEF"
                }
            ]
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAssetType, "native")
            XCTAssertEqual(response.destinationAssetType, "credit_alphanum12")
            XCTAssertEqual(response.path.count, 3)

            // Check mixed types in path
            XCTAssertEqual(response.path[0].assetType, "credit_alphanum4")
            XCTAssertEqual(response.path[1].assetType, "native")
            XCTAssertEqual(response.path[2].assetType, "credit_alphanum12")
        } catch {
            XCTFail("Failed to decode mixed asset type path: \(error)")
        }
    }

    // MARK: - Amount Parsing Tests

    func testPaymentPathWithVerySmallAmount() {
        let jsonString = """
        {
            "source_asset_type": "native",
            "source_amount": "0.0000001",
            "destination_asset_type": "credit_alphanum4",
            "destination_asset_code": "USD",
            "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "destination_amount": "0.0000001",
            "path": []
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAmount, "0.0000001")
            XCTAssertEqual(response.destinationAmount, "0.0000001")
        } catch {
            XCTFail("Failed to decode path with small amount: \(error)")
        }
    }

    func testPaymentPathWithLargeAmount() {
        let jsonString = """
        {
            "source_asset_type": "native",
            "source_amount": "922337203685.4775807",
            "destination_asset_type": "credit_alphanum4",
            "destination_asset_code": "USD",
            "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "destination_amount": "500000000000.0000000",
            "path": []
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)

            XCTAssertEqual(response.sourceAmount, "922337203685.4775807")
            XCTAssertEqual(response.destinationAmount, "500000000000.0000000")
        } catch {
            XCTFail("Failed to decode path with large amount: \(error)")
        }
    }

    // MARK: - OfferAssetResponse Tests

    func testOfferAssetResponseNative() {
        let jsonString = """
        {
            "asset_type": "native"
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(OfferAssetResponse.self, from: jsonData)

            XCTAssertEqual(response.assetType, "native")
            XCTAssertNil(response.assetCode)
            XCTAssertNil(response.assetIssuer)
        } catch {
            XCTFail("Failed to decode native OfferAssetResponse: \(error)")
        }
    }

    func testOfferAssetResponseCreditAlphanum4() {
        let jsonString = """
        {
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(OfferAssetResponse.self, from: jsonData)

            XCTAssertEqual(response.assetType, "credit_alphanum4")
            XCTAssertEqual(response.assetCode, "USD")
            XCTAssertEqual(response.assetIssuer, "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX")
        } catch {
            XCTFail("Failed to decode credit_alphanum4 OfferAssetResponse: \(error)")
        }
    }

    func testOfferAssetResponseCreditAlphanum12() {
        let jsonString = """
        {
            "asset_type": "credit_alphanum12",
            "asset_code": "LONGASSET123",
            "asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM"
        }
        """

        do {
            let jsonData = jsonString.data(using: .utf8)!
            let response = try JSONDecoder().decode(OfferAssetResponse.self, from: jsonData)

            XCTAssertEqual(response.assetType, "credit_alphanum12")
            XCTAssertEqual(response.assetCode, "LONGASSET123")
            XCTAssertEqual(response.assetIssuer, "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6EVEQZVMCQWM")
        } catch {
            XCTFail("Failed to decode credit_alphanum12 OfferAssetResponse: \(error)")
        }
    }

    // MARK: - Error Handling Tests

    func testPaymentPathResponseMissingRequiredField() {
        // Missing source_amount (required)
        let jsonString = """
        {
            "source_asset_type": "native",
            "destination_asset_type": "credit_alphanum4",
            "destination_asset_code": "USD",
            "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "destination_amount": "100.0000000",
            "path": []
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testPaymentPathResponseMissingPath() {
        // Missing path (required)
        let jsonString = """
        {
            "source_asset_type": "native",
            "source_amount": "100.0000000",
            "destination_asset_type": "credit_alphanum4",
            "destination_asset_code": "USD",
            "destination_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "destination_amount": "50.0000000"
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testFindPaymentPathsResponseMissingEmbedded() {
        // Missing _embedded
        let jsonString = """
        {
            "records": []
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(FindPaymentPathsResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testFindPaymentPathsResponseMalformedJSON() {
        let jsonString = """
        {
            "_embedded": {
                "records": "not_an_array"
            }
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(FindPaymentPathsResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Helper Methods

    private func createMockPaymentPath(
        sourceAssetType: String,
        sourceAmount: String,
        sourceAssetCode: String? = nil,
        sourceAssetIssuer: String? = nil,
        destinationAssetType: String,
        destinationAmount: String,
        destinationAssetCode: String? = nil,
        destinationAssetIssuer: String? = nil,
        path: [OfferAssetResponse] = []
    ) -> PaymentPathResponse {
        var jsonDict: [String: Any] = [
            "source_asset_type": sourceAssetType,
            "source_amount": sourceAmount,
            "destination_asset_type": destinationAssetType,
            "destination_amount": destinationAmount,
            "path": path.map { assetDict -> [String: Any] in
                var dict: [String: Any] = ["asset_type": assetDict.assetType]
                if let code = assetDict.assetCode {
                    dict["asset_code"] = code
                }
                if let issuer = assetDict.assetIssuer {
                    dict["asset_issuer"] = issuer
                }
                return dict
            }
        ]

        if let code = sourceAssetCode {
            jsonDict["source_asset_code"] = code
        }
        if let issuer = sourceAssetIssuer {
            jsonDict["source_asset_issuer"] = issuer
        }
        if let code = destinationAssetCode {
            jsonDict["destination_asset_code"] = code
        }
        if let issuer = destinationAssetIssuer {
            jsonDict["destination_asset_issuer"] = issuer
        }

        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict)
        return try! JSONDecoder().decode(PaymentPathResponse.self, from: jsonData)
    }
}
