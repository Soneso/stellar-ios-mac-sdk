//
//  TradesResponsesMock.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/22/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class TradesResponsesMock : ResponsesMock {
    var tradesResponses = [String: String]()
    
    func addTradesResponse(key: String, response: String) {
        tradesResponses[key] = response
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let response = self?.tradesResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return response
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/trades?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
