//
//  File.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 09.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Result enum for fee statistics requests.
public enum FeeStatsResponseEnum {
    /// Successfully retrieved fee statistics from Horizon.
    case success(details: FeeStatsResponse)
    /// Failed to retrieve fee statistics due to a network or server error.
    case failure(error: HorizonRequestError)
}

/// Service for querying network fee statistics from the Stellar Horizon API.
///
/// Provides current fee statistics including min, mode, and percentile fees from recent ledgers.
/// Use this to determine appropriate fee levels for transaction submission.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// let response = await sdk.feeStats.getFeeStats()
/// switch response {
/// case .success(let feeStats):
///     print("Min fee: \(feeStats.minAcceptedFee)")
///     print("Mode fee: \(feeStats.modeAcceptedFee)")
///     print("P90 fee: \(feeStats.feeCharged.p90)")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
open class FeeStatsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// This endpoint gives useful information about per-operation fee stats in the last 5 ledgers. It can be used to predict a fee set on the transaction that will be submitted to the network.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// - Returns: FeeStatsResponseEnum with fee statistics on success or error on failure
    ///
    open func getFeeStats() async -> FeeStatsResponseEnum {
        let requestPath = "/fee_stats"
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let responseMessage = try self.jsonDecoder.decode(FeeStatsResponse.self, from: data)
                return .success(details:responseMessage)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
