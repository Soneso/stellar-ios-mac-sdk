//
//  PutCallbackUrlResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 31.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class PutCallbackUrlResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                let body = String(decoding: data, as: UTF8.self)
                print(body)
            }
            let jwt = request.allHTTPHeaderFields?["Authorization"];
            if jwt == "Bearer 200_jwt" {
                mock.statusCode = 200
            } else if jwt == "Bearer 404_jwt" {
                mock.statusCode = 404
                return self?.notFoundError
            } else if jwt == "Bearer 400_jwt" {
                mock.statusCode = 400
                return self?.badDataError
            } else {
                mock.statusCode = 401 // unauthorized
            }
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/customer/callback",
                           httpMethod: "PUT",
                           mockHandler: handler)
    }
    
    let notFoundError = """
    {
      "error":  "customer with `id` not found"
    }
    """
    
    let badDataError = """
    {
      "error":  "invalid url"
    }
    """
    
}
