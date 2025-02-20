//
//  GetCustomerInfoResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct GetCustomerInfoResponse: Decodable {
    
    /// (optional) ID of the customer, if the customer has already been created via a PUT /customer request.
    public var id:String?
    
    /// Status of the customers KYC process.
    public var status:String
    
    /// (optional) An object containing the fields the anchor has not yet received for the given customer of the type provided in the request. Required for customers in the NEEDS_INFO status.
    public var fields:[String:GetCustomerInfoField]?
    
    /// (optional) An object containing the fields the anchor has received for the given customer. Required for customers whose information needs verification.
    public var providedFields:[String:GetCustomerInfoProvidedField]?
    
    /// (optional) Human readable message describing the current state of customer's KYC process.
    public var message:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case fields
        case providedFields = "provided_fields"
        case message
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        status = try values.decode(String.self, forKey: .status)
        fields = try values.decodeIfPresent([String:GetCustomerInfoField].self, forKey: .fields)
        providedFields = try values.decodeIfPresent([String:GetCustomerInfoProvidedField].self, forKey: .providedFields)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
    
}

public struct GetCustomerInfoField: Decodable {
    
    /// The data type of the field value. Can be "string", "binary", "number", or "date"
    public var type:String
    
    /// A human-readable description of this field, especially important if this is not a SEP-9 field.
    public var description:String
    
    /// (optional) An array of valid values for this field.
    public var choices:[Any]?
    
    /// (optional) A boolean whether this field is required to proceed or not. Defaults to false.
    public var optional:Bool?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case description
        case choices
        case optional
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        description = try values.decode(String.self, forKey: .description)
        choices = try values.decodeIfPresent([Any].self, forKey: .choices)
        optional = try values.decodeIfPresent(Bool.self, forKey: .optional)
    }
    
}

public struct GetCustomerInfoProvidedField: Decodable {
    
    /// The data type of the field value. Can be "string", "binary", "number", or "date"
    public var type:String
    
    /// A human-readable description of this field, especially important if this is not a SEP-9 field.
    public var description:String
    
    /// (optional) An array of valid values for this field.
    public var choices:[Any]?
    
    /// (optional) A boolean whether this field is required to proceed or not. Defaults to false.
    public var optional:Bool?
    
    /// (optional) One of the values described in Provided Field Statuses (https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#provided-field-statuses). If the server does not wish to expose which field(s) were accepted or rejected, this property can be omitted.
    public var status:String?
    
    /// (optional) The human readable description of why the field is REJECTED.
    public var error:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case description
        case choices
        case optional
        case status
        case error
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        description = try values.decode(String.self, forKey: .description)
        choices = try values.decodeIfPresent([Any].self, forKey: .choices)
        optional = try values.decodeIfPresent(Bool.self, forKey: .optional)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        error = try values.decodeIfPresent(String.self, forKey: .error)
    }
    
}
