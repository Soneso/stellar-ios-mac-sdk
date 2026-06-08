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
        walletAdapter: OZExternalWalletAdapter? = nil
    ) -> OZExternalSignerManager {
        return OZExternalSignerManager(
            networkPassphrase: testNetworkPassphrase,
            walletAdapter: walletAdapter
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
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        let manager = makeManager(walletAdapter: adapter)

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
        let kp = try newKeypair()
        let address = kp.accountId

        // Register a wallet signer for the same address the keypair claims.
        adapter.preset(wallet: OZConnectedWallet(
            address: address,
            walletId: "wallet-1",
            walletName: "WalletOne"
        ))
        let manager = makeManager(walletAdapter: adapter)
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

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

        let manager = makeManager(walletAdapter: adapter)
        let kp = try newKeypair()
        _ = try await manager.addFromSecret(secretKey: kp.secretSeed!)

        try await manager.removeAll()

        XCTAssertEqual(adapter.disconnectCallCount, 1)
        let hasAfter = await manager.hasSigners()
        XCTAssertFalse(hasAfter)
        let all = await manager.getAll()
        XCTAssertTrue(all.isEmpty, "removeAll() must leave both keypair and wallet bookkeeping empty")
    }

    func test_removeAll_clearsEd25519RegistrationsAlongsideWalletSigners() async throws {
        let adapter = FakeExternalWalletAdapter()
        adapter.preset(wallet: OZConnectedWallet(
            address: validAddress1,
            walletId: "w1",
            walletName: "WalletOne"
        ))
        let manager = makeManager(walletAdapter: adapter)

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
    var nextSignAuthResult: OZSignAuthEntryResult?
    var signAuthError: Error?

    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    private(set) var disconnectByAddressCalls: [String] = []
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
}
