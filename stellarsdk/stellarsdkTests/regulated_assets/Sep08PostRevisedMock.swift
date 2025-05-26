//
//  Sep08PostRevisedMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep08PostRevisedMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    
    init(host:String) {
        self.host = host
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                // let body = String(decoding: data, as: UTF8.self)
                // print(body)
                let request = try! self!.jsonDecoder.decode(Sep08PostTestRequest.self, from: data)
                mock.statusCode = 200
                return """
                    {
                      "status" : "revised",
                      "tx": "\(request.tx + request.tx)",
                      "message": "hello",
                    }
                    """
            }
            mock.statusCode = 400
            return ""
            
        }
        
        return RequestMock(host: host,
                           path: "/tx_approve/revised",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
