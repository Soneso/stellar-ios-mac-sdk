//
//  OperationsResponsesMock.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/21/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class OperationsResponsesMock : ResponsesMock {
    var operationsResponses = [String: String]()
    
    func addOperationsResponse(key: String, response: String) {
        operationsResponses[key] = response
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let response = self?.operationsResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return response
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/operations?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
