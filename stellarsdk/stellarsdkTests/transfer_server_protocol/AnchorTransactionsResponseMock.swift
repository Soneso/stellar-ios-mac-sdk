//
//  AnchorTransactionsResponseMock.swift
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
            return self?.transactionsSuccess
        }
        
        return RequestMock(host: address,
                           path: "/transactions",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let transactionsSuccess = """
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
          "id": "52fys79f63dh3v2",
          "kind": "deposit-exchange",
          "status": "pending_anchor",
          "status_eta": 3600,
          "external_transaction_id": "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093",
          "amount_in": "500",
          "amount_in_asset": "iso4217:BRL",
          "amount_out": "100",
          "amount_out_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
          "amount_fee": "0.1",
          "amount_fee_asset": "iso4217:BRL",
          "started_at": "2021-06-11T17:05:32Z"
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
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1238234",
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
          "id": "72fhs729f63dh0v1",
          "kind": "deposit",
          "status": "completed",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2017-03-20T17:00:02Z",
          "completed_at": "2017-03-20T17:09:58Z",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1238234",
          "from": "AJ3845SAD",
          "to": "GBITQ4YAFKD2372TNAMNHQ4JV5VS3BYKRK4QQR6FOLAR7XAHC3RVGVVJ",
          "refunds": {
            "amount_refunded": "10",
            "amount_fee": "5",
            "payments": [
              {
                "id": "104201",
                "id_type": "external",
                "amount": "10",
                "fee": "5"
              }
            ]
          }
        },
        {
          "id": "52fys79f63dh3v1",
          "kind": "withdrawal",
          "status": "pending_transaction_info_update",
          "amount_in": "750.00",
          "amount_out": null,
          "amount_fee": null,
          "started_at": "2017-03-20T17:00:02Z",
          "required_info_message": "We were unable to send funds to the provided bank account. Bank error: 'Account does not exist'. Please provide the correct bank account address.",
          "required_info_updates": {
            "transaction": {
              "dest": {"description": "your bank account number" },
              "dest_extra": { "description": "your routing number" }
            }
          }
        },
        {
          "id": "52fys79f63dh3v2",
          "kind": "withdrawal-exchange",
          "status": "pending_anchor",
          "status_eta": 3600,
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "amount_in": "100",
          "amount_in_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
          "amount_out": "500",
          "amount_out_asset": "iso4217:BRL",
          "amount_fee": "0.1",
          "amount_fee_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
          "started_at": "2021-06-11T17:05:32Z"
        },
      ]
    }
    """
}
