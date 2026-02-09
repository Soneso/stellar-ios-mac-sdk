//
//  Sep24FeeResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24FeeResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            if let key = mock.variables["asset_code"] {
                if key == "ETH" {
                    mock.statusCode = 400
                    return self!.feeError
                } else if key == "XYZ" {
                    mock.statusCode = 403
                    return self!.authRequired
                } else if key == "ABC" {
                    mock.statusCode = 400
                    return self!.anchorError
                }
            }
            mock.statusCode = 200
            return self!.feeSuccess
        }
        
        return RequestMock(host: address,
                           path: "/fee",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let feeSuccess = """
    {
      "fee": 0.013
    }
    """
    
    let feeError = """
    {
      "error": "This anchor doesn't support the given currency code: ETH"
    }
    """
    
    let authRequired = """
    {
      "type": "authentication_required"
    }
    """
    
    let anchorError = """
    {
      "error": "This anchor doesn't support the given currency code: ABC"
    }
    """
}
