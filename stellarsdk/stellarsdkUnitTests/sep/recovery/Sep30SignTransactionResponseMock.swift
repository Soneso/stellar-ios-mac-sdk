//
//  Sep30SignTransactionResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class Sep30SignTransactionResponseMock: ResponsesMock {
    var host: String
    var address: String
    var signingAddress: String
    
    init(host:String, address:String, signingAddress:String) {
        self.host = host
        self.address = address
        self.signingAddress = signingAddress
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // Body received - no debug output
            }
            mock.statusCode = 200
            return self?.signSuccess
        }
        
        return RequestMock(host: host,
                           path: "/accounts/\(address)/sign/\(signingAddress)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
    
    let signSuccess = """
    { 
    "signature": "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS",
    "network_passphrase": "Test SDF Network ; September 2015"
    }
    """
    
}
