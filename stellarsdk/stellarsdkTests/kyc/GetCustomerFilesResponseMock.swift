//
//  GetCustomerFilesResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class GetCustomerFilesResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            let jwt = request.allHTTPHeaderFields?["Authorization"];
            if jwt == "Bearer 200_files_jwt" {
                mock.statusCode = 200
                return self?.files
            } else if jwt == "Bearer 200_empty_jwt" {
                mock.statusCode = 200
                return self?.empty
            } else {
                mock.statusCode = 401 // unauthorized
            }
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/customer/files",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    let files = """
    {
      "files": [
        {
          "file_id": "file_d5c67b4c-173c-428c-baab-944f4b89a57f",
          "content_type": "image/png",
          "size": 6134063,
          "customer_id": "2bf95490-db23-442d-a1bd-c6fd5efb584e"
        },
        {
          "file_id": "file_d3d54529-6683-4341-9b66-4ac7d7504238",
          "content_type": "image/jpeg",
          "size": 4089371,
          "customer_id": "2bf95490-db23-442d-a1bd-c6fd5efb584e"
        }
      ]
    }
    """
    
    let empty = """
    {
      "files": []
    }
    """
}
