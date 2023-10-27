//
//  Sep30DeleteAccountResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class Sep30DeleteAccountResponseMock: ResponsesMock {
    var host: String
    var address: String
    
    init(host:String, address:String) {
        self.host = host
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }
        
        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "DELETE",
                           mockHandler: handler)
    }
    
    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "sender" },
        { "role": "receiver" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
    
}
