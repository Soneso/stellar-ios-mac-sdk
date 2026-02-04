//
//  SingleLedgerResponseMock.swift
//  stellarsdkTests
//
//  Created by AI Assistant on 04.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class SingleLedgerResponseMock : ResponsesMock {
    var ledgerResponses = [String: String]()

    func addLedgerResponse(sequence: String, response: String) {
        ledgerResponses[sequence] = response
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let sequence = mock.variables["sequence"],
                  let response = self?.ledgerResponses[sequence] else {
                mock.statusCode = 404
                return self?.resourceMissingResponse()
            }

            return response
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/ledgers/${sequence}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
