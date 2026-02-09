//
//  Sep24InfoResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24InfoResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            return self?.infoSuccess
        }
        
        return RequestMock(host: address,
                           path: "/info",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let infoSuccess = """
    {
      "deposit": {
        "USD": {
          "enabled": true,
          "fee_fixed": 5,
          "fee_percent": 1,
          "min_amount": 0.1,
          "max_amount": 1000
        },
        "ETH": {
          "enabled": true,
          "fee_fixed": 0.002,
          "fee_percent": 0
        },
        "native": {
          "enabled": true,
          "fee_fixed": 0.00001,
          "fee_percent": 0
        }
      },
      "withdraw": {
        "USD": {
          "enabled": true,
          "fee_minimum": 5,
          "fee_percent": 0.5,
          "min_amount": 0.1,
          "max_amount": 1000
        },
        "ETH": {
          "enabled": false
        },
        "native": {
          "enabled": true
        }
      },
      "fee": {
        "enabled": false
      },
      "features": {
        "account_creation": true,
        "claimable_balances": true
      }
    }
    """
    
}
