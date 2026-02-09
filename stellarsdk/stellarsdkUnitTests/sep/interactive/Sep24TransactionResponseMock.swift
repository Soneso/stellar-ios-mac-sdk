//
//  Sep24TransactionResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24TransactionResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let key = mock.variables["id"], key == "1234" {
                mock.statusCode = 404
                return "Transaction not found"
            }
            mock.statusCode = 200
            return self!.success
        }
        
        return RequestMock(host: address,
                           path: "/transaction",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let success = """
    { 
        "transaction":
        {
          "id": "82fhs729f63dh0v4",
          "kind": "withdrawal",
          "status": "completed",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2025-01-14T14:22:06.391779Z",
          "completed_at": "2025-01-14T14:22:08.491Z",
          "updated_at": "2025-01-14T14:22:07Z",
          "more_info_url": "https://youranchor.com/tx/242523523",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1941491",
          "withdraw_anchor_account": "GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL",
          "withdraw_memo": "186384",
          "withdraw_memo_type": "id",
          "refunds": {
            "amount_refunded": "10",
            "amount_fee": "5",
            "payments": [
              {
                "id": "b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020",
                "id_type": "stellar",
                "amount": "10",
                "fee": "5"
              }
            ]
          }
        }
    }
    """
}
