//
//  TransactionsError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum TransactionsError: Error {
    case transactionNotFound(response: String)
    case parsingFailed(response: String)
    case requestFailed(response: String)
}
