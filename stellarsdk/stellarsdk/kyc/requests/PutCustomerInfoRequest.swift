//
//  PutCustomerInfoRequest.swift
//  stellarsdk
//
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct PutCustomerInfoRequest {

    /// (optional) The id value returned from a previous call to this endpoint. If specified, no other parameter is required.
    public var id:String?
    
    /// (deprecated, optional) The server should infer the account from the sub value in the SEP-10 JWT to identify the customer. The account parameter is only used for backwards compatibility, and if explicitly provided in the request body it should match the sub value of the decoded SEP-10 JWT.
    public var account:String?
    
    /// The JWT previously sent by the anchor via the /jwt endpoint via SEP-10 authentication
    public var jwt:String
    
    /// (optional) the client-generated memo that uniquely identifies the customer. If a memo is present in the decoded SEP-10 JWT's sub value, it must match this parameter value. If a muxed account is used as the JWT's sub value, memos sent in requests must match the 64-bit integer subaccount ID of the muxed account.
    public var memo:String?
    
    /// (deprecated, optional) type of memo. One of text, id or hash. Deprecated because memos should always be of type id, although anchors should continue to support this parameter for outdated clients. If hash, memo should be base64-encoded. If a memo is present in the decoded SEP-10 JWT's sub value, this parameter can be ignored.
    public var memoType:String?
    
    /// (optional) The type of the customer as defined in the Type Specification: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#type-specification
    public var type:String?
    
    /// (optional) The transaction id with which the customer's info is associated. When information
    /// from the customer depends on the transaction (e.g., more information is required for larger amounts)
    public var transactionId:String?
    
    /// one or more of the fields listed in SEP-9
    public var fields:[KYCNaturalPersonFieldsEnum]?
    
    /// one or more of the organization fields listed in SEP-9
    public var organizationFields:[KYCOrganizationFieldsEnum]?
    
    /// one or more of the financial account fields listed in SEP-9
    public var financialAccountFields:[KYCFinancialAccountFieldsEnum]?
    
    /// one or more of the card fields listed in SEP-9
    public var cardFields:[KYCCardFieldsEnum]?
    
    /// extra fields to send
    public var extraFields:[String:String]?
    
    /// extra files to send
    public var extraFiles:[String:Data]?
    
    public init(jwt:String) {
        self.jwt = jwt
    }
    
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        if let id = id {
            parameters["id"] = id.data(using: .utf8)
        }
        if let account = account {
            parameters["account"] = account.data(using: .utf8)
        }
        if let memo = memo {
            parameters["memo"] = memo.data(using: .utf8)
        }
        if let memoType = memoType {
            parameters["memo_type"] = memoType.data(using: .utf8)
        }
        if let type = type {
            parameters["type"] = type.data(using: .utf8)
        }
        if let transactionId = transactionId {
            parameters["transaction_id"] = transactionId.data(using: .utf8)
        }
        
        var collectedFiles:[String:Data] = [:]
        
        if let fields = fields {
            for field in fields {
                switch field {
                case .photoIdFront(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .photoIdBack(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .notaryApprovalOfPhotoId(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .ipAddress(let string):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .photoProofResidence(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .proofOfIncome(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .proofOfLiveness(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .referralId(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                default:
                    parameters[field.parameter.0] = field.parameter.1
                }
            }
        }
        if let fields = organizationFields {
            for field in fields {
                switch field {
                case .photoIncorporationDoc(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .photoProofAddress(let data):
                    collectedFiles[field.parameter.0] = field.parameter.1
                default:
                    parameters[field.parameter.0] = field.parameter.1
                }
            }
        }
        
        if let fields = financialAccountFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        if let fields = cardFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        if let fields = extraFields {
            for (key, value) in fields {
                parameters[key] = value.data(using: .utf8)
            }
        }
        
        // put files at the end
        for (key, value) in collectedFiles {
            parameters[key] = value
        }
        
        if let files = extraFiles {
            for (key, value) in files {
                parameters[key] = value
            }
        }
    
        return parameters
    }
    
}
