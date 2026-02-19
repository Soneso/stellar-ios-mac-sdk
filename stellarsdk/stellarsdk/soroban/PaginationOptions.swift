//
//  PaginationOptions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Pagination settings for Soroban RPC queries that return large result sets.
///
/// Use PaginationOptions to control the number of results returned and to
/// navigate through multiple pages of results.
///
/// Parameters:
/// - cursor: Continuation token from a previous response (for fetching next page)
/// - limit: Maximum number of results to return per request
///
/// Example:
/// ```swift
/// // Fetch first page with limit
/// let firstPageOptions = PaginationOptions(limit: 100)
/// let response1 = await server.getEvents(
///     startLedger: 1000000,
///     paginationOptions: firstPageOptions
/// )
///
/// // Fetch next page using cursor from first response
/// if let cursor = response1.cursor {
///     let nextPageOptions = PaginationOptions(
///         cursor: cursor,
///         limit: 100
///     )
///     let response2 = await server.getEvents(
///         startLedger: 1000000,
///         paginationOptions: nextPageOptions
///     )
/// }
/// ```
///
/// See also:
/// - [SorobanServer.getEvents] for event queries
/// - [SorobanServer.getTransactions] for transaction queries
/// - [SorobanServer.getLedgers] for ledger queries
public final class PaginationOptions: Sendable {

    /// Pagination cursor from previous response for retrieving the next page of results.
    public let cursor:String?
    /// Maximum number of records to return per page.
    public let limit: Int?
    
    /// Creates pagination options for limiting and offsetting query results.
    public init(cursor:String? = nil, limit: Int? = nil) {
        self.cursor = cursor
        self.limit = limit
    }
    
    /// Converts pagination options into request parameters for the Soroban RPC API.
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        if cursor != nil {
            result["cursor"] = cursor!
        }
        if limit != nil {
            result["limit"] = limit!
        }
        return result;
    }
}
