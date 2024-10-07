//
//  File.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 09.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed fee stats responses.
public enum FeeStatsResponseEnum {
    case success(details: FeeStatsResponse)
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a fee stats request.
public typealias FeeStatsResponseClosure = (_ response:FeeStatsResponseEnum) -> (Void)

/// Class that handles fee stats related calls.
open class FeeStatsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// This endpoint gives useful information about per-operation fee stats in the last 5 ledgers. It can be used to predict a fee set on the transaction that will be submitted to the network.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/fee-stats.html "Fee stats")
    ///
    /// - Parameter response: The closure to be called upon response.
    ///
    /// - Throws:
    ///     - other 'HorizonRequestError' errors depending on the error case.
    ///
    @available(*, renamed: "getFeeStats()")
    open func getFeeStats(response: @escaping FeeStatsResponseClosure) {
        Task {
            let result = await getFeeStats()
            response(result)
        }
    }
    
    
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
