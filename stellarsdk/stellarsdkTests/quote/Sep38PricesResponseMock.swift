//
//  Sep38PricesResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38PricesResponseMock: ResponsesMock {
    var host: String
    
    init(host:String) {
        self.host = host
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }
        
        return RequestMock(host: host,
                           path: "/prices",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let success = """
    {
      "buy_assets": [
        {
          "asset": "iso4217:BRL",
          "price": "0.18",
          "decimals": 2
        }
      ]
    }
    """
}
