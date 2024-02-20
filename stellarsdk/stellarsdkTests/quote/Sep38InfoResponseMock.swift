//
//  Sep38InfoResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38InfoResponseMock: ResponsesMock {
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
                           path: "/info",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let success = """
    {
      "assets":  [
        {
          "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        },
        {
          "asset": "stellar:BRL:GDVKY2GU2DRXWTBEYJJWSFXIGBZV6AZNBVVSUHEPZI54LIS6BA7DVVSP"
        },
        {
          "asset": "iso4217:BRL",
          "country_codes": ["BRA"],
          "sell_delivery_methods": [
            {
              "name": "cash",
              "description": "Deposit cash BRL at one of our agent locations."
            },
            {
              "name": "ACH",
              "description": "Send BRL directly to the Anchor's bank account."
            },
            {
              "name": "PIX",
              "description": "Send BRL directly to the Anchor's bank account."
            }
          ],
          "buy_delivery_methods": [
            {
              "name": "cash",
              "description": "Pick up cash BRL at one of our payout locations."
            },
            {
              "name": "ACH",
              "description": "Have BRL sent directly to your bank account."
            },
            {
              "name": "PIX",
              "description": "Have BRL sent directly to the account of your choice."
            }
          ]
        }
      ]
    }
    """
    
}
