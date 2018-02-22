//
//  PaymentsResponsesMock.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/22/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class PaymentsResponsesMock : ResponsesMock {
    var paymentsResponses = [String: String]()
    
    func addPaymentsResponse(ledgerId: String, limit:String, response: String) {
        paymentsResponses[ledgerId+limit] = response
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let id = mock.variables["ledgerId"],
                let limit = mock.variables["limit"],
                let response = self?.paymentsResponses[id+limit] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return response
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/ledgers/${ledgerId}/payments?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
