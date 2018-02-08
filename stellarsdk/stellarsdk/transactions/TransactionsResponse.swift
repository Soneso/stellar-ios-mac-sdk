//
//  TransactionsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class TransactionsResponse: NSObject {
    public var transactions:[Transaction]
    
    public init(transactions: [Transaction]) {
        self.transactions = transactions
    }
}
