//
//  AccountResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 06.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import stellarsdk


class AccountResponsesMock : ResponsesMock {
    var accounts = [String: String]()
    
    func addAccount(key: String, accountResponse: String) {
        accounts[key] = accountResponse
    }
    
    
    override func requestMock() -> RequestMock {
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
}
