//
//  PutVerificationResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 31.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class PutVerificationResponseMock: ResponsesMock {
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
                mock.statusCode = 202
                return self?.putSuccess
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
                           path: "/customer/verification",
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
      "error": "The provided confirmation code was invalid."
    }
    """
    
    
    let putSuccess = """
    {
       "id": "d1ce2f48-3ff1-495d-9240-7a50d806cfed",
       "status": "ACCEPTED",
       "provided_fields": {
          "mobile_number": {
             "description": "phone number of the customer",
             "type": "string",
             "status": "ACCEPTED"
          }
       }
    }
    """
}
