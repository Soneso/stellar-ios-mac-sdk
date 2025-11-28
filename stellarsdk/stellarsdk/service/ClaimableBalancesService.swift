//
//  ClaimableBalancesService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Result enum for claimable balance details requests.
public enum ClaimableBalanceDetailsResponseEnum {
    /// Success case containing claimable balance details.
    case success(details: ClaimableBalanceResponse)
    /// Failure case containing error information.
    case failure(error: HorizonRequestError)
}

/// Service for querying claimable balances from the Stellar Horizon API.
///
/// Claimable balances allow creating asset transfers that recipients can claim later when
/// specific conditions are met. Useful for implementing payment channels, escrow, and
/// conditional transfers.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get claimable balance details
/// let response = await sdk.claimableBalances.getClaimableBalanceDetails(
///     claimableBalanceId: "00000000..."
/// )
/// switch response {
/// case .success(let balance):
///     print("Amount: \(balance.amount)")
///     print("Asset: \(balance.asset)")
///     for claimant in balance.claimants {
///         print("Claimant: \(claimant.destination)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - CreateClaimableBalanceOperation for creating claimable balances
public class ClaimableBalancesService: @unchecked Sendable {
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
    
    /// Retrieves detailed information about a specific claimable balance.
    /// - Parameter balanceId: The claimable balance ID (hex or B-encoded format)
    /// - Returns: ClaimableBalanceDetailsResponseEnum with balance details or error
    open func getClaimableBalance(balanceId:String) async -> ClaimableBalanceDetailsResponseEnum {
        var idHex = balanceId
        if balanceId.hasPrefix("B"),
            let cid = try? balanceId.decodeClaimableBalanceIdToHex() {
            idHex = cid
        }
        let requestPath = "/claimable_balances/" + idHex
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let value = try self.jsonDecoder.decode(ClaimableBalanceResponse.self, from: data)
                return .success(details: value)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    /// Retrieves claimable balances filtered by asset with pagination support.
    /// - Parameters:
    ///   - asset: The asset to filter claimable balances by
    ///   - cursor: Pagination cursor for next page
    ///   - order: Sort order (.ascending or .descending)
    ///   - limit: Maximum number of records to return (default 10, max 200)
    /// - Returns: PageResponse containing matching claimable balances or error
    open func getClaimableBalances(asset:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        var requestPath = "/claimable_balances"
        
        var params = Dictionary<String,String>()
        params["asset"] = asset.toCanonicalForm()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getClaimableBalancesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves claimable balances that can be claimed by a specific account.
    /// - Parameters:
    ///   - claimantAccountId: The account ID that can claim the balances
    ///   - cursor: Pagination cursor for next page
    ///   - order: Sort order (.ascending or .descending)
    ///   - limit: Maximum number of records to return (default 10, max 200)
    /// - Returns: PageResponse containing claimable balances for the specified claimant or error
    open func getClaimableBalances(claimantAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        var requestPath = "/claimable_balances"
        
        var params = Dictionary<String,String>()
        params["claimant"] = claimantAccountId
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getClaimableBalancesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves claimable balances sponsored by a specific account.
    /// - Parameters:
    ///   - sponsorAccountId: The account ID that sponsors the balances
    ///   - cursor: Pagination cursor for next page
    ///   - order: Sort order (.ascending or .descending)
    ///   - limit: Maximum number of records to return (default 10, max 200)
    /// - Returns: PageResponse containing sponsored claimable balances or error
    open func getClaimableBalances(sponsorAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        var requestPath = "/claimable_balances"
        
        var params = Dictionary<String,String>()
        params["sponsor"] = sponsorAccountId
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getClaimableBalancesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Loads claimable balances from a specific URL for pagination.
    /// - Parameter url: The complete URL to fetch balances from (typically from PageResponse links)
    /// - Returns: PageResponse containing claimable balances or error
    open func getClaimableBalancesFromUrl(url:String) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                //print(String(data: data, encoding: .utf8)!)
                let values = try self.jsonDecoder.decode(PageResponse<ClaimableBalanceResponse>.self, from: data)
                return .success(page: values)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
