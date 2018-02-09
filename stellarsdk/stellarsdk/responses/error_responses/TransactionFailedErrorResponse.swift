//
//  TransactionFailedErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a transaction failed error response (code 400) from the horizon api, containing information related to the error
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/errors/transaction-failed.html "Transaction Failed")
public class TransactionFailedErrorResponse: ErrorResponse {
    
    /// A base64-encoded representation of the TransactionEnvelope XDR whose failure triggered this response.
    public var envelopeXDR:String
    
    /// A base64-encoded representation of the TransactionResult XDR returned by stellar-core when submitting this transactions.
    public var resultXDR:String
    
    /// The transaction result code returned by stellar-core.
    public var transactionResultCode:String
    
    /// An array of strings, representing the operation result codes for each operation in the submitted transaction, if available.
    public var operationsResultCodes:[String]
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case extras
    }
    
    private var extras:ExtrasResponseService
    struct ExtrasResponseService: Decodable {
        public var envelopeXDR:String
        public var resultXDR:String
        public var resultCodes:ResultCodesResponseService
        
        struct ResultCodesResponseService: Decodable {
            public var transaction:String
            public var operations:[String]
        }
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        extras = try values.decode(ExtrasResponseService.self, forKey: .extras)
        self.envelopeXDR = extras.envelopeXDR
        self.resultXDR = extras.resultXDR
        self.transactionResultCode = extras.resultCodes.transaction
        self.operationsResultCodes = extras.resultCodes.operations
        
        try super.init(from: decoder)
    }
}
