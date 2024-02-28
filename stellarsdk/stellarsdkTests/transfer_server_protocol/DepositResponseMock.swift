//
//  DepositResponseMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class DepositResponseMock: ResponsesMock {
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
                } else if key == "GDZHO73UEHTRLF5H3OUJHT42YXT6GQXRWDLYI7MAM3CGSRFTPT4GEIGD" {
                    mock.statusCode = 200
                    return self?.depositBTCSuccess
                } else if key == "GCA42DZONGM4U7F5NZRBWBO2LGQDJQP4FJIQ4C2T2XMMMGJI5JF6XZL4" {
                    mock.statusCode = 200
                    return self?.depositRippleSuccess
                } else if key == "GAILDWJHIV5CV4DDEK4ST4YWHOTNDGXC2XOVDFR36JFTYBRIXLLJKLS5" {
                    mock.statusCode = 200
                    return self?.depositMXNSuccess
                } else if key == "GBTMF7Y4S7S3ZMYLIU5MLVEECJETO7FYIZ5OH3GBDD7W3Z4A6556RTMC" {
                    mock.statusCode = 400
                    return nil
                } else if key == "GCIKZJNCDA6W335ODLBIINABY53DJXJTW4PPW6CXK623ZTA6LSYZI7SL" {
                    mock.statusCode = 403
                    return self?.informationNeededNonInteractive
                } else if key == "GAT3G3YYJJA6PIJJCP33N6RBJODYHMHVA556SBAOZYV5HTGLTFBI2VI3" {
                    mock.statusCode = 403
                    return self?.informationStatus
                } else if key == "GBYLNNAUUJQ7YJSGIATU432IJP2QYTTPKIY5AFWT7LFZAIT76QYVLTAG" {
                    mock.statusCode = 423
                    return self?.error
                }
            }
            
            mock.statusCode = 400
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/deposit",
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
    
    let depositBTCSuccess = """
    {
      "id": "9421871e-0623-4356-b7b5-5996da122f3e",
      "instructions": {
        "organization.crypto_address": {
          "value": "1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB",
          "description": "Bitcoin address"
        }
      },
      "how": "Make a payment to Bitcoin address 1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB",
      "fee_fixed": 0.0002
    }
    """
    
    let depositRippleSuccess = """
    {
      "id": "9421871e-0623-4356-b7b5-5996da122f3e",
      "instructions": {
        "organization.crypto_address": {
          "value": "rNXEkKCxvfLcM1h4HJkaj2FtmYuAWrHGbf",
          "description": "Ripple address"
        },
        "organization.crypto_memo": {
          "value": "88",
          "description": "Ripple tag"
        }
      },
      "how": "Make a payment to Ripple address rNXEkKCxvfLcM1h4HJkaj2FtmYuAWrHGbf with tag 88",
      "eta": 60,
      "fee_percent": 0.1,
      "extra_info": {
        "message": "You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete."
      }
    }
    """
    
    let depositMXNSuccess = """
    {
      "id": "9421871e-0623-4356-b7b5-5996da122f3e",
      "instructions": {
        "organization.clabe_number": {
          "value": "646180111803859359",
          "description": "CLABE number"
        }
      },
      "how": "Make a payment to Bank: STP Account: 646180111803859359",
      "eta": 1800
    }
    """
    
    let depositSuccess = """
    {
        "how" : "1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB",
        "id": "9421871e-0623-4356-b7b5-5996da122f3e",
        "eta": 60,
        "fee_fixed" : 0.0002,
        "fee_percent" : 0.1,
          "extra_info": {
            "message": "You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete."
          }
    }
    """
    
    let informationNeededNonInteractive = """
    {
        "type": "non_interactive_customer_info_needed",
        "fields" : ["family_name", "given_name", "address", "tax_id"]
    }
    """
    
    let informationStatus = """
    {
      "type": "customer_info_status",
      "status": "denied",
      "more_info_url": "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
    }
    """
        
    let error = """
    {
      "error": "This anchor doesn't support the given currency code: ETH"
    }
    """
    
}
