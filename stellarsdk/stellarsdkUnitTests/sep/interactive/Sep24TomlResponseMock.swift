//
//  Sep24TomlResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24TomlResponseMock: ResponsesMock {
    var address: String

    init(address:String) {
        self.address = address

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }

            // Check URL path for specific test scenarios
            if let url = request.url {
                let path = url.path
                if path.contains("invalid-domain") {
                    mock.statusCode = 404
                    return nil
                } else if path.contains("invalid-toml") {
                    mock.statusCode = 200
                    return self.invalidToml
                } else if path.contains("missing-transfer-server") {
                    mock.statusCode = 200
                    return self.missingTransferServer
                }
            }

            mock.statusCode = 200
            return self.validToml
        }

        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let validToml = """
    # Stellar TOML file
    VERSION = "2.0.0"
    NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
    TRANSFER_SERVER_SEP0024 = "https://api.example.com/sep24"
    WEB_AUTH_ENDPOINT = "https://api.example.com/auth"
    """

    let invalidToml = """
    This is not valid TOML content
    { invalid: json: too }
    """

    let missingTransferServer = """
    # Stellar TOML file without TRANSFER_SERVER_SEP0024
    VERSION = "2.0.0"
    NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
    WEB_AUTH_ENDPOINT = "https://api.example.com/auth"
    """
}
