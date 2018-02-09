//
//  TransactionMalformedErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a transaction malformed error response (code 400) from the horizon api, containing information related to the error
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/errors/transaction-malformed.html "Transaction Malformed")
public class TransactionMalformedErrorResponse: ErrorResponse {
    
    /// The submitted data that was malformed in some way.
    public var envelopeXDR:String

    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case extras
    }
    
    private var extras:ExtrasResponseService
    struct ExtrasResponseService: Decodable {
        public var envelopeXDR:String
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        extras = try values.decode(ExtrasResponseService.self, forKey: .extras)
        self.envelopeXDR = extras.envelopeXDR
        
        try super.init(from: decoder)
    }
}
