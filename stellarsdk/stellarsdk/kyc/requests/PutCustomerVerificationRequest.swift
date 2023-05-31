//
//  PutCustomerVerificationRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct PutCustomerVerificationRequest {

    /// The ID of the customer as returned in the response of a previous PUT request.
    public var id:String
    
    /// The JWT previously sent by the anchor via the /jwt endpoint via SEP-10 authentication
    public var jwt:String
    
    /// One or more SEP-9 fields appended with _verification. See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification
    public var fields:[String:String]
    
    public init(id:String, fields:[String:String], jwt:String) {
        self.id = id
        self.fields = fields
        self.jwt = jwt
    }
    
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        parameters["id"] = id.data(using: .utf8)
        for field in fields {
            parameters[field.key] = field.value.data(using: .utf8)
        }
        return parameters
    }
    
}
