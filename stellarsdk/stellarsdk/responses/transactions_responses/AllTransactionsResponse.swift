//
//  AllTransactionsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an all transactions response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/transactions-all.html "All Transactions")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/transaction.html "Transaction")
public class AllTransactionsResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:AllTransactionsLinksResponse
    
    /// Transactions found in the response.
    public var transactions:[TransactionResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The assets are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedTransactionsResponseService
    struct EmbeddedTransactionsResponseService: Decodable {
        let records: [TransactionResponse]
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(AllTransactionsLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedTransactionsResponseService.self, forKey: .embeddedRecords)
        self.transactions = self.embeddedRecords.records
    }
}

