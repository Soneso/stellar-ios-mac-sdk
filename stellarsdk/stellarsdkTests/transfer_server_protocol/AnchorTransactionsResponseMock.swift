//
//  AnchorTransactionsServerMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class AnchorTransactionsResponseMock: ResponsesMock {
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
                           path: "/transactions",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let infoSuccess = """
    {
      "transactions": [
        {
          "id": "82fhs729f63dh0v4",
          "kind": "deposit",
          "status": "pending_external",
          "status_eta": 3600,
          "external_transaction_id": "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093",
          "amount_in": "18.34",
          "amount_out": "18.24",
          "amount_fee": "0.1",
          "started_at": "2017-03-20T17:05:32Z"
        },
        {
          "id": "82fhs729f63dh0v4",
          "kind": "withdrawal",
          "status": "completed",
          "amount_in": "500",
          "amount_out": "495",
          "amount_fee": "3",
          "started_at": "2017-03-20T17:00:02Z",
          "completed_at": "2017-03-20T17:09:58Z",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093"
        }
      ]
    }
    """
}
