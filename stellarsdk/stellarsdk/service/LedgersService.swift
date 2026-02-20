//
//  LedgersService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for ledger details requests.
public enum LedgerDetailsResponseEnum: Sendable {
    /// Success case containing ledger details.
    case success(details: LedgerResponse)
    /// Failure case containing error information.
    case failure(error: HorizonRequestError)
}

/// Defines ledger stream filter options for real-time ledger updates.
public enum LedgersChange: Sendable {
    /// Streams all ledgers as they close on the network
    case allLedgers(cursor:String?)
}

/// Service for querying ledger information from the Stellar Horizon API.
///
/// Ledgers represent the state of the Stellar network at a specific point in time. Each ledger
/// contains all transactions and operations that occurred, along with metadata like fees,
/// transaction count, and protocol version.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get details for a specific ledger
/// let response = await sdk.ledgers.getLedgerDetails(sequence: "12345")
/// switch response {
/// case .success(let ledger):
///     print("Transaction count: \(ledger.transactionCount)")
///     print("Closed at: \(ledger.closedAt)")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
public class LedgersService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Retrieves detailed information about a specific ledger by sequence number.
    /// - Parameter sequenceNumber: The ledger sequence number as a string
    /// - Returns: LedgerDetailsResponseEnum with ledger details or error
    open func getLedger(sequenceNumber:String) async -> LedgerDetailsResponseEnum {
        let requestPath = "/ledgers/" + sequenceNumber
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let ledger = try self.jsonDecoder.decode(LedgerResponse.self, from: data)
                return .success(details: ledger)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    /// Retrieves all ledgers with pagination support.
    /// - Parameters:
    ///   - cursor: Pagination cursor for next page
    ///   - order: Sort order (.ascending or .descending)
    ///   - limit: Maximum number of records to return (default 10, max 200)
    /// - Returns: PageResponse containing ledgers or error
    open func getLedgers(cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<LedgerResponse>.ResponseEnum {
        var requestPath = "/ledgers"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getLedgersFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Loads ledgers from a specific URL for pagination.
    /// - Parameter url: The complete URL to fetch ledgers from (typically from PageResponse links)
    /// - Returns: PageResponse containing ledgers or error
    open func getLedgersFromUrl(url:String) async -> PageResponse<LedgerResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let ledgers = try self.jsonDecoder.decode(PageResponse<LedgerResponse>.self, from: data)
                return .success(page: ledgers)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// Streams real-time ledger updates via Server-Sent Events from Horizon.
    ///
    /// - Parameter transactionsType: The filter specifying which ledgers to stream (currently only allLedgers)
    /// - Returns: LedgersStreamItem for receiving streaming ledger updates
    open func stream(for transactionsType:LedgersChange) -> LedgersStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allLedgers(let cursor):
            subpath = "/ledgers"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = LedgersStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
    
}
