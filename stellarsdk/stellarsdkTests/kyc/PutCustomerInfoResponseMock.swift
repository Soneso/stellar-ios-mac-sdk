//
//  PutCustomerInfoServerMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class PutCustomerInfoResponseMock: ResponsesMock {
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
                           path: "/customer",
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
      "error":  "'photo_id_front' cannot be decoded. Must be jpg or png."
    }
    """
    
    
    let putSuccess = """
    {
        "id": "391fb415-c223-4608-b2f5-dd1e91e3a986"
    }
    """
}
