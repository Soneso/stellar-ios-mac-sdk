//
//  TransactionFactory.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class TransactionsFactory: NSObject {
    let jsonDecoder = JSONDecoder()
    
    override init() {
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    func transactionsFromResponseData(data: Data) throws -> TransactionsResponse {
        var transactionsList = [Transaction]()
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            
            for record in json["_embedded"]!["records"] as! [[String:AnyObject]] {
                let jsonRecord = try JSONSerialization.data(withJSONObject: record, options: .prettyPrinted)
                let transaction = try transactionFromData(data: jsonRecord)
                transactionsList.append(transaction)
            }
            
        } catch {
            throw TransactionsError.parsingFailed(response: error.localizedDescription)
        }
        
        return TransactionsResponse(transactions: transactionsList)
    }
    
    func transactionFromData(data: Data) throws -> Transaction {
        return try jsonDecoder.decode(Transaction.self, from: data)
    }
}
