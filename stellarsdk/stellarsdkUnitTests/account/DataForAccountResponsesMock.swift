//
//  DataForAccountResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import stellarsdk


class DataForAccountResponsesMock : ResponsesMock {
    var keyValue = [String: String]()
    var dataEntries = [String : [String: String]]()
    
    func addDataEntry(accountId: String, key: String, value: String) {
        keyValue[key] = value
        dataEntries[accountId] = keyValue
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let account = mock.variables["account"],
                let key = mock.variables["key"],
                let dataResponse = self?.dataEntries[account]?[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return dataResponse
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/accounts/${account}/data/${key}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

