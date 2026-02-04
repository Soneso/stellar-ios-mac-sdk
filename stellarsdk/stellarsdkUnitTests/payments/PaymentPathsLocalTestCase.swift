//
//  PaymentPathsLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Claude on 04/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PaymentPathsLocalTestCase: XCTestCase {

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
