//
//  FindPaymentPathsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 18.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/path-finding.html "Find Payment Paths")
public struct FindPaymentPathsResponse: Decodable {
    
    /// records found in the response.
    public var records:[PaymentPathResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case embeddedRecords = "_embedded"
    }
    
    // The offers are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedResponseService
    struct EmbeddedResponseService: Decodable {
        let records: [PaymentPathResponse]
        
        init(records:[PaymentPathResponse]) {
            self.records = records
        }
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.embeddedRecords = try values.decode(EmbeddedResponseService.self, forKey: .embeddedRecords)
        self.records = self.embeddedRecords.records
    }
    
    /**
     Initializer - creates a new instance with parameters
     
     - Parameter operations: The payment operations received from the Horizon API
     - Parameter links: The links received from the Horizon API
     */
    public init(records: [PaymentPathResponse]) {
        self.records = records
        self.embeddedRecords = EmbeddedResponseService(records: records)
    }
}
