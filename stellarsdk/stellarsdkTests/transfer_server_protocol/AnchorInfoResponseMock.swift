//
//  AnchorInfoResponseMock.swift
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
          "authentication_required": true,
          "min_amount": 0.1,
          "max_amount": 1000,
          "fields": {
            "email_address" : {
              "description": "your email address for transaction status updates",
              "optional": true
            },
            "amount" : {
              "description": "amount in USD that you plan to deposit"
            },
            "country_code": {
              "description": "The ISO 3166-1 alpha-3 code of the user's current address",
              "choices": ["USA", "PRI"]
            },
            "type" : {
              "description": "type of deposit to make",
              "choices": ["SEPA", "SWIFT", "cash"]
            }
          }
        },
        "ETH": {
          "enabled": true,
          "authentication_required": false,
        }
      },
      "deposit-exchange": {
        "USD": {
          "authentication_required": true,
          "fields": {
            "email_address" : {
              "description": "your email address for transaction status updates",
              "optional": true
            },
            "amount" : {
              "description": "amount in USD that you plan to deposit"
            },
            "country_code": {
              "description": "The ISO 3166-1 alpha-3 code of the user's current address",
              "choices": ["USA", "PRI"]
            },
            "type" : {
              "description": "type of deposit to make",
              "choices": ["SEPA", "SWIFT", "cash"]
            }
          }
        }
      },
      "withdraw": {
        "USD": {
          "enabled": true,
          "authentication_required": true,
          "min_amount": 0.1,
          "max_amount": 1000,
          "types": {
            "bank_account": {
              "fields": {
                  "dest": {"description": "your bank account number" },
                  "dest_extra": { "description": "your routing number" },
                  "bank_branch": { "description": "address of your bank branch" },
                  "phone_number": { "description": "your phone number in case there's an issue" },
                  "country_code": {
                    "description": "The ISO 3166-1 alpha-3 code of the user's current address",
                    "choices": ["USA", "PRI"]
                  }
              }
            },
            "cash": {
              "fields": {
                "dest": {
                  "description": "your email address. Your cashout PIN will be sent here. If not provided, your account's default email will be used",
                  "optional": true
                }
              }
            }
          }
        },
        "ETH": {
          "enabled": false
        }
      },
      "withdraw-exchange": {
        "USD": {
          "authentication_required": true,
          "min_amount": 0.1,
          "max_amount": 1000,
          "types": {
            "bank_account": {
              "fields": {
                  "dest": {"description": "your bank account number" },
                  "dest_extra": { "description": "your routing number" },
                  "bank_branch": { "description": "address of your bank branch" },
                  "phone_number": { "description": "your phone number in case there's an issue" },
                  "country_code": {
                    "description": "The ISO 3166-1 alpha-3 code of the user's current address",
                    "choices": ["USA", "PRI"]
                  }
              }
            },
            "cash": {
              "fields": {
                "dest": {
                  "description": "your email address. Your cashout PIN will be sent here. If not provided, your account's default email will be used",
                  "optional": true
                }
              }
            }
          }
        }
      },
      "fee": {
        "enabled": false,
        "description": "Fees vary from 3 to 7 percent based on the the assets transacted and method by which funds are delivered to or collected by the anchor."
      },
      "transactions": {
        "enabled": true,
        "authentication_required": true
      },
      "transaction": {
        "enabled": false,
        "authentication_required": true
      },
      "features": {
        "account_creation": true,
        "claimable_balances": true
      }
    }
    """
    
}
