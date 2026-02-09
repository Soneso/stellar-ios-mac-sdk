//
//  Sep24TransactionsResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24TransactionsResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let key = mock.variables["asset_code"] {
                if "USD" == key {
                    return self!.empty
                }
            }
            return self!.success
        }
        
        return RequestMock(host: address,
                           path: "/transactions",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    

    let success = """
    {
      "transactions": [
        {
          "id": "82fhs729f63dh0v4",
          "kind": "deposit",
          "status": "pending_external",
          "status_eta": 3600,
          "external_transaction_id": "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093",
          "more_info_url": "https://youranchor.com/tx/242523523",
          "amount_in": "18.34",
          "amount_out": "18.24",
          "amount_fee": "0.1",
          "started_at": "2017-03-20T17:05:32Z",
          "claimable_balance_id": null,
          "user_action_required_by": "2024-03-20T17:05:32Z"
        },
        {
          "id": "82fhs729f63dh0v4",
          "kind": "withdrawal",
          "status": "completed",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2017-03-20T17:00:02Z",
          "completed_at": "2017-03-20T17:09:58Z",
          "updated_at": "2017-03-20T17:09:58Z",
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
        },
        {
          "id": "92fhs729f63dh0v3",
          "kind": "deposit",
          "status": "completed",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2017-03-20T17:00:02Z",
          "completed_at": "2017-03-20T17:09:58Z",
          "updated_at": "2017-03-20T17:09:58Z",
          "more_info_url": "https://youranchor.com/tx/242523526",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1947101",
          "refunds": {
            "amount_refunded": "10",
            "amount_fee": "5",
            "payments": [
              {
                "id": "1937103",
                "id_type": "external",
                "amount": "10",
                "fee": "5"
              }
            ]
          }
        },
        {
          "id": "92fhs729f63dh0v3",
          "kind": "deposit",
          "status": "pending_anchor",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2017-03-20T17:00:02Z",
          "updated_at": "2017-03-20T17:05:58Z",
          "more_info_url": "https://youranchor.com/tx/242523526",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1947101",
          "refunds": {
            "amount_refunded": "10",
            "amount_fee": "5",
            "payments": [
              {
                "id": "1937103",
                "id_type": "external",
                "amount": "10",
                "fee": "5"
              }
            ]
          }
        }
      ]
    }
    """
    
    let empty = """
    {
      "transactions": []
    }
    """
}
