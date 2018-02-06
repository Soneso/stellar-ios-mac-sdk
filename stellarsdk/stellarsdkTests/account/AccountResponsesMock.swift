//
//  AccountResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 06.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import stellarsdk


class AccountResponsesMock {
    var accounts = [String: String]()
    
    func addAccount(key: String, accountResponse: String) {
        accounts[key] = accountResponse
    }
    
    init() {
        ServerMock.add(mock: accountMock())
    }
    
    deinit {
        ServerMock.removeAll()
    }
    
    func accountMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["account"],
                let accountResponse = self?.accounts[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return accountResponse
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/accounts/${account}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
   
    private func resourceMissingResponse() -> String {
        return """
        {
            "type": "https://stellar.org/horizon-errors/not_found",
            "title": "Resource Missing",
            "status": 404,
            "detail": "The resource at the url requested was not found.  This is usually occurs for one of two reasons:  The url requested is not valid, or no data in our databas could be found with the parameters provided.",
            "instance": "horizon-testnet-001/6VNfUsVQkZ-28076890"
        }
        """
    }
}
