//
//  TransactionsResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 21.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class TransactionsResponsesMock : ResponsesMock {
    var transactionsResponses = [String: String]()
    
    func addTransactionsResponse(key: String, response: String) {
        transactionsResponses[key] = response
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let transactionsResponse = self?.transactionsResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return transactionsResponse
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/transactions?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
