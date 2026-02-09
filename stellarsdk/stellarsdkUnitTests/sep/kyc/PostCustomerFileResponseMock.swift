//
//  PostCustomerFileResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class PostCustomerFileResponseMock: ResponsesMock {
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
                return self?.postSuccess
            } else if jwt == "Bearer 400_jwt" {
                mock.statusCode = 400
                return self?.badDataError
            } else if jwt == "Bearer 413_empty_jwt" {
                mock.statusCode = 413
            } else if jwt == "Bearer 413_jwt" {
                mock.statusCode = 413
                return self?.payloadTooLargeError
            } else {
                mock.statusCode = 401 // unauthorized
            }
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/customer/files",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
    
    let badDataError = """
    {
      "error":  "'photo_id_front' cannot be decoded. Must be jpg or png."
    }
    """
    
    let payloadTooLargeError = """
    {
      "error":  "Max. size allowed: 3MB"
    }
    """
    
    
    let postSuccess = """
    {
      "file_id": "file_d3d54529-6683-4341-9b66-4ac7d7504238",
      "content_type": "image/jpeg",
      "size": 4089371,
      "customer_id": "2bf95490-db23-442d-a1bd-c6fd5efb584e"
    }
    """
}
