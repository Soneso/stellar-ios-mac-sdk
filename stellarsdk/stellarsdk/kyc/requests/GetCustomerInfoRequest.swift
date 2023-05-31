//
//  GetCustomerInfoRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct GetCustomerInfoRequest {

    /// (optional) The ID of the customer as returned in the response of a previous PUT request. If the customer has not been registered, they do not yet have an id.
    public var id:String?
    
    /// (deprecated, optional) The server should infer the account from the sub value in the SEP-10 JWT to identify the customer. The account parameter is only used for backwards compatibility, and if explicitly provided in the request body it should match the sub value of the decoded SEP-10 JWT.
    public var account:String?
    
    /// (optional) the client-generated memo that uniquely identifies the customer. If a memo is present in the decoded SEP-10 JWT's sub value, it must match this parameter value. If a muxed account is used as the JWT's sub value, memos sent in requests must match the 64-bit integer subaccount ID of the muxed account.
    public var memo:String?
    
    /// (deprecated, optional) type of memo. One of text, id or hash. Deprecated because memos should always be of type id, although anchors should continue to support this parameter for outdated clients. If hash, memo should be base64-encoded. If a memo is present in the decoded SEP-10 JWT's sub value, this parameter can be ignored.
    public var memoType:String?
    
    /// (optional) the type of action the customer is being KYCd for. See the Type Specification: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#type-specification
    public var type:String?
    
    /// (optional) Defaults to en. Language code specified using ISO 639-1. Human readable descriptions, choices, and messages should be in this language.
    public var lang:String?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String
    
    public init(jwt:String) {
        self.jwt = jwt
    }
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
        case account
        case memoType = "memo_type"
        case memo
        case type
        case lang
    }
}
