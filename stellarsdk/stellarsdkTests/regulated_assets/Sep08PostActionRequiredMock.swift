//
//  Sep08PostActionRequiredMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep08PostActionRequiredMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    
    init(host:String) {
        self.host = host
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                let body = String(decoding: data, as: UTF8.self)
                //print(body)
                try! self!.jsonDecoder.decode(Sep08PostTestRequest.self, from: data)
                mock.statusCode = 200
                return """
                    {
                      "status" : "action_required",
                      "message": "hello",
                      "action_url": "http://goat.io/action",
                      "action_method": "POST",
                      "action_fields": ["email_address", "mobile_number"]
                    }
                    """
            }
            mock.statusCode = 400
            return ""
            
        }
        
        return RequestMock(host: host,
                           path: "/tx_approve/action_required",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
