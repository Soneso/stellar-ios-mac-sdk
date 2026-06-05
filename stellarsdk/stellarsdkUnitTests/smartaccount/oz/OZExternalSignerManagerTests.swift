//
//  OZExternalSignerManagerTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZExternalSignerManagerTests: XCTestCase {

    // ========================================================================
    // Constants
    // ========================================================================

    private let testNetworkPassphrase = Network.testnet.passphrase

    /// Storage key under which the manager persists wallet connections.
    /// Sourced from the production static so the tests automatically follow
    /// any rename of the canonical key.
    private let walletStorageKey = OZExternalSignerManager.walletStorageKey

    private let validAddress1 = "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN5"
    private let validAddress2 = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
    private let validAddress3 = "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"

    // ========================================================================
    // Fixtures
    // ========================================================================

    private func newKeypair() throws -> KeyPair {
        return try KeyPair.generateRandomKeyPair()
    }

    private func makeManager(
        walletAdapter: OZExternalWalletAdapter? = nil,
        walletConnectionStorage: OZWalletConnectionStorage? = nil
    ) -> OZExternalSignerManager {
        return OZExternalSignerManager(
            networkPassphrase: testNetworkPassphrase,
            walletAdapter: walletAdapter,
            walletConnectionStorage: walletConnectionStorage
        )
    }

    // ========================================================================
    // E.1 — addFromSecret (5 cases)
    // ========================================================================

    func test_addFromSecret_validSecret_returnsAddress() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let secret = keypair.secretSeed!

        let address = try await manager.addFromSecret(secretKey: secret)

        XCTAssertEqual(address, keypair.accountId)
        XCTAssertTrue(address.hasPrefix("G"))
        XCTAssertEqual(address.count, 56)

        let info = await manager.get(address: address)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.type, .keypair)
        XCTAssertEqual(info?.address, address)
        XCTAssertNil(info?.walletName)
        XCTAssertNil(info?.walletId)
    }

    func test_addFromSecret_invalidSecret_throwsSignerInvalid() async throws {
        let manager = makeManager()

        do {
            _ = try await manager.addFromSecret(secretKey: "INVALID_SECRET_KEY")
            XCTFail("expected SmartAccountSignerException.Invalid")
        } catch let error as SmartAccountSignerException.Invalid {
            XCTAssertEqual(error.code, .signerInvalid)
            XCTAssertTrue(error.message.contains("Invalid signer"))
        }

        do {
            _ = try await manager.addFromSecret(secretKey: "")
            XCTFail("expected SmartAccountSignerException.Invalid")
        } catch is SmartAccountSignerException.Invalid {
            // expected
        }

        // A G-address must NOT be accepted as a secret key.
        let keypair = try newKeypair()
        do {
            _ = try await manager.addFromSecret(secretKey: keypair.accountId)
            XCTFail("expected SmartAccountSignerException.Invalid")
        } catch is SmartAccountSignerException.Invalid {
            // expected
        }
    }

    func test_addFromSecret_overwritesExistingKeypair() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let secret = keypair.secretSeed!

        let address1 = try await manager.addFromSecret(secretKey: secret)
        let address2 = try await manager.addFromSecret(secretKey: secret)

        XCTAssertEqual(address1, address2)
        let all = await manager.getAll()
        XCTAssertEqual(all.count, 1)
    }

    func test_addFromSecret_removesStaleWalletEntry() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        let keypair = try newKeypair()
        let address = keypair.accountId

        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        // Establish a persisted wallet entry first.
        adapter.nextConnect = OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        _ = try await manager.addFromWallet()
        let beforeJson = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(beforeJson, "wallet should be persisted to storage")
        XCTAssertTrue(beforeJson!.contains(address))

        // Now add a keypair for the same address; storage entry must be cleared.
        _ = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        let afterJson = await storage.getItem(key: walletStorageKey)
        XCTAssertNil(
            afterJson,
            "wallet storage entry must be cleared when keypair takes precedence"
        )
    }

    func test_addFromSecret_concurrentCalls_serializedByActor() async throws {
        let manager = makeManager()

        // Spawn many concurrent addFromSecret calls; each must succeed and
        // contribute a distinct entry. Actor isolation serializes mutation.
        let count = 25
        var keypairs: [KeyPair] = []
        keypairs.reserveCapacity(count)
        for _ in 0..<count {
            keypairs.append(try newKeypair())
        }

        await withTaskGroup(of: Void.self) { group in
            for keypair in keypairs {
                let manager = manager
                let secret = keypair.secretSeed!
                group.addTask {
                    _ = try? await manager.addFromSecret(secretKey: secret)
                }
            }
        }

        let all = await manager.getAll()
        XCTAssertEqual(all.count, count)
        let addresses = Set(all.map { $0.address })
        XCTAssertEqual(addresses.count, count)
        for keypair in keypairs {
            XCTAssertTrue(addresses.contains(keypair.accountId))
        }
    }

    // ========================================================================
    // E.2 — addFromWallet (4 cases)
    // ========================================================================

    func test_addFromWallet_noAdapter_throwsConfiguration() async throws {
        let manager = makeManager()

        do {
            _ = try await manager.addFromWallet()
            XCTFail("expected SmartAccountConfigurationException.MissingConfig")
        } catch let error as SmartAccountConfigurationException.MissingConfig {
            XCTAssertEqual(error.code, .missingConfig)
            XCTAssertTrue(error.message.contains("walletAdapter"))
        }
    }

    func test_addFromWallet_userCancelled_returnsNil() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.nextConnect = nil // simulate user cancellation
        let manager = makeManager(walletAdapter: adapter)

        let result = try await manager.addFromWallet()
        XCTAssertNil(result, "user cancellation must surface as nil, not as an error")
    }

    func test_addFromWallet_success_persistsToStorage() async throws {
        let adapter = FakeExternalWalletAdapter()
        let storage = OZInMemoryWalletConnectionStorage()
        let wallet = OZConnectedWallet(
            address: validAddress1,
            walletId: "freighter",
            walletName: "Freighter"
        )
        adapter.nextConnect = wallet
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let result = try await manager.addFromWallet()
        XCTAssertEqual(result, wallet)

        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(json)
        XCTAssertTrue(json!.contains(validAddress1))
        XCTAssertTrue(json!.contains("freighter"))
        XCTAssertTrue(json!.contains("Freighter"))
    }

    func test_addFromWallet_noStorage_doesNotPersist() async throws {
        let adapter = FakeExternalWalletAdapter()
        let wallet = OZConnectedWallet(
            address: validAddress1,
            walletId: "freighter",
            walletName: "Freighter"
        )
        adapter.nextConnect = wallet
        // No walletConnectionStorage configured.
        let manager = makeManager(walletAdapter: adapter)

        let result = try await manager.addFromWallet()
        XCTAssertEqual(result, wallet)
        // No way to verify storage state directly because none is configured.
        // hasWalletAdapter remains true; adapter sees the connect call.
        XCTAssertTrue(adapter.connectCallCount == 1)
        let hasAdapter = await manager.hasWalletAdapter
        XCTAssertTrue(hasAdapter)
    }

    // ========================================================================
    // E.3 — canSignFor (4 cases)
    // ========================================================================

    func test_canSignFor_keypairExists_returnsTrue() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let address = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        let canSign = await manager.canSignFor(address: address)
        XCTAssertTrue(canSign)
    }

    func test_canSignFor_walletExists_returnsTrue() async throws {
        let adapter = FakeExternalWalletAdapter()
        let wallet = OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        adapter.nextConnect = wallet
        let manager = makeManager(walletAdapter: adapter)
        _ = try await manager.addFromWallet()

        let canSign = await manager.canSignFor(address: validAddress1)
        XCTAssertTrue(canSign)
    }

    func test_canSignFor_neitherExists_returnsFalse() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()

        let canSign = await manager.canSignFor(address: keypair.accountId)
        XCTAssertFalse(canSign)
    }

    func test_canSignFor_keypairTakesPrecedence() async throws {
        let adapter = FakeExternalWalletAdapter()
        let keypair = try newKeypair()
        let address = keypair.accountId
        // Pre-register the wallet adapter to claim the same address.
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))

        let manager = makeManager(walletAdapter: adapter)
        _ = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        let info = await manager.get(address: address)
        XCTAssertEqual(info?.type, .keypair, "keypair must take precedence over wallet")
        let canSign = await manager.canSignFor(address: address)
        XCTAssertTrue(canSign)
    }

    // ========================================================================
    // E.4 — signAuthEntry (8 cases)
    // ========================================================================

    func test_signAuthEntry_keypair_decodesPreimageHashesEd25519Signs() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let address = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        // Build a preimage payload and base64-encode it.
        let preimagePayload = Data(repeating: 0xAB, count: 64)
        let preimageBase64 = preimagePayload.base64EncodedString()

        let result = try await manager.signAuthEntry(
            address: address,
            authEntry: preimageBase64
        )

        XCTAssertEqual(result.signerAddress, address)

        // Verify the signature: SHA-256(preimage) then Ed25519-sign with the
        // same keypair must reproduce the manager's signature byte-for-byte.
        let expectedHash = preimagePayload.sha256Hash
        let expectedSignature = Data(keypair.sign([UInt8](expectedHash)))
        let observedSignature = Data(base64Encoded: result.signedAuthEntry)
        XCTAssertNotNil(observedSignature)
        XCTAssertEqual(observedSignature, expectedSignature)
        XCTAssertEqual(observedSignature?.count, 64)
    }

    func test_signAuthEntry_keypair_invalidBase64_throwsSigningFailed() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let address = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        do {
            _ = try await manager.signAuthEntry(
                address: address,
                authEntry: "not-valid-base64-!!!"
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(error.message.contains("decode"))
        }
    }

    func test_signAuthEntry_walletDelegate_passesNetworkPassphraseAndAddress() async throws {
        // Adapter returns a real Ed25519 signature so the local verification
        // step accepts the signature and surfaces the routing assertions this
        // test cares about.
        let adapter = FakeExternalWalletAdapter()
        let walletKeyPair = try newKeypair()
        let wallet = OZConnectedWallet(
            address: walletKeyPair.accountId,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        adapter.preset(wallet: wallet)

        let preimagePayload = Data(repeating: 0x33, count: 32)
        let preimageBase64 = preimagePayload.base64EncodedString()
        let preimageHash = preimagePayload.sha256Hash
        let realSignature = Data(walletKeyPair.sign([UInt8](preimageHash)))
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: realSignature.base64EncodedString(),
            signerAddress: walletKeyPair.accountId
        )

        let manager = makeManager(walletAdapter: adapter)

        let result = try await manager.signAuthEntry(
            address: walletKeyPair.accountId,
            authEntry: preimageBase64
        )

        XCTAssertEqual(adapter.lastSignAuthInvocation?.preimageXdr, preimageBase64)
        XCTAssertEqual(adapter.lastSignAuthInvocation?.options?.networkPassphrase, testNetworkPassphrase)
        XCTAssertEqual(adapter.lastSignAuthInvocation?.options?.address, walletKeyPair.accountId)
        XCTAssertEqual(result.signerAddress, walletKeyPair.accountId)
    }

    /// Signatures returned by an external wallet adapter that do not verify
    /// against the requested address must be rejected before the transaction
    /// is forwarded to the on-chain pipeline.
    func test_signAuthEntry_walletDelegate_signatureDoesNotVerify_throwsSigningFailed() async throws {
        let adapter = FakeExternalWalletAdapter()
        let walletKeyPair = try newKeypair()
        let wallet = OZConnectedWallet(
            address: walletKeyPair.accountId,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        adapter.preset(wallet: wallet)

        // Mismatched signature: 64 zero bytes will not verify under any real
        // public key.
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: Data(repeating: 0x00, count: 64).base64EncodedString(),
            signerAddress: walletKeyPair.accountId
        )
        let manager = makeManager(walletAdapter: adapter)

        let preimageBase64 = Data(repeating: 0x33, count: 32).base64EncodedString()
        do {
            _ = try await manager.signAuthEntry(
                address: walletKeyPair.accountId,
                authEntry: preimageBase64
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains("does not verify"),
                "expected verification failure message, got: \(error.message)"
            )
        }
    }

    func test_signAuthEntry_neitherSignerAvailable_throwsSignerNotFound() async throws {
        let manager = makeManager()

        do {
            _ = try await manager.signAuthEntry(
                address: validAddress3,
                authEntry: "AAAA" // base64 for 24 bits of zero
            )
            XCTFail("expected SmartAccountSignerException.NotFound")
        } catch let error as SmartAccountSignerException.NotFound {
            XCTAssertEqual(error.code, .signerNotFound)
            XCTAssertTrue(error.message.contains(validAddress3))
        }
    }

    func test_signAuthEntry_keypairFirst_walletNotConsulted() async throws {
        let adapter = FakeExternalWalletAdapter()
        let keypair = try newKeypair()
        let address = keypair.accountId
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: Data(repeating: 0xFF, count: 64).base64EncodedString(),
            signerAddress: address
        )

        let manager = makeManager(walletAdapter: adapter)
        _ = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        let preimageBase64 = Data(repeating: 0x44, count: 16).base64EncodedString()
        let result = try await manager.signAuthEntry(
            address: address,
            authEntry: preimageBase64
        )

        // Wallet adapter must NOT have been called.
        XCTAssertEqual(adapter.signAuthCallCount, 0)
        XCTAssertEqual(result.signerAddress, address)

        // Signature must be the keypair-produced one, not the wallet stub.
        let preimage = Data(base64Encoded: preimageBase64)!
        let expectedSignature = Data(keypair.sign([UInt8](preimage.sha256Hash)))
        XCTAssertEqual(Data(base64Encoded: result.signedAuthEntry), expectedSignature)
    }

    func test_signAuthEntry_walletAdapterError_wrapsAsSigningFailed() async throws {
        let adapter = FakeExternalWalletAdapter()
        let wallet = OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        adapter.preset(wallet: wallet)
        struct AdapterFailure: Error, LocalizedError {
            var errorDescription: String? { "adapter blew up" }
        }
        adapter.signAuthError = AdapterFailure()
        let manager = makeManager(walletAdapter: adapter)

        do {
            _ = try await manager.signAuthEntry(
                address: validAddress1,
                authEntry: "AAAA"
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains(validAddress1),
                "wrapped error must surface the failing signer address"
            )
        }
    }

    func test_signAuthEntry_signatureBase64Encoded_inResult() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let address = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        let preimageBase64 = Data(repeating: 0x55, count: 8).base64EncodedString()
        let result = try await manager.signAuthEntry(
            address: address,
            authEntry: preimageBase64
        )

        let decoded = Data(base64Encoded: result.signedAuthEntry)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.count, 64, "Ed25519 signatures are 64 bytes")
    }

    func test_signAuthEntry_signerAddressInResult_matchesInput() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        let address = try await manager.addFromSecret(secretKey: keypair.secretSeed!)

        let preimageBase64 = Data(repeating: 0x66, count: 32).base64EncodedString()
        let result = try await manager.signAuthEntry(
            address: address,
            authEntry: preimageBase64
        )

        XCTAssertEqual(result.signerAddress, address)
    }

    // ========================================================================
    // E.5 — getAll / get / hasSigners (5 cases)
    // ========================================================================

    func test_getAll_returnsKeypairsFirstThenWallets() async throws {
        let adapter = FakeExternalWalletAdapter()
        let walletAddr = validAddress1
        adapter.preset(wallet: OZConnectedWallet(
            address: walletAddr,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        let manager = makeManager(walletAdapter: adapter)

        let kp = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        let all = await manager.getAll()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all[0].type, .keypair, "keypair signers must precede wallet signers")
        XCTAssertEqual(all[0].address, kp.accountId)
        XCTAssertEqual(all[1].type, .wallet)
        XCTAssertEqual(all[1].address, walletAddr)
    }

    func test_getAll_skipsWalletWhenAddressAlsoKeypair() async throws {
        let adapter = FakeExternalWalletAdapter()
        let kp = try newKeypair()
        let address = kp.accountId
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))

        let manager = makeManager(walletAdapter: adapter)
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        let all = await manager.getAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].type, .keypair)
        XCTAssertEqual(all[0].address, address)
    }

    func test_get_keypairTakesPrecedence() async throws {
        let adapter = FakeExternalWalletAdapter()
        let kp = try newKeypair()
        let address = kp.accountId
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))

        let manager = makeManager(walletAdapter: adapter)
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        let info = await manager.get(address: address)
        XCTAssertEqual(info?.type, .keypair)
        XCTAssertNil(info?.walletName)
        XCTAssertNil(info?.walletId)
    }

    func test_hasSigners_emptyManager_returnsFalse() async throws {
        let manager = makeManager()
        let hasSigners = await manager.hasSigners()
        XCTAssertFalse(hasSigners)
    }

    func test_hasSigners_anySignerPresent_returnsTrue() async throws {
        let manager = makeManager()
        let kp = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        let hasAfterAdd = await manager.hasSigners()
        XCTAssertTrue(hasAfterAdd)

        try await manager.removeAll()
        let hasAfterRemoveAll = await manager.hasSigners()
        XCTAssertFalse(hasAfterRemoveAll)

        // Now via wallet adapter only.
        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        let walletManager = makeManager(walletAdapter: adapter)
        let hasViaWallet = await walletManager.hasSigners()
        XCTAssertTrue(hasViaWallet)
    }

    // ========================================================================
    // E.6 — remove / removeAll (4 cases)
    // ========================================================================

    func test_remove_keypairAndWallet_removesBoth() async throws {
        let adapter = FakeExternalWalletAdapter()
        let storage = OZInMemoryWalletConnectionStorage()
        let kp = try newKeypair()
        let address = kp.accountId

        // Persist a wallet entry for the same address first.
        adapter.nextConnect = OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )
        _ = try await manager.addFromWallet()
        // Now add a keypair (this also clears storage).
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        // Re-add wallet to storage manually (simulate a stale entry surviving).
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))

        try await manager.remove(address: address)

        let info = await manager.get(address: address)
        XCTAssertNil(info, "remove() must clear both keypair and wallet bookkeeping")
        let canSign = await manager.canSignFor(address: address)
        XCTAssertFalse(canSign)
        XCTAssertEqual(adapter.disconnectByAddressCalls, [address])
    }

    func test_remove_callsAdapterDisconnectByAddress() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        let manager = makeManager(walletAdapter: adapter)

        try await manager.remove(address: validAddress1)

        XCTAssertEqual(adapter.disconnectByAddressCalls, [validAddress1])

        // Removing a non-registered address must not throw and must still call
        // disconnectByAddress (the adapter is the source of truth for wallets).
        try await manager.remove(address: validAddress3)
        XCTAssertEqual(adapter.disconnectByAddressCalls, [validAddress1, validAddress3])
    }

    func test_removeAll_clearsAllAndDisconnects() async throws {
        let adapter = FakeExternalWalletAdapter()
        let storage = OZInMemoryWalletConnectionStorage()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "w1",
            walletName: "WalletOne"
        ))
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress2,
            walletId: "w2",
            walletName: "WalletTwo"
        ))

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )
        let kp = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)
        await storage.setItem(key: walletStorageKey, value: "[]")

        try await manager.removeAll()

        XCTAssertEqual(adapter.disconnectCallCount, 1)
        let hasAfter = await manager.hasSigners()
        XCTAssertFalse(hasAfter)
        let all = await manager.getAll()
        XCTAssertTrue(all.isEmpty, "removeAll() must leave both keypair and wallet bookkeeping empty")
    }

    func test_removeAll_removesStorageKey() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        let adapter = FakeExternalWalletAdapter()
        adapter.nextConnect = OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        )
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )
        _ = try await manager.addFromWallet()
        let beforeJson = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(beforeJson)

        try await manager.removeAll()

        let afterJson = await storage.getItem(key: walletStorageKey)
        XCTAssertNil(afterJson)
    }

    func test_removeAll_clearsEd25519RegistrationsAlongsideWalletSigners() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.nextConnect = OZConnectedWallet(
            address: validAddress1,
            walletId: "w1",
            walletName: "WalletOne"
        )
        let storage = OZInMemoryWalletConnectionStorage()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        // Register one wallet signer.
        _ = try await manager.addFromWallet()

        // Register one Ed25519 signer.
        let ed25519Seed = Data(0x00 ..< 0x20)
        let verifierAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let pubKey = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519Seed,
            verifierAddress: verifierAddress
        )

        // Confirm both are registered before clearing.
        let canSignWallet = await manager.canSignFor(address: validAddress1)
        let canSignEd25519 = await manager.canSignEd25519For(
            verifierAddress: verifierAddress,
            publicKey: pubKey
        )
        XCTAssertTrue(canSignWallet, "wallet signer must be registered before removeAll")
        XCTAssertTrue(canSignEd25519, "Ed25519 signer must be registered before removeAll")

        try await manager.removeAll()

        let canSignWalletAfter = await manager.canSignFor(address: validAddress1)
        let canSignEd25519After = await manager.canSignEd25519For(
            verifierAddress: verifierAddress,
            publicKey: pubKey
        )
        XCTAssertFalse(canSignWalletAfter,
                       "removeAll() must clear the wallet signer")
        XCTAssertFalse(canSignEd25519After,
                       "removeAll() must clear the Ed25519 signer from ed25519Signers")
    }

    // ========================================================================
    // E.7 — restoreConnections (5 cases)
    // ========================================================================

    func test_restoreConnections_idempotent_secondCallReturnsCurrent() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(
            key: walletStorageKey,
            value: """
            [{"address":"\(validAddress1)","walletId":"freighter","walletName":"Freighter","connectedAt":1700000000000}]
            """
        )

        let adapter = FakeExternalWalletAdapter()
        adapter.reconnectResponse["freighter"] = OZConnectedWallet(
            address: validAddress1,
            walletId: "freighter",
            walletName: "Freighter"
        )

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let first = try await manager.restoreConnections()
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(adapter.reconnectCallCount, 1)

        // Second call: must NOT re-read storage and must NOT call reconnect again.
        let second = try await manager.restoreConnections()
        XCTAssertEqual(adapter.reconnectCallCount, 1, "reconnect must not be called on idempotent re-entry")
        // Second call returns whatever the adapter reports as currently connected.
        XCTAssertEqual(second.map { $0.walletId }, ["freighter"])
    }

    func test_restoreConnections_noStorage_returnsEmpty() async throws {
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(walletAdapter: adapter)

        let result = try await manager.restoreConnections()
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(adapter.reconnectCallCount, 0)
    }

    func test_restoreConnections_reconnectFailure_removesStaleEntry() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(
            key: walletStorageKey,
            value: """
            [{"address":"\(validAddress1)","walletId":"alpha","walletName":"Alpha","connectedAt":1700000000000},\
            {"address":"\(validAddress2)","walletId":"beta","walletName":"Beta","connectedAt":1700000001000}]
            """
        )

        let adapter = FakeExternalWalletAdapter()
        // Alpha succeeds; beta returns nil (treated as failure).
        adapter.reconnectResponse["alpha"] = OZConnectedWallet(
            address: validAddress1,
            walletId: "alpha",
            walletName: "Alpha"
        )
        adapter.reconnectResponse["beta"] = nil

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let restored = try await manager.restoreConnections()
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored[0].walletId, "alpha")

        // Storage must no longer contain the beta entry. The alpha entry was
        // never removed (only failed entries get cleaned up).
        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(json)
        XCTAssertTrue(json!.contains(validAddress1))
        XCTAssertFalse(json!.contains(validAddress2), "stale entry must be purged")
    }

    func test_restoreConnections_reconnectSuccess_returnsRestored() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(
            key: walletStorageKey,
            value: """
            [{"address":"\(validAddress1)","walletId":"alpha","walletName":"Alpha","connectedAt":1700000000000},\
            {"address":"\(validAddress2)","walletId":"beta","walletName":"Beta","connectedAt":1700000001000}]
            """
        )

        let adapter = FakeExternalWalletAdapter()
        adapter.reconnectResponse["alpha"] = OZConnectedWallet(
            address: validAddress1,
            walletId: "alpha",
            walletName: "Alpha"
        )
        adapter.reconnectResponse["beta"] = OZConnectedWallet(
            address: validAddress2,
            walletId: "beta",
            walletName: "Beta"
        )

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let restored = try await manager.restoreConnections()
        XCTAssertEqual(restored.count, 2)
        let walletIds = Set(restored.map { $0.walletId })
        XCTAssertEqual(walletIds, Set(["alpha", "beta"]))
    }

    func test_restoreConnections_concurrentCalls_serializedByActor() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(
            key: walletStorageKey,
            value: """
            [{"address":"\(validAddress1)","walletId":"freighter","walletName":"Freighter","connectedAt":1700000000000}]
            """
        )

        let adapter = FakeExternalWalletAdapter()
        adapter.reconnectResponse["freighter"] = OZConnectedWallet(
            address: validAddress1,
            walletId: "freighter",
            walletName: "Freighter"
        )

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        // Fire many concurrent restoreConnections calls. Actor isolation must
        // collapse the work so that reconnect is called at most once.
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                let manager = manager
                group.addTask {
                    _ = try? await manager.restoreConnections()
                }
            }
        }

        XCTAssertEqual(
            adapter.reconnectCallCount,
            1,
            "concurrent restoreConnections must collapse to a single reconnect call"
        )
    }

    // ========================================================================
    // E.8 — JSON storage (5 cases)
    // ========================================================================

    func test_serializeWallets_emptyList_validJsonArray() async throws {
        // Round-trip through storage: removing the last entry deletes the
        // storage key entirely (so we never need to serialize an empty list).
        let storage = OZInMemoryWalletConnectionStorage()
        let adapter = FakeExternalWalletAdapter()
        adapter.nextConnect = OZConnectedWallet(
            address: validAddress1,
            walletId: "w1",
            walletName: "WalletOne"
        )
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )
        _ = try await manager.addFromWallet()

        // Remove the single entry; storage key should be wiped, not left as "[]".
        try await manager.remove(address: validAddress1)

        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNil(json, "removing the last entry must delete the storage key")

        // Confirm that fresh-install state (no storage key) parses to empty.
        let result = try await manager.restoreConnections()
        XCTAssertTrue(result.isEmpty)
    }

    func test_serializeWallets_multipleEntries_correctOrder() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        // Persist three wallets in a known order.
        let wallets = [
            OZConnectedWallet(address: validAddress1, walletId: "alpha", walletName: "Alpha"),
            OZConnectedWallet(address: validAddress2, walletId: "beta", walletName: "Beta"),
            OZConnectedWallet(address: validAddress3, walletId: "gamma", walletName: "Gamma")
        ]
        for wallet in wallets {
            adapter.nextConnect = wallet
            _ = try await manager.addFromWallet()
        }

        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(json)

        let data = json!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 3)
        XCTAssertEqual(parsed?[0]["walletId"] as? String, "alpha")
        XCTAssertEqual(parsed?[1]["walletId"] as? String, "beta")
        XCTAssertEqual(parsed?[2]["walletId"] as? String, "gamma")
    }

    func test_parseStoredWallets_validJson_returnsList() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(
            key: walletStorageKey,
            value: """
            [{"address":"\(validAddress1)","walletId":"freighter","walletName":"Freighter","connectedAt":1700000000000},\
            {"address":"\(validAddress2)","walletId":"lobstr","walletName":"LOBSTR","connectedAt":1700000001000}]
            """
        )

        let adapter = FakeExternalWalletAdapter()
        adapter.reconnectResponse["freighter"] = OZConnectedWallet(
            address: validAddress1,
            walletId: "freighter",
            walletName: "Freighter"
        )
        adapter.reconnectResponse["lobstr"] = OZConnectedWallet(
            address: validAddress2,
            walletId: "lobstr",
            walletName: "LOBSTR"
        )

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let restored = try await manager.restoreConnections()
        XCTAssertEqual(restored.count, 2)
        let walletIds = Set(restored.map { $0.walletId })
        XCTAssertEqual(walletIds, Set(["freighter", "lobstr"]))
    }

    func test_parseStoredWallets_malformedJson_returnsEmpty() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(key: walletStorageKey, value: "this is not json at all")

        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        // Must not throw; malformed input -> empty list.
        let result = try await manager.restoreConnections()
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(adapter.reconnectCallCount, 0)
    }

    func test_removeWalletFromStorage_lastEntry_deletesStorageKey() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        adapter.nextConnect = OZConnectedWallet(
            address: validAddress1,
            walletId: "only",
            walletName: "Only"
        )
        _ = try await manager.addFromWallet()
        let beforeJson = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(beforeJson)

        try await manager.remove(address: validAddress1)

        let afterJson = await storage.getItem(key: walletStorageKey)
        XCTAssertNil(
            afterJson,
            "removing the last persisted wallet must delete the storage key, not leave an empty array"
        )
    }

    // ========================================================================
    // Auxiliary coverage — OZInMemoryWalletConnectionStorage primitives
    // ========================================================================

    func test_inMemoryStorage_basicOperations() async throws {
        let storage = OZInMemoryWalletConnectionStorage()

        let empty = await storage.getItem(key: "k1")
        XCTAssertNil(empty)

        await storage.setItem(key: "k1", value: "v1")
        let afterSet = await storage.getItem(key: "k1")
        XCTAssertEqual(afterSet, "v1")

        await storage.setItem(key: "k1", value: "v2")
        let afterOverwrite = await storage.getItem(key: "k1")
        XCTAssertEqual(afterOverwrite, "v2")

        await storage.removeItem(key: "k1")
        let afterRemove = await storage.getItem(key: "k1")
        XCTAssertNil(afterRemove)

        // Removing a non-existent key is a no-op.
        await storage.removeItem(key: "missing")
    }

    // ========================================================================
    // hasWalletAdapter
    // ========================================================================

    func test_hasWalletAdapter_noAdapter_returnsFalse() async throws {
        let manager = makeManager()
        let has = await manager.hasWalletAdapter
        XCTAssertFalse(has)
    }

    func test_hasWalletAdapter_withAdapter_returnsTrue() async throws {
        let manager = makeManager(walletAdapter: FakeExternalWalletAdapter())
        let has = await manager.hasWalletAdapter
        XCTAssertTrue(has)
    }

    // ========================================================================
    // Lifecycle, idempotency, and serialization edge cases
    // ========================================================================

    /// An empty secret key string must be rejected before the keypair is
    /// constructed.
    func test_addFromSecret_emptySecretKey_throws() async throws {
        let manager = makeManager()
        do {
            _ = try await manager.addFromSecret(secretKey: "")
            XCTFail("expected SmartAccountSignerException.Invalid")
        } catch is SmartAccountSignerException.Invalid {
            // expected
        }
    }

    /// A G-address (public account identifier) must NOT be accepted in place
    /// of an S-address (secret seed). The parser must reject it.
    func test_addFromSecret_publicKeyInsteadOfSecret_throws() async throws {
        let manager = makeManager()
        let keypair = try newKeypair()
        do {
            _ = try await manager.addFromSecret(secretKey: keypair.accountId)
            XCTFail("expected SmartAccountSignerException.Invalid for G-address as secret")
        } catch is SmartAccountSignerException.Invalid {
            // expected
        }
    }

    /// Adding multiple distinct keypair signers must produce independent
    /// entries — none must overwrite the others.
    func test_addFromSecret_multipleDistinctSigners_persistAll() async throws {
        let manager = makeManager()
        let kp1 = try newKeypair()
        let kp2 = try newKeypair()
        let kp3 = try newKeypair()

        _ = try await manager.addFromSecret(secretKey: kp1.secretSeed!)
        _ = try await manager.addFromSecret(secretKey: kp2.secretSeed!)
        _ = try await manager.addFromSecret(secretKey: kp3.secretSeed!)

        let all = await manager.getAll()
        XCTAssertEqual(all.count, 3)
        let addresses = Set(all.map { $0.address })
        XCTAssertTrue(addresses.contains(kp1.accountId))
        XCTAssertTrue(addresses.contains(kp2.accountId))
        XCTAssertTrue(addresses.contains(kp3.accountId))
    }

    /// After `remove(address:)`, the manager must report it cannot sign for
    /// the removed address.
    func test_canSignFor_afterRemoval_returnsFalse() async throws {
        let manager = makeManager()
        let kp = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        let canSignBefore = await manager.canSignFor(address: kp.accountId)
        XCTAssertTrue(canSignBefore)

        try await manager.remove(address: kp.accountId)

        let canSignAfter = await manager.canSignFor(address: kp.accountId)
        XCTAssertFalse(canSignAfter)
    }

    /// Looking up a non-existent signer must return `nil`, not throw.
    func test_get_nonExistent_returnsNil() async throws {
        let manager = makeManager()
        let info = await manager.get(address: validAddress3)
        XCTAssertNil(info)
    }

    /// `hasSigners()` must return `false` after `removeAll()` clears every
    /// managed entry.
    func test_hasSigners_afterRemoveAll_returnsFalse() async throws {
        let manager = makeManager()
        let kp = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)
        let hasBefore = await manager.hasSigners()
        XCTAssertTrue(hasBefore)

        try await manager.removeAll()
        let hasAfter = await manager.hasSigners()
        XCTAssertFalse(hasAfter)
    }

    /// Removing an address that was never registered must be a no-op rather
    /// than an error. The actor remains usable for subsequent calls.
    func test_remove_nonExistent_doesNotThrow() async throws {
        let manager = makeManager()
        do {
            try await manager.remove(address: validAddress3)
        } catch {
            XCTFail("removing a non-existent address must not throw, got: \(error)")
        }
    }

    /// `remove(address:)` must remove only the targeted signer; other
    /// signers must remain intact.
    func test_remove_onlyRemovesTargetSigner_othersIntact() async throws {
        let manager = makeManager()
        let kp1 = try newKeypair()
        let kp2 = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp1.secretSeed!)
        _ = try await manager.addFromSecret(secretKey: kp2.secretSeed!)

        try await manager.remove(address: kp1.accountId)

        let removedInfo = await manager.get(address: kp1.accountId)
        let remainingInfo = await manager.get(address: kp2.accountId)
        let removedCanSign = await manager.canSignFor(address: kp1.accountId)
        let remainingCanSign = await manager.canSignFor(address: kp2.accountId)
        XCTAssertNil(removedInfo)
        XCTAssertNotNil(remainingInfo)
        XCTAssertFalse(removedCanSign)
        XCTAssertTrue(remainingCanSign)
    }

    /// Wallet names containing JSON-significant characters must round-trip
    /// through the JSON storage layer without corruption.
    func test_serializationRoundTrip_specialCharactersInWalletName() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let specialName = #"Wallet "Pro" / v1.0 \ alpha"#
        let wallet = OZConnectedWallet(
            address: validAddress1,
            walletId: "special-id",
            walletName: specialName
        )
        adapter.nextConnect = wallet
        _ = try await manager.addFromWallet()

        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(json)

        // Decode through JSONSerialization so escape sequences are
        // unwrapped to the original characters.
        let data = json!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertEqual(parsed?.first?["walletName"] as? String, specialName)
    }

    /// Empty-string fields must round-trip correctly. The serializer must
    /// not coerce empty strings to nil or omit them.
    func test_serializationRoundTrip_emptyStringFields() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let wallet = OZConnectedWallet(
            address: validAddress1,
            walletId: "",
            walletName: ""
        )
        adapter.nextConnect = wallet
        _ = try await manager.addFromWallet()

        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(json)
        let data = json!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertEqual(parsed?.first?["walletId"] as? String, "")
        XCTAssertEqual(parsed?.first?["walletName"] as? String, "")
    }

    // ========================================================================
    // E.9 — Ed25519 methods (9 cases)
    // ========================================================================

    /// A valid C-strkey used as a verifier address throughout Ed25519 tests.
    private let ed25519VerifierAlpha =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    /// A second valid C-strkey used to test tuple-key disambiguation.
    private let ed25519VerifierBeta =
        "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"

    /// Raw 32-byte Ed25519 secret seed used for in-process Ed25519 signing tests.
    /// Shared with the fixture emitter so keys are byte-identical across test and
    /// fixture files. Bytes 0x00..0x1F provide a stable, deterministic seed.
    private let ed25519SecretBytes = Data(0x00 ..< 0x20)

    func test_addEd25519FromRawKey_validRawKey_storesKeypairAndReturnsPublicKey() async throws {
        let manager = makeManager()
        let seed = try Seed(bytes: [UInt8](ed25519SecretBytes))
        let expectedPublicKey = Data(KeyPair(seed: seed).publicKey.bytes)

        let publicKey = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierAlpha
        )

        XCTAssertEqual(publicKey, expectedPublicKey)
        XCTAssertEqual(publicKey.count, 32)

        // Registration must be visible via canSignEd25519For.
        let canSign = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)
        XCTAssertTrue(canSign)
    }

    func test_addEd25519FromRawKey_invalidRawKey_throwsInvalidInput() async throws {
        let manager = makeManager()

        // Wrong length: 16 bytes.
        do {
            _ = try await manager.addEd25519FromRawKey(
                secretKeyBytes: Data(repeating: 0, count: 16),
                verifierAddress: ed25519VerifierAlpha
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for 16-byte key")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.lowercased().contains("32"))
        }

        // Empty data.
        do {
            _ = try await manager.addEd25519FromRawKey(
                secretKeyBytes: Data(),
                verifierAddress: ed25519VerifierAlpha
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for empty key")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }

        // Wrong length: 33 bytes.
        do {
            _ = try await manager.addEd25519FromRawKey(
                secretKeyBytes: Data(repeating: 0, count: 33),
                verifierAddress: ed25519VerifierAlpha
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for 33-byte key")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    func test_addEd25519FromRawKey_sameKeyTwoVerifiers_storedAsDistinctEntries() async throws {
        let manager = makeManager()

        let publicKeyAlpha = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierAlpha
        )
        let publicKeyBeta = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierBeta
        )

        // Both verifier slots return the same public key (same seed bytes).
        XCTAssertEqual(publicKeyAlpha, publicKeyBeta)

        // Both (verifierAddress, publicKey) tuples must resolve to canSign = true.
        let canSignAlphaBefore = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKeyAlpha)
        let canSignBetaBefore = await manager.canSignEd25519For(verifierAddress: ed25519VerifierBeta, publicKey: publicKeyBeta)
        XCTAssertTrue(canSignAlphaBefore)
        XCTAssertTrue(canSignBetaBefore)

        // Removing one entry must not affect the other.
        await manager.removeEd25519(verifierAddress: ed25519VerifierAlpha, publicKey: publicKeyAlpha)
        let canSignAlphaAfter = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKeyAlpha)
        let canSignBetaAfter = await manager.canSignEd25519For(verifierAddress: ed25519VerifierBeta, publicKey: publicKeyBeta)
        XCTAssertFalse(canSignAlphaAfter)
        XCTAssertTrue(canSignBetaAfter)
    }

    func test_canSignEd25519For_registered_returnsTrue() async throws {
        let manager = makeManager()
        let publicKey = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierAlpha
        )

        let canSign = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)
        XCTAssertTrue(canSign)
    }

    func test_canSignEd25519For_unregistered_returnsFalse() async throws {
        let manager = makeManager()
        let seed = try Seed(bytes: [UInt8](ed25519SecretBytes))
        let publicKey = Data(KeyPair(seed: seed).publicKey.bytes)

        // Nothing registered yet.
        let canSign = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)
        XCTAssertFalse(canSign)
    }

    func test_signEd25519AuthDigest_registered_returnsValidSignature() async throws {
        let manager = makeManager()
        let publicKey = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierAlpha
        )

        let authDigest = Data(repeating: 0x42, count: 32)
        let signature = try await manager.signEd25519AuthDigest(
            verifierAddress: ed25519VerifierAlpha,
            publicKey: publicKey,
            authDigest: authDigest
        )

        XCTAssertEqual(signature.count, 64, "Ed25519 signatures are 64 bytes")

        // Locally verify: derive keypair from the same seed bytes and check.
        let verifySeed = try Seed(bytes: [UInt8](ed25519SecretBytes))
        let verifyKeypair = KeyPair(seed: verifySeed)
        let verifyValid = try verifyKeypair.verify(
            signature: [UInt8](signature),
            message: [UInt8](authDigest)
        )
        XCTAssertTrue(verifyValid, "signature produced by signEd25519AuthDigest must verify against the registered public key")
    }

    func test_signEd25519AuthDigest_unregistered_throwsValidation() async throws {
        let manager = makeManager()
        let seed = try Seed(bytes: [UInt8](ed25519SecretBytes))
        let publicKey = Data(KeyPair(seed: seed).publicKey.bytes)
        let authDigest = Data(repeating: 0x01, count: 32)

        do {
            _ = try await manager.signEd25519AuthDigest(
                verifierAddress: ed25519VerifierAlpha,
                publicKey: publicKey,
                authDigest: authDigest
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    func test_removeEd25519_clearsRegistration() async throws {
        let manager = makeManager()
        let publicKey = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierAlpha
        )

        let canSignBefore = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)
        XCTAssertTrue(canSignBefore)

        await manager.removeEd25519(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)

        let canSignAfter = await manager.canSignEd25519For(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)
        XCTAssertFalse(canSignAfter)

        // Removing a non-existent entry is a no-op.
        await manager.removeEd25519(verifierAddress: ed25519VerifierAlpha, publicKey: publicKey)
    }

    func test_ed25519Adapter_takesPrecedenceForCanSignForTrue() async throws {
        let seed = try Seed(bytes: [UInt8](ed25519SecretBytes))
        let publicKey = Data(KeyPair(seed: seed).publicKey.bytes)

        // Adapter claims it can sign; no in-process keypair registered.
        let adapter = FakeEd25519SignerAdapter(canSign: true)
        let manager = OZExternalSignerManager(
            networkPassphrase: testNetworkPassphrase,
            ed25519Adapter: adapter
        )

        let canSignViaAdapter = await manager.canSignEd25519For(
            verifierAddress: ed25519VerifierAlpha,
            publicKey: publicKey
        )
        XCTAssertTrue(
            canSignViaAdapter,
            "adapter returning true must short-circuit to true without consulting in-process registry"
        )
    }

    func test_ed25519Adapter_falsyAdapterFallsBackToInProcessKeypair() async throws {
        // Adapter claims it cannot sign; should fall back to in-process keypair.
        let adapter = FakeEd25519SignerAdapter(canSign: false)
        let manager = OZExternalSignerManager(
            networkPassphrase: testNetworkPassphrase,
            ed25519Adapter: adapter
        )
        let publicKey = try await manager.addEd25519FromRawKey(
            secretKeyBytes: ed25519SecretBytes,
            verifierAddress: ed25519VerifierAlpha
        )

        let canSignViaFallback = await manager.canSignEd25519For(
            verifierAddress: ed25519VerifierAlpha,
            publicKey: publicKey
        )
        XCTAssertTrue(
            canSignViaFallback,
            "when adapter returns false, canSignEd25519For must fall back to the in-process keypair registry"
        )
    }

    // ========================================================================
    // E.10 — get(address:) wallet branch
    // ========================================================================

    /// When no keypair matches but a wallet adapter reports a wallet for the
    /// address, `get(address:)` must return a `.wallet` info populated from the
    /// adapter's wallet record (name and id included).
    func test_get_walletOnly_returnsWalletInfoFromAdapter() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "freighter",
            walletName: "Freighter"
        ))
        let manager = makeManager(walletAdapter: adapter)

        let info = await manager.get(address: validAddress1)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.type, .wallet)
        XCTAssertEqual(info?.address, validAddress1)
        XCTAssertEqual(info?.walletName, "Freighter")
        XCTAssertEqual(info?.walletId, "freighter")
    }

    /// With a wallet adapter configured but no wallet registered for the
    /// queried address, `get(address:)` must return `nil`.
    func test_get_walletAdapterPresent_noMatch_returnsNil() async throws {
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(walletAdapter: adapter)

        let info = await manager.get(address: validAddress2)
        XCTAssertNil(info)
    }

    // ========================================================================
    // E.11 — verifyExternalWalletSignature error branches
    // ========================================================================

    /// The wallet adapter returning a non-base64 signature must be rejected
    /// during local verification before any on-chain submission.
    func test_signAuthEntry_walletDelegate_nonBase64Signature_throwsSigningFailed() async throws {
        let adapter = FakeExternalWalletAdapter()
        let walletKeyPair = try newKeypair()
        adapter.preset(wallet: OZConnectedWallet(
            address: walletKeyPair.accountId,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: "not-valid-base64-!!!",
            signerAddress: walletKeyPair.accountId
        )
        let manager = makeManager(walletAdapter: adapter)

        let preimageBase64 = Data(repeating: 0x33, count: 32).base64EncodedString()
        do {
            _ = try await manager.signAuthEntry(
                address: walletKeyPair.accountId,
                authEntry: preimageBase64
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains("non-base64"),
                "expected non-base64 signature message, got: \(error.message)"
            )
        }
    }

    /// When the adapter reports a signer address that is not a valid Stellar
    /// account id, public-key derivation must fail and surface as SigningFailed.
    func test_signAuthEntry_walletDelegate_invalidSignerAddress_throwsSigningFailed() async throws {
        let adapter = FakeExternalWalletAdapter()
        // The adapter must claim it can sign for the requested address, so use a
        // valid requested address but return an invalid signerAddress in the
        // result. expectedSignerAddress = result.signerAddress, which is invalid.
        let requested = validAddress1
        adapter.preset(wallet: OZConnectedWallet(
            address: requested,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: Data(repeating: 0x00, count: 64).base64EncodedString(),
            signerAddress: "not-a-valid-stellar-address"
        )
        let manager = makeManager(walletAdapter: adapter)

        let preimageBase64 = Data(repeating: 0x33, count: 32).base64EncodedString()
        do {
            _ = try await manager.signAuthEntry(
                address: requested,
                authEntry: preimageBase64
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains("derive public key"),
                "expected key-derivation failure message, got: \(error.message)"
            )
        }
    }

    /// A signature with a length other than 64 bytes makes `KeyPair.verify`
    /// throw (rather than return false); that throwing path must surface as
    /// SigningFailed with the "does not verify" message.
    func test_signAuthEntry_walletDelegate_wrongLengthSignature_verifyThrows_throwsSigningFailed() async throws {
        let adapter = FakeExternalWalletAdapter()
        let walletKeyPair = try newKeypair()
        adapter.preset(wallet: OZConnectedWallet(
            address: walletKeyPair.accountId,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        // 32-byte signature (valid base64, wrong length) makes verify() throw
        // Ed25519Error.invalidSignatureLength inside verifyExternalWalletSignature.
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: Data(repeating: 0x01, count: 32).base64EncodedString(),
            signerAddress: walletKeyPair.accountId
        )
        let manager = makeManager(walletAdapter: adapter)

        let preimageBase64 = Data(repeating: 0x33, count: 32).base64EncodedString()
        do {
            _ = try await manager.signAuthEntry(
                address: walletKeyPair.accountId,
                authEntry: preimageBase64
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains("does not verify"),
                "expected verification-failure message, got: \(error.message)"
            )
        }
    }

    /// The wallet adapter must be unable to produce a signature over an
    /// auth-entry preimage that is itself not valid base64. The verification
    /// step decodes the preimage and rejects it before checking the signature.
    ///
    /// The adapter is configured to echo back a structurally valid (base64)
    /// signature so the failure is attributable to the preimage decode, which
    /// is the first guard inside `verifyExternalWalletSignature`.
    func test_signAuthEntry_walletDelegate_nonBase64Preimage_verificationRejects() async throws {
        let adapter = FakeExternalWalletAdapter()
        let walletKeyPair = try newKeypair()
        adapter.preset(wallet: OZConnectedWallet(
            address: walletKeyPair.accountId,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        // Adapter ignores the (invalid) preimage and returns a base64 signature.
        adapter.nextSignAuthResult = OZSignAuthEntryResult(
            signedAuthEntry: Data(repeating: 0x00, count: 64).base64EncodedString(),
            signerAddress: walletKeyPair.accountId
        )
        let manager = makeManager(walletAdapter: adapter)

        do {
            _ = try await manager.signAuthEntry(
                address: walletKeyPair.accountId,
                authEntry: "not-valid-base64-!!!"
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains("decode base64 auth entry preimage"),
                "expected preimage-decode failure message, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // E.12 — addEd25519FromRawKey invalid verifier address
    // ========================================================================

    /// A verifier address that is not a valid C-strkey must be rejected before
    /// any keypair construction is attempted.
    func test_addEd25519FromRawKey_invalidVerifierAddress_throwsInvalidInput() async throws {
        let manager = makeManager()

        do {
            _ = try await manager.addEd25519FromRawKey(
                secretKeyBytes: ed25519SecretBytes,
                verifierAddress: "not-a-contract-address"
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for bad verifier")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(
                error.message.contains("verifierAddress") || error.message.contains("verifier address"),
                "expected verifier-address validation message, got: \(error.message)"
            )
        }

        // A G-address is a valid strkey but not a contract id; it must also be
        // rejected by the C-strkey check.
        let gAddress = try newKeypair().accountId
        do {
            _ = try await manager.addEd25519FromRawKey(
                secretKeyBytes: ed25519SecretBytes,
                verifierAddress: gAddress
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for G-address verifier")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // E.13 — signEd25519AuthDigest adapter error path
    // ========================================================================

    /// When the adapter claims it can sign but throws during signing, the error
    /// must be wrapped as SigningFailed and reference the verifier address.
    func test_signEd25519AuthDigest_adapterThrows_wrapsAsSigningFailed() async throws {
        struct AdapterFailure: Error, LocalizedError {
            var errorDescription: String? { "hardware unavailable" }
        }
        let adapter = ThrowingEd25519SignerAdapter(error: AdapterFailure())
        let manager = OZExternalSignerManager(
            networkPassphrase: testNetworkPassphrase,
            ed25519Adapter: adapter
        )

        let seed = try Seed(bytes: [UInt8](ed25519SecretBytes))
        let publicKey = Data(KeyPair(seed: seed).publicKey.bytes)
        let authDigest = Data(repeating: 0x42, count: 32)

        do {
            _ = try await manager.signEd25519AuthDigest(
                verifierAddress: ed25519VerifierAlpha,
                publicKey: publicKey,
                authDigest: authDigest
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains("Ed25519 adapter signing failed"),
                "expected adapter-signing-failure message, got: \(error.message)"
            )
            XCTAssertTrue(
                error.message.contains("hardware unavailable"),
                "wrapped message must surface the underlying adapter error text"
            )
        }
    }

    // ========================================================================
    // E.14 — restoreConnections transient reconnect error keeps entry
    // ========================================================================

    /// When `reconnect` throws (treated as transient), the stored entry must be
    /// left intact so a later restore can retry. The throwing entry must not be
    /// purged from storage, and only successfully reconnected wallets appear in
    /// the result.
    func test_restoreConnections_reconnectThrows_keepsStaleEntry() async throws {
        let storage = OZInMemoryWalletConnectionStorage()
        await storage.setItem(
            key: walletStorageKey,
            value: """
            [{"address":"\(validAddress1)","walletId":"alpha","walletName":"Alpha","connectedAt":1700000000000},\
            {"address":"\(validAddress2)","walletId":"beta","walletName":"Beta","connectedAt":1700000001000}]
            """
        )

        let adapter = FakeExternalWalletAdapter()
        // alpha reconnects fine; beta throws a transient error.
        adapter.reconnectResponse["alpha"] = OZConnectedWallet(
            address: validAddress1,
            walletId: "alpha",
            walletName: "Alpha"
        )
        struct TransientReconnectError: Error {}
        adapter.reconnectErrors["beta"] = TransientReconnectError()

        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let restored = try await manager.restoreConnections()
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored[0].walletId, "alpha")

        // Both entries must still be present: alpha was never removed and beta
        // failed transiently, so it is left for a future retry.
        let json = await storage.getItem(key: walletStorageKey)
        XCTAssertNotNil(json)
        XCTAssertTrue(json!.contains(validAddress1), "alpha must remain in storage")
        XCTAssertTrue(
            json!.contains(validAddress2),
            "transiently-failing entry must NOT be purged from storage"
        )
    }

    // ========================================================================
    // E.16 — getStoredWallets storage-read failure returns empty
    // ========================================================================

    /// When the storage backend throws on read, `restoreConnections` (which
    /// reads via getStoredWallets) must treat the failure as an empty store
    /// rather than propagating the error.
    func test_restoreConnections_storageReadThrows_returnsEmpty() async throws {
        struct StorageReadError: Error {}
        let storage = ThrowingWalletConnectionStorage(getError: StorageReadError())
        let adapter = FakeExternalWalletAdapter()
        let manager = makeManager(
            walletAdapter: adapter,
            walletConnectionStorage: storage
        )

        let result = try await manager.restoreConnections()
        XCTAssertTrue(result.isEmpty, "storage read failure must yield an empty restore set")
        XCTAssertEqual(
            adapter.reconnectCallCount,
            0,
            "no reconnect attempts when the store read failed"
        )
    }

    // ========================================================================
    // E.17 — describe(...) message-extraction branches
    // ========================================================================

    /// When the wallet adapter throws a `SmartAccountException`, the wrapping
    /// SigningFailed error must surface the structured `message` of that
    /// exception (the SmartAccountException branch of `describe`).
    func test_signAuthEntry_walletAdapterThrowsSmartAccountException_usesStructuredMessage() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        let innerMessage = "Storage read failed for key: probe"
        adapter.signAuthError = SmartAccountStorageException.readFailed(key: "probe")
        let manager = makeManager(walletAdapter: adapter)

        do {
            _ = try await manager.signAuthEntry(
                address: validAddress1,
                authEntry: "AAAA"
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            XCTAssertTrue(
                error.message.contains(innerMessage),
                "wrapped message must include the SmartAccountException structured message, got: \(error.message)"
            )
        }
    }

    /// When the wallet adapter throws an error whose `localizedDescription` is
    /// empty, `describe` must fall back to `String(describing:)`. The wrapped
    /// SigningFailed message must then include the type-derived description.
    func test_signAuthEntry_walletAdapterThrowsEmptyLocalizedError_usesDescribingFallback() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        adapter.signAuthError = EmptyLocalizedDescriptionError()
        let manager = makeManager(walletAdapter: adapter)

        do {
            _ = try await manager.signAuthEntry(
                address: validAddress1,
                authEntry: "AAAA"
            )
            XCTFail("expected SmartAccountTransactionException.SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertEqual(error.code, .transactionSigningFailed)
            // String(describing:) of the value type yields the type name.
            XCTAssertTrue(
                error.message.contains("EmptyLocalizedDescriptionError"),
                "wrapped message must fall back to String(describing:), got: \(error.message)"
            )
        }
    }
}

// ============================================================================
// OZExternalSignerManager test helpers
// ============================================================================

// ============================================================================
// Ed25519 test doubles
// ============================================================================

/// Minimal stub ``OZExternalEd25519SignerAdapter`` that returns a fixed value for
/// ``canSignFor(verifierAddress:publicKey:)`` and produces a zeroed signature from
/// ``signAuthDigest(authDigest:publicKey:)``. Used to exercise adapter-first
/// precedence without a real hardware-signing backend.
private final class FakeEd25519SignerAdapter: OZExternalEd25519SignerAdapter, @unchecked Sendable {

    private let canSignResult: Bool

    init(canSign: Bool) {
        self.canSignResult = canSign
    }

    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool {
        return canSignResult
    }

    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data {
        return Data(repeating: 0x00, count: 64)
    }
}

/// Stub ``OZExternalEd25519SignerAdapter`` that always claims it can sign and
/// always throws from ``signAuthDigest(authDigest:publicKey:)``. Used to drive
/// the adapter-signing-failure path of ``signEd25519AuthDigest``.
private final class ThrowingEd25519SignerAdapter: OZExternalEd25519SignerAdapter, @unchecked Sendable {

    private let error: Error

    init(error: Error) {
        self.error = error
    }

    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool {
        return true
    }

    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data {
        throw error
    }
}

/// ``OZWalletConnectionStorage`` whose `getItem` always throws. Used to drive
/// the storage-read-failure path of `getStoredWallets`, which must swallow the
/// error and behave as if the store were empty.
private final class ThrowingWalletConnectionStorage: OZWalletConnectionStorage, @unchecked Sendable {

    private let getError: Error

    init(getError: Error) {
        self.getError = getError
    }

    func getItem(key: String) async throws -> String? {
        throw getError
    }

    func setItem(key: String, value: String) async throws {}

    func removeItem(key: String) async throws {}
}

/// Error whose `localizedDescription` is the empty string, used to drive the
/// `String(describing:)` fallback branch of the manager's private `describe`
/// helper.
private struct EmptyLocalizedDescriptionError: Error, LocalizedError {
    var errorDescription: String? { "" }
}

// ============================================================================
// Test doubles
// ============================================================================

/// Recording fake ``OZExternalWalletAdapter`` for unit tests.
///
/// Exposes preset state, queued responses, and call-site recordings so tests
/// can verify interaction patterns (precedence ordering, options propagation,
/// idempotency) without standing up a real wallet integration.
private final class FakeExternalWalletAdapter: OZExternalWalletAdapter, @unchecked Sendable {

    // Synchronisation: tests run sequentially per method by default. Concurrent
    // tests use Swift actor isolation on the manager side; the fake itself is
    // mutated only inside actor-isolated calls.
    private let queue = DispatchQueue(label: "FakeExternalWalletAdapter")

    var nextConnect: OZConnectedWallet?
    var reconnectResponse: [String: OZConnectedWallet?] = [:]
    /// Per-walletId errors thrown by `reconnect`. Takes precedence over
    /// `reconnectResponse` for the same walletId, modeling a transient
    /// reconnect failure (network outage, pop-up blocked, back-end overload).
    var reconnectErrors: [String: Error] = [:]
    var nextSignAuthResult: OZSignAuthEntryResult?
    var signAuthError: Error?

    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    private(set) var disconnectByAddressCalls: [String] = []
    private(set) var reconnectCallCount = 0
    private(set) var signAuthCallCount = 0

    struct SignAuthInvocation {
        let preimageXdr: String
        let options: OZSignAuthEntryOptions?
    }
    private(set) var lastSignAuthInvocation: SignAuthInvocation?

    private var presetWallets: [String: OZConnectedWallet] = [:]

    func preset(wallet: OZConnectedWallet) {
        queue.sync { presetWallets[wallet.address] = wallet }
    }

    func connect() async throws -> OZConnectedWallet? {
        let wallet = queue.sync { () -> OZConnectedWallet? in
            connectCallCount += 1
            return nextConnect
        }
        if let wallet = wallet {
            queue.sync { presetWallets[wallet.address] = wallet }
        }
        return wallet
    }

    func disconnect() async throws {
        // why: production adapters drop their per-wallet state when the kit
        // calls disconnect(); the fake mirrors that contract so `hasSigners()`
        // and `getConnectedWallets()` observe the cleared state immediately.
        queue.sync {
            disconnectCallCount += 1
            presetWallets.removeAll()
        }
    }

    func disconnectByAddress(address: String) async throws {
        queue.sync {
            disconnectByAddressCalls.append(address)
            presetWallets.removeValue(forKey: address)
        }
    }

    func signAuthEntry(
        preimageXdr: String,
        options: OZSignAuthEntryOptions?
    ) async throws -> OZSignAuthEntryResult {
        let snapshot: (Error?, OZSignAuthEntryResult?) = queue.sync {
            signAuthCallCount += 1
            lastSignAuthInvocation = SignAuthInvocation(preimageXdr: preimageXdr, options: options)
            return (signAuthError, nextSignAuthResult)
        }
        if let error = snapshot.0 { throw error }
        if let result = snapshot.1 { return result }
        throw SmartAccountTransactionException.signingFailed(
            reason: "FakeExternalWalletAdapter: no signAuth result configured"
        )
    }

    func getConnectedWallets() -> [OZConnectedWallet] {
        return queue.sync { Array(presetWallets.values) }
    }

    func canSignFor(address: String) -> Bool {
        return queue.sync { presetWallets[address] != nil }
    }

    func getWalletForAddress(address: String) -> OZConnectedWallet? {
        return queue.sync { presetWallets[address] }
    }

    func reconnect(walletId: String) async throws -> OZConnectedWallet? {
        let snapshot: (Error?, OZConnectedWallet??) = queue.sync {
            reconnectCallCount += 1
            return (reconnectErrors[walletId], reconnectResponse[walletId])
        }
        if let error = snapshot.0 { throw error }
        let response: OZConnectedWallet?? = snapshot.1
        guard let resolved = response else { return nil }
        if let wallet = resolved {
            queue.sync { presetWallets[wallet.address] = wallet }
        }
        return resolved
    }
}
