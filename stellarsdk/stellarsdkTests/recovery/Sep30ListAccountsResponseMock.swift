//
//  Sep30ListAccountsResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class Sep30ListAccountsResponseMock: ResponsesMock {
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
                           path: "/accounts",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let success = """
    {
      "accounts": [
        {
          "address": "GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD",
          "identities": [
            { "role": "owner", "authenticated": true }
          ],
          "signers": [
            { "key": "GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY" }
          ]
        },
        {
          "address": "GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ",
          "identities": [
            { "role": "sender", "authenticated": true },
            { "role": "receiver" },
          ],
          "signers": [
            { "key": "GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN" }
          ]
        },
        {
          "address": "GD62WD2XTOCAENMB34FB2SEW6JHPB7AFYQAJ5OCQ3TYRW5MOJXLKGTMM",
          "identities": [
            { "role": "sender" },
            { "role": "receiver", "authenticated": true },
          ],
          "signers": [
            { "key": "GDFPM46I2L2DXB3TWAKPMLUMEW226WXLRWJNS4QHXXKJXEUW3M6OAFBY" }
          ]
        }
      ]
    }
    """
    
}
