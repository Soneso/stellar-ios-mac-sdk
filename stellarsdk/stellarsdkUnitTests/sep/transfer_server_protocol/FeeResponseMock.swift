//
//  FeeResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class FeeResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            if let key = mock.variables["asset_code"] {
                if key == "ETH" {
                    mock.statusCode = 200
                    return self?.feeSuccess
                }
            }
            mock.statusCode = 400
            return nil
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
}
