//
//  HealthService.swift
//  stellarsdk
//
//  Created by Soneso on 05/10/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// An enum used to differentiate between successful and failed health check responses.
public enum HealthCheckResponseEnum {
    case success(details: HealthCheckResponse)
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a health check request.
public typealias HealthCheckResponseClosure = (_ response: HealthCheckResponseEnum) -> (Void)

/// Class that handles health check related calls.
/// The health endpoint provides information about the health status of the Horizon server,
/// including database connectivity and Stellar Core status.
open class HealthService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()

    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }

    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }

    /// Checks the health of the Horizon server.
    /// This endpoint returns information about the health status of Horizon,
    /// including whether it can connect to its database and Stellar Core,
    /// and whether Stellar Core is synchronized with the network.
    ///
    /// The HTTP status code returned by this endpoint will be:
    /// - 200 OK: if all health checks pass (database connected, core up, and core synced)
    /// - 503 Service Unavailable: if any health check fails
    ///
    /// See [Horizon API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/health "Health Check")
    ///
    /// - Parameter response: The closure to be called upon response.
    ///
    @available(*, renamed: "getHealth()")
    open func getHealth(response: @escaping HealthCheckResponseClosure) {
        Task {
            let result = await getHealth()
            response(result)
        }
    }

    /// Checks the health of the Horizon server.
    /// This endpoint returns information about the health status of Horizon,
    /// including whether it can connect to its database and Stellar Core,
    /// and whether Stellar Core is synchronized with the network.
    ///
    /// The HTTP status code returned by this endpoint will be:
    /// - 200 OK: if all health checks pass (database connected, core up, and core synced)
    /// - 503 Service Unavailable: if any health check fails
    ///
    /// See [Horizon API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/health "Health Check")
    ///
    /// - Returns: HealthCheckResponseEnum indicating success or failure
    ///
    open func getHealth() async -> HealthCheckResponseEnum {
        let requestPath = "/health"

        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let responseMessage = try self.jsonDecoder.decode(HealthCheckResponse.self, from: data)
                return .success(details: responseMessage)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }

        case .failure(let error):
            return .failure(error: error)
        }
    }
}
