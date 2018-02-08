//
//  AllTransactionsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class AllTransactionsResponse: NSObject {
    public var transactions:[TransactionResponse]
    
    public init(transactions: [TransactionResponse]) {
        self.transactions = transactions
    }
}
