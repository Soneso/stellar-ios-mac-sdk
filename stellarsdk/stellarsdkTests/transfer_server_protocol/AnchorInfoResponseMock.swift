//
//  AnchorInfoServerMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class AnchorInfoResponseMock: ResponsesMock {
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
          "fields": {
            "email_address" : {
              "description": "your email address for transaction status updates",
              "optional": true
            },
            "amount" : {
              "description": "amount in USD that you plan to deposit",
            }
          }
        },
        "ETH": {
          "enabled": true,
          "fee_fixed": 0.002,
          "fee_percent": 0
        }
      },
      "withdraw": {
        "USD": {
          "enabled": true,
          "fee_fixed": 5,
          "fee_percent": 0,
          "types": {
            "bank_account": {
              "fields": {
                  "dest": {"description": "your bank account number" },
                  "dest_extra": { "description": "your routing number" },
                  "bank_branch": { "description": "address of your bank branch" },
                  "phone_number": { "description": "your phone number in case there's an issue" }
              }
            },
            "cash": {
              "fields": {
                "dest": { "description": "your email address. Your cashout PIN will be sent here." }
              }
            }
          }
        },
        "ETH": {
          "enabled": false
        }
      },
      "transactions": {
        "enabled": true
      }
    }
    """
    
}
