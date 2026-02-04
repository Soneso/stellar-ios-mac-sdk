//
//  TradesForAccountResponseMock.swift
//  stellarsdkTests
//
//  Created by AI Assistant on 04.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class TradesForAccountResponseMock : ResponsesMock {
    var tradesResponses = [String: String]()

    func addTradesResponse(key: String, response: String) {
        tradesResponses[key] = response
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let accountId = mock.variables["account_id"],
                  let response = self?.tradesResponses[accountId] else {
                mock.statusCode = 404
                return self?.resourceMissingResponse()
            }

            return response
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/accounts/${account_id}/trades",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
