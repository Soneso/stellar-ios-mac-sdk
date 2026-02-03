//
//  Sep38PriceResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38PriceResponseMock: ResponsesMock {
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
                           path: "/price",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let success = """
    {
      "total_price": "0.20",
      "price": "0.18",
      "sell_amount": "100",
      "buy_amount": "500",
      "fee": {
        "total": "10.00",
        "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
        "details": [
          {
            "name": "Service fee",
            "amount": "5.00"
          },
          {
            "name": "PIX fee",
            "description": "Fee charged in order to process the outgoing BRL PIX transaction.",
            "amount": "5.00"
          }
        ]
      }
    }
    """
}
