//
//  ErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an error response from the horizon api, containing information related to the error that occured.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/errors.html "Errors")
public class ErrorResponse: NSObject, Decodable {
    
    /// The identifier for the error. This is a URL that can be visited in the browser.
    public var type:String
    
    /// A short title describing the error.
    public var title:String
    
    /// An HTTP status code that maps to the error.
    public var httpStatusCode:UInt
    
    /// A more detailed description of the error.
    public var detail:String
    
    /// A token that uniquely identifies this request. Allows server administrators to correlate a client report with server log files.
    public var instance:String?
    
    public var extras:ErrorResponseExtras?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case title
        case httpStatusCode = "status"
        case detail
        case instance
        case extras
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        title = try values.decode(String.self, forKey: .title)
        httpStatusCode = try values.decode(UInt.self, forKey: .httpStatusCode)
        detail = try values.decode(String.self, forKey: .detail)
        instance = try values.decodeIfPresent(String.self, forKey: .instance)
        extras = try values.decodeIfPresent(ErrorResponseExtras.self, forKey: .extras)
    }
}

public class ErrorResponseExtras: Decodable {
    public var envelopeXdr: String?
    public var resultXdr: String?
    public var resultCodes: ErrorResultCodes?
    public var txHash: String?

    private enum CodingKeys: String, CodingKey {
        case envelopeXdr = "envelope_xdr"
        case resultXdr = "result_xdr"
        case resultCodes = "result_codes"
        case txHash = "hash"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        envelopeXdr = try values.decodeIfPresent(String.self, forKey: .envelopeXdr)
        resultXdr = try values.decodeIfPresent(String.self, forKey: .resultXdr)
        resultCodes = try values.decodeIfPresent(ErrorResultCodes.self, forKey: .resultCodes)
        txHash = try values.decodeIfPresent(String.self, forKey: .txHash)
    }
}

public class ErrorResultCodes: Decodable {
    public var transaction: String?
    public var operations: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case transaction
        case operations
    }
    
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transaction = try values.decodeIfPresent(String.self, forKey: .transaction)
        operations = try values.decodeIfPresent([String].self, forKey: .operations)
    }
}

///  Represents a timeout error response (code 504) from the horizon api, containing information related to the error
///  See [Horizon API](https://developers.stellar.org/docs/data/horizon/api-reference/errors/http-status-codes/horizon-specific/timeout "Stale History")
public class TimeoutErrorResponse: ErrorResponse {}
