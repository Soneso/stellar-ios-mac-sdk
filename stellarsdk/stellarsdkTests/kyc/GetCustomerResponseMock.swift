//
//  File.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 31.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class GetCustomerResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            
            let jwt = request.allHTTPHeaderFields?["Authorization"];
            if jwt == "Bearer accepted_jwt" {
                mock.statusCode = 202
                return self?.accepted
            } else if jwt == "Bearer some_info_jwt" {
                mock.statusCode = 200
                return self?.someInfo
            } else if jwt == "Bearer 404_jwt" {
                mock.statusCode = 404
                return self?.notFoundError
            } else if jwt == "Bearer 400_jwt" {
                mock.statusCode = 400
                return self?.otherError
            } else {
                mock.statusCode = 401 // unauthorized
            }
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/customer",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    // The case when a customer has been successfully KYC'd and approved
    let accepted = """
    {
       "id": "d1ce2f48-3ff1-495d-9240-7a50d806cfed",
       "status": "ACCEPTED",
       "provided_fields": {
          "first_name": {
             "description": "The customer's first name",
             "type": "string",
             "status": "ACCEPTED"
          },
          "last_name": {
             "description": "The customer's last name",
             "type": "string",
             "status": "ACCEPTED"
          },
          "email_address": {
             "description": "The customer's email address",
             "type": "string",
             "status": "ACCEPTED"
          }
       }
    }
    """
    
    // The case when a customer has provided some but not all required information
    let someInfo = """
    {
       "id": "d1ce2f48-3ff1-495d-9240-7a50d806cfed",
       "status": "NEEDS_INFO",
       "fields": {
          "mobile_number": {
             "description": "phone number of the customer",
             "type": "string"
          },
          "email_address": {
             "description": "email address of the customer",
             "type": "string",
             "optional": true
          }
       },
       "provided_fields": {
          "first_name": {
             "description": "The customer's first name",
             "type": "string",
             "status": "ACCEPTED"
          },
          "last_name": {
             "description": "The customer's last name",
             "type": "string",
             "status": "ACCEPTED"
          }
       }
    }
    """
    
    // The case when an anchor requires info about an unknown customer
    let unknownCustomer = """
    {
       "id": "d1ce2f48-3ff1-495d-9240-7a50d806cfed",
       "status": "NEEDS_INFO",
       "fields": {
          "mobile_number": {
             "description": "phone number of the customer",
             "type": "string"
          },
          "email_address": {
             "description": "email address of the customer",
             "type": "string",
             "optional": true
          }
       },
       "provided_fields": {
          "first_name": {
             "description": "The customer's first name",
             "type": "string",
             "status": "ACCEPTED"
          },
          "last_name": {
             "description": "The customer's last name",
             "type": "string",
             "status": "ACCEPTED"
          }
       }
    }
    """
    
    let notFoundError = """
    {
      "error": "customer not found for id: 7e285e7d-d984-412c-97bc-909d0e399fbf"
    }
    """
    
    let otherError = """
    {
      "error": "unrecognized 'type' value. see valid values in the /info response"
    }
    """
    
}
