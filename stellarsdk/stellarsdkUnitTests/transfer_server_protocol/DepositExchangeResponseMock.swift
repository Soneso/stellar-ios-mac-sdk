//
//  DepositExchangeResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//


import Foundation

class DepositExchangeResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            if let key = mock.variables["account"] {
                if key == "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI" {
                    mock.statusCode = 200
                    return self?.depositBankSuccess
                }
            }
            mock.statusCode = 400
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/deposit-exchange",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let depositBankSuccess = """
    {
      "id": "9421871e-0623-4356-b7b5-5996da122f3e",
      "instructions": {
        "organization.bank_number": {
          "value": "121122676",
          "description": "US bank routing number"
        },
        "organization.bank_account_number": {
          "value": "13719713158835300",
          "description": "US bank account number"
        }
      },
      "how": "Make a payment to Bank: 121122676 Account: 13719713158835300"
    }
    """
}
