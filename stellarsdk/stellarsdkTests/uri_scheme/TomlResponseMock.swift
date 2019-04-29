//
//  TomlResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 12/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class TomlResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {

        let handler: MockHandler = { [weak self] mock, request in
            return self?.stellarToml
        }
        
        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let stellarToml = """
            # Sample stellar.toml
            
            FEDERATION_SERVER="https://api.domain.com/federation"
            AUTH_SERVER="https://api.domain.com/auth"
            TRANSFER_SERVER="https://api.domain.com"
            URI_REQUEST_SIGNING_KEY="GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"
            """
}
