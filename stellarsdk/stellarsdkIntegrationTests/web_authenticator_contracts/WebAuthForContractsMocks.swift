//
//  WebAuthForContractsMocks.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13/12/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

class WebAuthForContractsTomlMock: ResponsesMock {
    var address: String
    var serverSigningKey: String
    var authServer: String
    var webAuthContractId: String

    init(address: String, serverSigningKey: String, authServer: String, webAuthContractId: String) {
        self.address = address
        self.serverSigningKey = serverSigningKey
        self.authServer = authServer
        self.webAuthContractId = webAuthContractId

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            return self?.stellarToml
        }

        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    var stellarToml: String {
        return """
            # Sample stellar.toml for SEP-45

            WEB_AUTH_FOR_CONTRACTS_ENDPOINT="\(authServer)"
            WEB_AUTH_CONTRACT_ID="\(webAuthContractId)"
            SIGNING_KEY="\(serverSigningKey)"
        """
    }
}

class WebAuthForContractsClientDomainTomlMock: ResponsesMock {
    var address: String
    var serverSigningKey: String

    init(address: String, serverSigningKey: String) {
        self.address = address
        self.serverSigningKey = serverSigningKey

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            return self?.stellarToml
        }

        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    var stellarToml: String {
        return """
            # Sample stellar.toml for client domain

            SIGNING_KEY="\(serverSigningKey)"
        """
    }
}

class WebAuthForContractsChallengeMock: ResponsesMock {
    var address: String
    var serverKeyPair: KeyPair
    var webAuthContractId: String
    var domain: String

    // Cache for test contract IDs to ensure consistent encoding/decoding
    var testContractIdCache: [String: Data] = [:]

    init(address: String, serverKeyPair: KeyPair, webAuthContractId: String, domain: String) {
        self.address = address
        self.serverKeyPair = serverKeyPair
        self.webAuthContractId = webAuthContractId
        self.domain = domain

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return "error" }

