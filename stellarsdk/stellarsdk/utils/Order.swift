//
//  Order.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Sort order for Horizon API list requests.
///
/// Used when querying collections of resources (transactions, operations, etc.) to specify
/// whether results should be returned in chronological or reverse chronological order.
///
/// Example:
/// ```swift
/// // Get most recent transactions first
/// sdk.transactions.getTransactions(order: .descending) { response in
///     // ...
/// }
/// ```
public enum Order: String, Sendable {
    /// Ascending order (oldest to newest, chronological).
    case ascending = "asc"

    /// Descending order (newest to oldest, reverse chronological).
    case descending = "desc"
}
