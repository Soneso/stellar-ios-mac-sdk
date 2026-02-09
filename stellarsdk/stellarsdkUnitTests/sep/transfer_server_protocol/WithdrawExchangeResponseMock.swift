//
//  WithdrawExchangeResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class WithdrawExchangeResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            if let key = mock.variables["destination_asset"] {
                if key == "iso4217:USD" {
                    mock.statusCode = 200
                    return self?.withdrawSuccess
                }
            }
            mock.statusCode = 400
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/withdraw-exchange",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let withdrawSuccess = """
    {
      "account_id": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ",
      "memo_type": "id",
      "memo": "123",
      "id": "9421871e-0623-4356-b7b5-5996da122f3e"
    }
    """
}
