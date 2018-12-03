//
//  PostCallbackMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 03/12/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class PostCallbackMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return nil
        }
        
        return RequestMock(host: address,
                           path: "",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
