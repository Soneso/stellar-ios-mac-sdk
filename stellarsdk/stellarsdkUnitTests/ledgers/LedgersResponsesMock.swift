//
//  LedgersResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 20.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class LedgersResponsesMock : ResponsesMock {
    var ledgersResponses = [String: String]()
    
    func addLedgersResponse(key: String, response: String) {
        ledgersResponses[key] = response
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let assetsResponse = self?.ledgersResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return assetsResponse
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/ledgers?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
