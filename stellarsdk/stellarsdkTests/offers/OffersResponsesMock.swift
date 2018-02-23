//
//  OffersResponsesMock.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/22/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class OffersResponsesMock : ResponsesMock {
    var offersResponses = [String: String]()
    
    func addOffersResponse(accountId: String, limit:String, response: String) {
        offersResponses[accountId+limit] = response
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let id = mock.variables["accountId"],
                let limit = mock.variables["limit"],
                let response = self?.offersResponses[id + limit] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return response
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/accounts/${accountId}/offers?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

