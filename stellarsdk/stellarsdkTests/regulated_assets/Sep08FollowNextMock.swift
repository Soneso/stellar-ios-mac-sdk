//
//  Sep08FollowNextMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep08FollowNextMock: ResponsesMock {
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
                mock.statusCode = 200
                return """
                    {
                      "result" : "follow_next_url",
                      "message": "Please submit mobile number",
                      "next_url": "http://goat.io/action",
                    }
                    """
            }
            mock.statusCode = 400
            return ""
            
        }
        
        return RequestMock(host: host,
                           path: "/action/next",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
