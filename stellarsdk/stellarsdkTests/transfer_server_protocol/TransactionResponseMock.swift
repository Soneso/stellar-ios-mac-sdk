//
//  TransactionResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class TransactionResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            if let key = mock.variables["id"] {
                if key == "82fhs729f63dh0v4" {
                    mock.statusCode = 200
                    return self?.txSuccess
                }
            }
            mock.statusCode = 400
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/transaction",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let txSuccess = """
    {
      "transaction": {
        "id": "82fhs729f63dh0v4",
        "kind": "deposit",
        "status": "pending_external",
        "status_eta": 3600,
        "external_transaction_id": "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093",
        "amount_in": "18.34",
        "amount_out": "18.24",
        "amount_fee": "0.1",
        "started_at": "2017-03-20T17:05:32Z"
      }
    }
    """
}
