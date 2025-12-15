//
//  WebAuthRemoteTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.09.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class WebAuthRemoteTestCase: XCTestCase {

    /// Integration test: SEP-10 authentication with testanchor.stellar.org
    ///
    /// Tests the basic SEP-10 web authentication flow without client domain signing.
    func testWithStellarTestAnchor() async throws {
        let responseEnum = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: .testnet)

        let webAuth: WebAuthenticator
        switch responseEnum {
        case .success(let response):
            webAuth = response
        case .failure(let error):
            XCTFail("Failed to create WebAuthenticator: \(error)")
            return
        }

        let userKeyPair = try KeyPair.generateRandomKeyPair()
        let userAccountId = userKeyPair.accountId

        print("Testing SEP-10 with testanchor.stellar.org...")
        print("User account: \(userAccountId)")

        let jwtResponseEnum = await webAuth.jwtToken(forUserAccount: userAccountId, signers: [userKeyPair])
        switch jwtResponseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            print("Successfully received JWT token")
            print("JWT: \(jwtToken)")
        case .failure(let error):
            XCTFail("Failed to get JWT token: \(error)")
        }
    }

    /// Integration test: SEP-10 authentication with testanchor.stellar.org and client domain
    ///
    /// Uses testsigner.stellargate.com as the client domain signing server.
    /// Remote signer source: https://github.com/Soneso/go-server-signer
    func testWithStellarTestAnchorAndClientDomain() async throws {
        let responseEnum = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: .testnet)

        let webAuth: WebAuthenticator
        switch responseEnum {
        case .success(let response):
            webAuth = response
        case .failure(let error):
            XCTFail("Failed to create WebAuthenticator: \(error)")
            return
        }

        // Client domain configuration
        // Remote signer source code: https://github.com/Soneso/go-server-signer
        let clientDomain = "testsigner.stellargate.com"
        let clientDomainSigningKey = "GBWW7NMWWIKPDEWZZKTTCSUGV2ZMVN23IZ5JFOZ4FWZBNVQNHMU47HOR"
        let remoteSigningUrl = "https://testsigner.stellargate.com/sign-sep-10"
        let bearerToken = "7b23fe8428e7fb9b3335ed36c39fb5649d3cd7361af8bf88c2554d62e8ca3017"

        // Create keypair with only the public key (no private key) for validation
        // The SDK will call the signing function since there's no private key
        let clientDomainAccountKeyPair = try KeyPair(accountId: clientDomainSigningKey)

        // Track callback invocation
        var callbackInvoked = false

        // Create callback that calls the remote signing server
        let signingFunction: (String) async throws -> String = { transactionXdr in
            callbackInvoked = true
            print("Callback invoked, sending transaction to remote signing server...")

            guard let url = URL(string: remoteSigningUrl) else {
                throw NSError(domain: "WebAuthRemoteTestCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

            let requestBody: [String: Any] = [
                "transaction": transactionXdr,
                "network_passphrase": "Test SDF Network ; September 2015"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "WebAuthRemoteTestCase", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "WebAuthRemoteTestCase", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Remote signing failed: \(errorBody)"])
            }

            guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let signedTransaction = jsonData["transaction"] as? String else {
                throw NSError(domain: "WebAuthRemoteTestCase", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
            }

            print("Remote signing server returned signed transaction")
            return signedTransaction
        }

        let userKeyPair = try KeyPair.generateRandomKeyPair()
        let userAccountId = userKeyPair.accountId

        print("Testing SEP-10 with testanchor.stellar.org and client domain...")
        print("User account: \(userAccountId)")
        print("Client domain: \(clientDomain)")

        let jwtResponseEnum = await webAuth.jwtToken(
            forUserAccount: userAccountId,
            signers: [userKeyPair],
            clientDomain: clientDomain,
            clientDomainAccountKeyPair: clientDomainAccountKeyPair,
            clientDomainSigningFunction: signingFunction
        )

        switch jwtResponseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(callbackInvoked, "Client domain signing callback should have been invoked")
            print("Successfully received JWT token with client domain support")
            print("JWT: \(jwtToken)")
        case .failure(let error):
            XCTFail("Failed to get JWT token: \(error)")
        }
    }
}
