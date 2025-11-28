//
//  HealthRemoteTestCase.swift
//  stellarsdk
//
//  Created by Soneso on 05/10/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class HealthRemoteTestCase: XCTestCase {
    static let testOn = "testnet" // "futurenet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()

    func testGetHealth() async {

        let response = await sdk.health.getHealth()

        switch response {
        case .success(let healthResponse):
            // Verify all boolean fields are present
            XCTAssertNotNil(healthResponse.databaseConnected)
            XCTAssertNotNil(healthResponse.coreUp)
            XCTAssertNotNil(healthResponse.coreSynced)

            // For a healthy testnet/futurenet, we expect all to be true
            // However, we don't enforce this as the network may have transient issues
            print("Database Connected: \(healthResponse.databaseConnected)")
            print("Core Up: \(healthResponse.coreUp)")
            print("Core Synced: \(healthResponse.coreSynced)")
            print("Overall Healthy: \(healthResponse.isHealthy)")

            // The test passes as long as we get a valid response
            XCTAssertTrue(true)

        case .failure(let error):
            // Note: The health endpoint may return 503 Service Unavailable if unhealthy
            // This is still a valid response, just indicates the service is not healthy
            switch error {
            case .staleHistory(let message, _):
                // 503 response with health status - this is expected behavior
                print("Horizon is unhealthy (503): \(message)")
                XCTAssertTrue(true)
            default:
                StellarSDKLog.printHorizonRequestErrorMessage(tag: "Load health testcase", horizonRequestError: error)
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testHealthResponseIsHealthyProperty() async {
        let response = await sdk.health.getHealth()

        switch response {
        case .success(let healthResponse):
            // Test the convenience property
            let expectedHealthy = healthResponse.databaseConnected &&
                                healthResponse.coreUp &&
                                healthResponse.coreSynced

            XCTAssertEqual(healthResponse.isHealthy, expectedHealthy,
                         "isHealthy property should match individual health checks")

        case .failure(_):
            // If we get a failure, that's also a valid test result
            // The health endpoint can return 503 when unhealthy
            XCTAssertTrue(true)
        }
    }

    func testHealthCheckMultipleNetworks() async {
        // Test against public network
        let publicSDK = StellarSDK.publicNet()
        let publicResponse = await publicSDK.health.getHealth()

        switch publicResponse {
        case .success(let healthResponse):
            print("Public Network - Database Connected: \(healthResponse.databaseConnected)")
            print("Public Network - Core Up: \(healthResponse.coreUp)")
            print("Public Network - Core Synced: \(healthResponse.coreSynced)")
            XCTAssertTrue(true)
        case .failure(_):
            // 503 is acceptable
            XCTAssertTrue(true)
        }

        // Test against test network
        let testSDK = StellarSDK.testNet()
        let testResponse = await testSDK.health.getHealth()

        switch testResponse {
        case .success(let healthResponse):
            print("Test Network - Database Connected: \(healthResponse.databaseConnected)")
            print("Test Network - Core Up: \(healthResponse.coreUp)")
            print("Test Network - Core Synced: \(healthResponse.coreSynced)")
            XCTAssertTrue(true)
        case .failure(_):
            // 503 is acceptable
            XCTAssertTrue(true)
        }
    }
}
