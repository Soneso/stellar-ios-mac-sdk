//
//  Sep08ActionDoneMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep08ActionDoneMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    
    init(host:String) {
        self.host = host
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // let body = String(decoding: data, as: UTF8.self)
                // print(body)
                mock.statusCode = 200
                return """
                    {
                      "result" : "no_further_action_required"
                    }
                    """
            }
            mock.statusCode = 400
            return ""
            
        }
        
        return RequestMock(host: host,
                           path: "/action/done",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
