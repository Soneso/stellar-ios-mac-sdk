//
//  HealthService.swift
//  stellarsdk
//
//  Created by Soneso on 05/10/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Result enum for health check requests.
public enum HealthCheckResponseEnum {
    /// Successfully retrieved health check details from Horizon.
    case success(details: HealthCheckResponse)
    /// Failed to retrieve health check details due to a network or server error.
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a health check request.
public typealias HealthCheckResponseClosure = (_ response: HealthCheckResponseEnum) -> (Void)

/// Service for checking Horizon server health status.
///
/// The health endpoint provides information about the Horizon server's operational status,
/// including database connectivity and Stellar Core synchronization. Useful for monitoring
/// and determining if the server is ready to handle requests.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// let response = await sdk.health.getHealthCheck()
/// switch response {
/// case .success(let health):
///     print("Status: \(health.status)")
/// case .failure(let error):
///     print("Health check failed: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
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
    /// See [Stellar developer docs](https://developers.stellar.org)
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
    /// See [Stellar developer docs](https://developers.stellar.org)
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
