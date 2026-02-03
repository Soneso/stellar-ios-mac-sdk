//
//  Sep38PostQuoteResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38PostQuoteResponseMock: ResponsesMock {
    var host: String
    
    init(host:String) {
        self.host = host
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                let body = String(decoding: data, as: UTF8.self)
                print(body)
            }
            mock.statusCode = 200
            return self?.success
        }
        
        return RequestMock(host: host,
                           path: "/quote",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
    
    let success = """
    {
      "id": "de762cda-a193-4961-861e-57b31fed6eb3",
      "expires_at": "2021-04-30T07:42:23",
      "total_price": "5.42",
      "price": "5.00",
      "sell_asset": "iso4217:BRL",
      "sell_amount": "542",
      "buy_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
      "buy_amount": "100",
      "fee": {
        "total": "42.00",
        "asset": "iso4217:BRL",
        "details": [
          {
            "name": "PIX fee",
            "description": "Fee charged in order to process the outgoing PIX transaction.",
            "amount": "12.00"
          },
          {
            "name": "Brazilian conciliation fee",
            "description": "Fee charged in order to process conciliation costs with intermediary banks.",
            "amount": "15.00"
          },
          {
            "name": "Service fee",
            "amount": "15.00"
          }
        ]
      }
    }
    """
    
}
