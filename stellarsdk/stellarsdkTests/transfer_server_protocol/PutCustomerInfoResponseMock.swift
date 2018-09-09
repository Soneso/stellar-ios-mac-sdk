//
//  PutCustomerInfoServerMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class PutCustomerInfoResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if request.allHTTPHeaderFields?["Content-Length"] == "293" {
                mock.statusCode = 202
            } else {
                mock.statusCode = 434
                return self?.error
            }
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/customer",
                           httpMethod: "PUT",
                           mockHandler: handler)
    }
    
    let error = """
    {
      "error": "This anchor doesn't support the given currency code: ETH"
    }
    """
    
}
