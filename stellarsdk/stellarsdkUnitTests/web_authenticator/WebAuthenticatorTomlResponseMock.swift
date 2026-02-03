//
//  WebAuthenticatorTomlResponseMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 16/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class WebAuthenticatorTomlResponseMock: ResponsesMock {
    var address: String
    var serverSigningKey: String
    var authServer: String
    
    init(address:String, serverSigningKey: String, authServer: String) {
        self.address = address
        self.serverSigningKey = serverSigningKey
        self.authServer = authServer
        
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
    
    var stellarToml:String {
        get {
            return """
                # Sample stellar.toml
            
                WEB_AUTH_ENDPOINT="\(authServer)"
                SIGNING_KEY="\(serverSigningKey)"
            """
        }
    }
}
