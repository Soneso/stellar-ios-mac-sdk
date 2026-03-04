//
//  OperationXDRRemoteTestCase.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 02/02/2026.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationXDRRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()

    func testGetTransactionXdr() async {
        let responseEnum = await sdk.transactions.getTransactions(limit:1)
        switch responseEnum {
        case .success(let transactionsResponse):
            if let response = transactionsResponse.records.first {
                switch response.transactionResult.result {
                case .success(let operations):
                    self.validateOperation(operationXDR: operations.first!)
                default:
                    XCTFail()
                }
            }
        case .failure(_):
            XCTFail()
        }
    }

    func validateOperation(operationXDR: OperationResultXDR) {
        // Verify the discriminant round-trips correctly
        XCTAssertEqual(operationXDR.type(), OperationResultCode.inner.rawValue)

        guard case .tr(let tr) = operationXDR else {
            XCTFail("Expected .tr (inner) result, got error code: \(operationXDR.type())")
            return
        }

        // Verify the inner result encodes and decodes without error
        let encoded = try? XDREncoder.encode(operationXDR)
        XCTAssertNotNil(encoded, "Failed to encode OperationResultXDR for operation type: \(tr.type())")

        if let encoded = encoded {
            let decoded = try? XDRDecoder.decode(OperationResultXDR.self, data: encoded)
            XCTAssertNotNil(decoded, "Failed to decode OperationResultXDR for operation type: \(tr.type())")
        }
    }
}