            if let account = mock.variables["account"] {
                // Success cases - normal client contract ID
                if account == "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        signServerEntry: true
                    )
                }
                // Invalid contract ID test
                else if account == "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM" {
                    mock.statusCode = 200
                    return self.buildChallengeWithWrongContractId(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address
                    )
                }
                // Invalid function name test
                else if account == "CBBBBBBBBB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQWBJRF" {
                    mock.statusCode = 200
                    return self.buildChallengeWithWrongFunctionName(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address
                    )
                }
                // Sub-invocations test
                else if account == "CCCCCCCCCMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGIQH2" {
                    mock.statusCode = 200
                    return self.buildChallengeWithSubInvocations(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address
                    )
                }
                // Invalid home domain test
                else if account == "CDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDAWP7S" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: "wrong.domain.com",
                        webAuthDomain: self.address,
                        signServerEntry: true
                    )
                }
                // Invalid web auth domain test
                else if account == "CEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEERDDQ" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: "wrong.auth.stellar.org",
                        signServerEntry: true
                    )
                }
                // Invalid account test (account in args doesn't match)
                else if account == "CBMKBASJGUKV26JB55OKZW3G3PGQ4C7PLRH6L2RW74PYUTE22Y4KFW56" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV",
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        signServerEntry: true
                    )
                }
                // Invalid nonce test
                else if account == "CFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4UQI" {
                    mock.statusCode = 200
                    return self.buildChallengeWithInconsistentNonce(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address
                    )
                }
                // Invalid server signature test
                else if account == "CGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGAZCRI" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        signServerEntry: false
                    )
                }
                // Missing server entry test
                else if account == "CHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHA2LJK" {
                    mock.statusCode = 200
                    return self.buildChallengeWithoutServerEntry(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address
                    )
                }
                // Missing client entry test
                else if account == "CIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIAH4NU" {
                    mock.statusCode = 200
                    return self.buildChallengeWithoutClientEntry(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address
                    )
                }
                // Invalid client domain account test
                else if account == "CJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJAGYRY" {
                    mock.statusCode = 200
                    let clientDomain = "client.example.com"
                    let wrongClientDomainAccount = "GCEQZYKOEJTZET2AKUY664EM44VFNRIAH7AXE4RIDWFV6UYGDTJWD2JJ"
                    return self.buildValidChallengeWithClientDomain(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        clientDomain: clientDomain,
                        clientDomainAccount: wrongClientDomainAccount,
                        signServerEntry: true
                    )
                }
                // Client domain test (success case with client domain)
                else if account == "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE" {
                    mock.statusCode = 200
                    let clientDomain = "client.example.com"
                    // Use the public key from the test's secret seed SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L
                    // which is GAIWNNJMDNZTSKEIWBZIERE3WCRIW2LCA3PK3GRX2K7DGWDA7Z5MVUZN
                    let clientDomainKeyPair = try! KeyPair(secretSeed: "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L")
                    return self.buildValidChallengeWithClientDomain(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        clientDomain: clientDomain,
                        clientDomainAccount: clientDomainKeyPair.accountId,
                        signServerEntry: true
                    )
                }
                // HTTP error test (get challenge error)
                else if account == "CLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLAPGFE" {
                    mock.statusCode = 400
                    return self.errorResponse
                }
                // Submit error test
                else if account == "CMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMA7YBP" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        signServerEntry: true
                    )
                }
                // Submit timeout test
                else if account == "CNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNAHVUO" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        signServerEntry: true
                    )
                }
            }

            mock.statusCode = 400
            return self.errorResponse
        }

        return RequestMock(host: address,
                           path: "*",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    // Helper to build args map as SCValXDR
    func buildArgsMap(
        account: String,
        homeDomain: String,
        webAuthDomain: String,
        webAuthDomainAccount: String,
        nonce: String,
        clientDomain: String? = nil,
        clientDomainAccount: String? = nil
    ) -> SCValXDR {
        var mapEntries: [SCMapEntryXDR] = []

        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("account"),
            val: SCValXDR.string(account)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("home_domain"),
            val: SCValXDR.string(homeDomain)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("web_auth_domain"),
            val: SCValXDR.string(webAuthDomain)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("web_auth_domain_account"),
            val: SCValXDR.string(webAuthDomainAccount)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("nonce"),
            val: SCValXDR.string(nonce)
        ))

        if let cd = clientDomain {
            mapEntries.append(SCMapEntryXDR(
                key: SCValXDR.symbol("client_domain"),
                val: SCValXDR.string(cd)
            ))
        }

        if let cda = clientDomainAccount {
            mapEntries.append(SCMapEntryXDR(
                key: SCValXDR.symbol("client_domain_account"),
                val: SCValXDR.string(cda)
            ))
        }

        return SCValXDR.map(mapEntries)
    }

    // Helper to build a single authorization entry
    func buildAuthEntry(
        credentialsAddress: String,
        contractId: String,
        functionName: String,
        argsMap: SCValXDR,
        nonce: Int64,
        expirationLedger: UInt32,
        signWith: KeyPair? = nil,
        network: Network = .testnet,
        subInvocations: [SorobanAuthorizedInvocationXDR] = []
    ) throws -> SorobanAuthorizationEntryXDR {
        // Create address
        let address: SCAddressXDR
        if credentialsAddress.starts(with: "C") {
            // Check cache first for test contract IDs
            let contractIdData: Data
            if let cachedData = testContractIdCache[credentialsAddress] {
                contractIdData = cachedData
            } else {
                // Try to decode contract ID
                do {
                    contractIdData = try credentialsAddress.decodeContractId()
                    testContractIdCache[credentialsAddress] = contractIdData
                } catch {
                    // Generate unique data based on the string to ensure different test IDs don't collide
                    var hasher = Hasher()
                    hasher.combine(credentialsAddress)
                    let hashValue = hasher.finalize()
                    var data = Data(count: 32)
                    withUnsafeBytes(of: hashValue) { bytes in
                        data.replaceSubrange(0..<min(bytes.count, 32), with: bytes)
                    }
                    testContractIdCache[credentialsAddress] = data
                    contractIdData = data
                }
            }
            address = SCAddressXDR.contract(WrappedData32(contractIdData))
        } else if credentialsAddress.starts(with: "G") {
            let publicKey = try PublicKey(accountId: credentialsAddress)
            address = SCAddressXDR.account(publicKey)
        } else {
            throw NSError(domain: "Invalid address", code: 0)
        }

        // Create credentials
        let credentials = SorobanCredentialsXDR.address(
            SorobanAddressCredentialsXDR(
                address: address,
                nonce: nonce,
                signatureExpirationLedger: expirationLedger,
                signature: SCValXDR.vec([])
            )
        )

        // Create contract function
        let contractAddress: SCAddressXDR
        // Check cache first for contract ID
        let contractIdData: Data
        if let cachedData = testContractIdCache[contractId] {
            contractIdData = cachedData
        } else {
            // Try to decode contract ID
            do {
                contractIdData = try contractId.decodeContractId()
                testContractIdCache[contractId] = contractIdData
            } catch {
                // Generate unique data based on the string
                var hasher = Hasher()
                hasher.combine(contractId)
                let hashValue = hasher.finalize()
                var data = Data(count: 32)
                withUnsafeBytes(of: hashValue) { bytes in
                    data.replaceSubrange(0..<min(bytes.count, 32), with: bytes)
                }
                testContractIdCache[contractId] = data
                contractIdData = data
            }
        }
        contractAddress = SCAddressXDR.contract(WrappedData32(contractIdData))

        let contractFn = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: functionName,
            args: [argsMap]
        )

        let function = SorobanAuthorizedFunctionXDR.contractFn(contractFn)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: function,
            subInvocations: subInvocations
        )

        var entry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )

        // Sign if keypair provided
        if let signer = signWith {
            try entry.sign(signer: signer, network: network)
        }

        return entry
    }

    // Helper to encode authorization entries to base64 XDR
    func encodeAuthEntries(_ entries: [SorobanAuthorizationEntryXDR]) throws -> String {
        struct AuthEntriesArray: XDREncodable {
            let entries: [SorobanAuthorizationEntryXDR]

            func xdrEncode(to encoder: XDREncoder) throws {
                try encoder.encode(Int32(entries.count))
                for entry in entries {
                    try encoder.encode(entry)
                }
            }
        }

        let wrapper = AuthEntriesArray(entries: entries)
        let encodedBytes = try XDREncoder.encode(wrapper)
        return Data(encodedBytes).base64EncodedString()
    }

    func buildValidChallenge(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String,
        signServerEntry: Bool
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            // Server entry
            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: signServerEntry ? serverKeyPair : nil
            )
            entries.append(serverEntry)

            // Client entry
            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildValidChallengeWithClientDomain(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String,
        clientDomain: String,
        clientDomainAccount: String,
        signServerEntry: Bool
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce,
                clientDomain: clientDomain,
                clientDomainAccount: clientDomainAccount
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            // Server entry
            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: signServerEntry ? serverKeyPair : nil
            )
            entries.append(serverEntry)

            // Client entry
            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            // Client domain entry
            let clientDomainEntry = try buildAuthEntry(
                credentialsAddress: clientDomainAccount,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12347,
                expirationLedger: 1000000
            )
            entries.append(clientDomainEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildChallengeWithWrongContractId(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String
    ) -> String {
        do {
            let wrongContractId = "CCJCTOZFKPNTFLMORB7RBNKDQU42PBKGVTI4DIWVEMUCXRHWCYXGRRV7"
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: wrongContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: serverKeyPair
            )
            entries.append(serverEntry)

            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: wrongContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildChallengeWithWrongFunctionName(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "wrong_function",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: serverKeyPair
            )
            entries.append(serverEntry)

            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: webAuthContractId,
                functionName: "wrong_function",
                argsMap: argsMap,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildChallengeWithSubInvocations(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            // Create a sub-invocation
            let contractIdData = try webAuthContractId.decodeContractId()
            let contractAddress = SCAddressXDR.contract(WrappedData32(contractIdData))
            let subContractFn = InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "some_other_function",
                args: []
            )
            let subFunction = SorobanAuthorizedFunctionXDR.contractFn(subContractFn)
            let subInvocation = SorobanAuthorizedInvocationXDR(
                function: subFunction,
                subInvocations: []
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: serverKeyPair,
                subInvocations: [subInvocation]
            )
            entries.append(serverEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildChallengeWithInconsistentNonce(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String
    ) -> String {
        do {
            let nonce1 = "test_nonce_1"
            let nonce2 = "test_nonce_2"

            let argsMap1 = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce1
            )

            let argsMap2 = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce2
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap1,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: serverKeyPair
            )
            entries.append(serverEntry)

            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap2,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildChallengeWithoutServerEntry(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            // Only client entry, no server entry
            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    func buildChallengeWithoutClientEntry(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            // Only server entry, no client entry
            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: serverKeyPair
            )
            entries.append(serverEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    var errorResponse: String {
        return """
        {
            "error": "Invalid account or request"
        }
        """
    }
}

class WebAuthForContractsSendChallengeMock: ResponsesMock {
    var address: String
    var shouldTimeout: Bool = false
    var shouldError: Bool = false

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return "error" }

            // Parse the request body to extract the client account ID
            var clientAccountId: String?
            if let httpBody = request.httpBody {
                // Try to extract authorization_entries from the body
                var authEntriesBase64: String?

                // Check if it's form-urlencoded
                if let bodyString = String(data: httpBody, encoding: .utf8) {
                    if bodyString.contains("authorization_entries=") {
                        // Form-urlencoded
                        let components = bodyString.components(separatedBy: "&")
                        for component in components {
                            let pair = component.components(separatedBy: "=")
                            if pair.count == 2 && pair[0] == "authorization_entries" {
                                authEntriesBase64 = pair[1].removingPercentEncoding
                                break
                            }
                        }
                    }
                }

                // Check if it's JSON
                if authEntriesBase64 == nil {
                    if let json = try? JSONSerialization.jsonObject(with: httpBody) as? [String: Any],
                       let entries = json["authorization_entries"] as? String {
                        authEntriesBase64 = entries
                    }
                }

                // Decode the authorization entries to find the client account
                if let base64Xdr = authEntriesBase64,
                   let xdrData = Data(base64Encoded: base64Xdr) {
                    do {
                        let xdrDecoder = XDRDecoder(data: xdrData)
                        let count = try xdrDecoder.decode(Int32.self)

                        // Iterate through entries to find client entry
                        for _ in 0..<count {
                            let entry = try SorobanAuthorizationEntryXDR(from: xdrDecoder)

                            // Get the credentials address
                            if case .address(let addressCreds) = entry.credentials {
                                let address = addressCreds.address

                                // Convert to string
                                switch address {
                                case .contract(let contractId):
                                    if let accountStr = try? contractId.wrapped.encodeContractId() {
                                        // Check if this is a client entry (not server entry)
                                        // Client entries typically have empty or non-server signatures
                                        if accountStr.starts(with: "C") {
                                            clientAccountId = accountStr
                                        }
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    } catch {
                        // Failed to parse, ignore
                    }
                }
            }

            // Check for specific test IDs
            if let accountId = clientAccountId {
                // Submit error test ID
                if accountId == "CMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMA7YBP" {
                    mock.statusCode = 400
                    return """
                    {
                        "error": "Invalid signature"
                    }
                    """
                }
                // Submit timeout test ID
                if accountId == "CNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNAHVUO" {
                    mock.statusCode = 504
                    return "Gateway Timeout"
                }
            }

            // Check for global flags (for backward compatibility)
            if self.shouldTimeout {
                mock.statusCode = 504
                return "Gateway Timeout"
            }

            if self.shouldError {
                mock.statusCode = 400
                return """
                {
                    "error": "Invalid signature"
                }
                """
            }

            mock.statusCode = 200
            return self.successResponse
        }

        return RequestMock(host: address,
                           path: "*",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    var successResponse: String {
        return """
        {
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJDRFpKSURRVzVXVFBBWjY0UEdJSkdWRUlETks3MkxMM0xLVVpXRzNHNkdXWFlRS0kySkFJVkZOViIsImlzcyI6ImV4YW1wbGUuc3RlbGxhci5vcmciLCJpYXQiOjE3Mzc3NjAwMDAsImV4cCI6MTczNzc2MzYwMH0.test"
        }
        """
    }
}
