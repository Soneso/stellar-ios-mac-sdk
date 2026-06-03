# Smart Accounts Reference

Passkey-authenticated smart accounts on Stellar using OpenZeppelin Soroban contracts. Core production API: kit setup, wallet creation, connection, transactions, signer types, credentials, the external-signer manager, events, and the indexer.

Standard import:

```swift
import stellarsdk
```

Every smart-account operation runs in an `async` context and most are `throws`. The kit, its operations modules, and several collaborators are reference types; `OZExternalSignerManager` and `InMemoryStorageAdapter` are Swift `actor`s, so calls into them require `await` even for synchronous-looking methods.

Related references:

- [Context Rules, Policies, and Multi-Signer](./smart_accounts_policies.md) — signer management on context rules, context rules, policies, multi-signer ceremonies.
- [WebAuthn Setup](./smart_accounts_webauthn.md) — `WebAuthnProvider` implementations on iOS / macOS, `StorageAdapter` (Keychain / UserDefaults), allow-credential handling.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Kit Lifecycle](#kit-lifecycle)
- [Creating a Wallet](#creating-a-wallet)
- [Connecting to a Wallet](#connecting-to-a-wallet)
- [Standalone Passkey Authentication](#standalone-passkey-authentication)
- [Signer Types](#signer-types)
- [Transactions](#transactions)
- [Credential Management](#credential-management)
- [External Signer Manager](#external-signer-manager)
- [Events](#events)
- [Indexer](#indexer)
- [Deterministic Address Derivation](#deterministic-address-derivation)
- [Deployer Details](#deployer-details)
- [Error Handling](#error-handling)
- [Contract Limits](#contract-limits)

---

## Overview

A smart account is a Soroban contract whose authorization logic lives on-chain. Instead of a classical Stellar account secured by an Ed25519 secret key, the smart-account contract verifies signatures against configured signers and applies context rules and policies.

Supported signer types:

- **WebAuthn passkey** (secp256r1) verified by an on-chain verifier contract.
- **Delegated** Stellar account (`G…`) or contract (`C…`) using Soroban's native `require_auth`.
- **Ed25519** external signer verified by a verifier contract.

Architecture. `OZSmartAccountKit.create(config:)` is the single entry point. The kit exposes the operations modules and per-domain managers as properties:

- `walletOperations` (`OZWalletOperations`)
- `transactionOperations` (`OZTransactionOperations`)
- `signerManager` (`OZSignerManager`)
- `policyManager` (`OZPolicyManager`)
- `contextRuleManagerConcrete` (`OZContextRuleManager`)
- `credentialManagerConcrete` (`OZCredentialManager`)
- `multiSignerManager` (`OZMultiSignerManager`)
- `externalSigners` (`OZExternalSignerManager`, non-optional actor)
- `events` (`SmartAccountEventEmitter`)

The config carries two platform adapters — a `WebAuthnProvider` and a `StorageAdapter` — plus two optional external-signer adapters: `ExternalWalletAdapter` (`externalWallet`) for `G…` custody, and `OZExternalEd25519SignerAdapter` (`externalEd25519Adapter`) for Ed25519 custody. Internally the kit owns a `SorobanServer` (RPC), an optional `OZRelayerClient` (fee-bump), and an optional `OZIndexerClient` (credential lookup).

```swift
// WRONG: kit.walletOperations() — it is a property, not a method
// CORRECT: kit.walletOperations — property access, no parentheses
```

The managers exposed through the protocol surface (`contextRuleManager`, `credentialManager`) are library-internal. Application code uses the concrete-typed accessors:

```swift
// WRONG: kit.credentialManager — internal protocol accessor, not visible to consumers
// CORRECT: kit.credentialManagerConcrete — public, returns the concrete OZCredentialManager
// WRONG: kit.contextRuleManager — internal
// CORRECT: kit.contextRuleManagerConcrete — public
```

---

## Installation

Smart accounts ship in the main `stellarsdk` module. A single import exposes every public symbol on this page:

```swift
import stellarsdk
```

Public types live under two source areas: a protocol-agnostic `core` layer (signer types, errors, `WebAuthnProvider`, utilities) and an OpenZeppelin-specific `oz` layer (kit, managers, config, results). Both are part of the same module — no separate import is required.

---

## Configuration

`OZSmartAccountConfig` is a struct with four required fields and several optional ones. Its initializer is `throws`: it validates inputs and throws `ConfigurationException` on invalid values.

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `rpcUrl` | `String` | Soroban RPC endpoint URL |
| `networkPassphrase` | `String` | Stellar network passphrase (testnet or mainnet) |
| `accountWasmHash` | `String` | SHA-256 hash (**hex**, 64 chars) of the smart-account WASM |
| `webauthnVerifierAddress` | `String` | `C…` address of the deployed WebAuthn verifier contract |

```swift
// WRONG: accountWasmHash: "YWJjMTIzZGVm..." — base64 is NOT accepted
// CORRECT: accountWasmHash must be a 64-character hex string ([0-9a-fA-F]{64}).
//          The initializer throws ConfigurationException.InvalidConfig otherwise.
// WRONG: webauthnVerifierAddress: "GA7Q..." — must be a C-address, not a G-address
// CORRECT: webauthnVerifierAddress: "CB26VN37..." — validated via isValidContractId()
```

```swift
// WRONG: C-address fixture "C0OO1...88..." — base32 alphabet is A-Z + 2-7 only.
//        Digits 0, 1, 8, 9 are illegal; isValidContractId() returns false and the
//        initializer throws ConfigurationException.InvalidConfig with a generic message.
// CORRECT: build C-address placeholders from A-Z + 2-7 exclusively.
```

### Optional fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `deployerKeypair` | `KeyPair?` | `nil` | `nil` means use the default deterministic deployer |
| `sessionExpiryMs` | `Int64` | `604_800_000` (7 days) | Session duration for silent reconnect |
| `signatureExpirationLedgers` | `Int` | `StellarProtocolConstants.ledgersPerHour` (~1 h) | Auth-entry expiration in ledgers. Replay-protection window — consider shortening for high-value transfers. Must be `>= 1`. No client-side upper bound; the host enforces the network `maxEntryTTL` (CAP-0046-11) at submission. |
| `timeoutInSeconds` | `Int` | `30` | Transaction TimeBounds window in seconds (`max_time = now + N`; `0` = no expiry). Must be `>= 0` |
| `relayerUrl` | `String?` | `nil` | Enables a fee-bump relayer |
| `indexerUrl` | `String?` | `nil` | Enables credential-to-contract discovery |
| `webauthnProvider` | `WebAuthnProvider?` | `nil` | Platform passkey implementation |
| `storage` | `StorageAdapter` | `InMemoryStorageAdapter()` | Credential/session persistence. The default is tests-only — see warning below |
| `externalWallet` | `ExternalWalletAdapter?` | `nil` | `G…` wallet adapter (adapter custody) injected into `externalSigners` |
| `externalEd25519Adapter` | `OZExternalEd25519SignerAdapter?` | `nil` | Ed25519 adapter (adapter custody) injected into `externalSigners` |
| `maxContextRuleScanId` | `UInt32` | `50` | Highest context-rule ID to scan when listing |

```swift
// WRONG: sessionExpiryMs: 7 — interpreted as 7 milliseconds, expires almost immediately
// CORRECT: sessionExpiryMs: 7 * 24 * 60 * 60 * 1000 — milliseconds
// WRONG: signatureExpirationLedgers: 3600 — 3600 ledgers is ~5 hours at 5s/ledger
// CORRECT: signatureExpirationLedgers: StellarProtocolConstants.ledgersPerHour — ~1 hour
```

> **The default `InMemoryStorageAdapter` is tests-only.** It holds credentials in process memory; they are lost when the process exits, and the on-chain smart account becomes unreachable. Production apps pass a persistent adapter (`KeychainStorageAdapter` on Apple platforms). See [smart_accounts_webauthn.md](./smart_accounts_webauthn.md).

### Initializer construction (primary path)

The direct throwing memberwise initializer is the idiomatic in-app path. It is the single place that surfaces every optional field — including `relayerUrl`, `indexerUrl`, `externalWallet`, `externalEd25519Adapter`, and `maxContextRuleScanId`. It `throws ConfigurationException` on invalid input.

```swift
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY",
    relayerUrl: "https://relayer.example.com",        // optional: fee-bump relayer
    indexerUrl: "https://indexer.example.com",        // optional: credential discovery
    webauthnProvider: myWebAuthnProvider,             // required for createWallet / transfer
    storage: KeychainStorageAdapter(),                // use persistent storage in production
    externalWallet: myWalletAdapter,                  // optional: G… adapter custody
    externalEd25519Adapter: myEd25519Adapter,         // optional: Ed25519 adapter custody
    maxContextRuleScanId: 50                          // optional: highest context-rule ID to scan
)
```

### Builder alternative

`OZSmartAccountConfig.builder(...)` is a fluent alternative to the direct initializer — same validation, same `throws`. Use it when chaining reads more clearly than a long argument list.

```swift
let config = try OZSmartAccountConfig.builder(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
)
    .sessionExpiryMs(86_400_000)                 // 1 day
    .signatureExpirationLedgers(1440)            // ~2 hours
    .relayerUrl("https://relayer.example.com")
    .indexerUrl("https://indexer.example.com")
    .webauthnProvider(myWebAuthnProvider)
    .storage(KeychainStorageAdapter())
    .externalWallet(myWalletAdapter)
    .build()
```

### createDefaultDeployer

The deterministic default deployer is a static factory:

```swift
// async because it derives a keypair via SHA-256 + Ed25519 seed derivation
let defaultDeployer: KeyPair = try await OZSmartAccountConfig.createDefaultDeployer()
print(defaultDeployer.accountId)   // always the same G-address
```

When `deployerKeypair` is `nil`, this default is used automatically. See [Deployer Details](#deployer-details).

---

## Kit Lifecycle

### Create the kit

`OZSmartAccountKit.create(config:)` is synchronous — it wires collaborators and returns immediately. It does not load sessions or perform any network call. Create the kit **once** for the app's lifetime and keep it alive; do not recreate it per connect. `disconnect()` is the per-session teardown; `close()` is only for final shutdown / replacing the kit.

```swift
let kit = OZSmartAccountKit.create(config: config)
```

### Connection state

The kit exposes three synchronous read-only properties reflecting in-memory state only:

```swift
let connected: Bool      = kit.isConnected
let credId: String?      = kit.credentialId   // Base64URL, no padding
let contractId: String?  = kit.contractId     // C-address (56 chars)
```

```swift
// WRONG: kit.credentialId returns hex — it does NOT; it is Base64URL without padding
// CORRECT: credentialId is Base64URL-encoded (WebAuthn specification)
```

After an app restart `isConnected` is always `false`. Call `kit.walletOperations.connectWallet()` to restore the session from storage.

### Disconnect (per-session teardown)

Clears in-memory connection state and the stored session, then emits `walletDisconnected`. It does **not** tear down the kit: event subscriptions on `events`, the external-signer manager, and every manager stay usable, so the same kit handles the next `connectWallet`. Stored credentials remain so the user can reconnect later. Safe to call when nothing is connected.

```swift
try await kit.disconnect()   // ends the session; kit stays alive for the next connect
```

### Close (final shutdown only)

`close()` is for final shutdown or replacing the kit, not for ending a session. It releases the HTTP resources the kit owns (Soroban RPC, indexer, relayer) and removes every listener on `events`. It does not clear session state — call `disconnect()` first when an active session is open. `close()` is idempotent.

After `close()`, accessing the operations/manager properties (`walletOperations`, `transactionOperations`, `signerManager`, `policyManager`, `contextRuleManagerConcrete`, `credentialManagerConcrete`, `multiSignerManager`) **traps** — the kit nils its strong references to break the retain cycle. `externalSigners` and the config remain valid.

```swift
// WRONG: read kit.transactionOperations after `await kit.close()` — runtime trap
// CORRECT: call close() last; do not touch managers afterward
let kit = OZSmartAccountKit.create(config: config)
do {
    // ... use kit.walletOperations, kit.transactionOperations, etc.
    try await kit.disconnect()
}
await kit.close()   // close() is not throwing; managers must not be accessed after this
```

---

## Creating a Wallet

`walletOperations.createWallet(...)` runs a WebAuthn registration ceremony, derives a deterministic contract address, and optionally deploys the smart-account contract.

> **Account-loss risk — add a backup signer before funding.** A freshly created wallet has exactly one signer: the passkey on the device that ran `createWallet`. If that device is lost, wiped, or the OS resets the authenticator (with iCloud passkey sync unavailable), the account and any funds it holds become permanently inaccessible. Before funding a production wallet, add at least one backup signer — see [Signer Management in smart_accounts_policies.md](./smart_accounts_policies.md).

### Signature

```swift
public func createWallet(
    userName: String = "Smart Account User",
    autoSubmit: Bool = false,
    autoFund: Bool = false,
    nativeTokenContract: String? = nil,
    forceMethod: SubmissionMethod? = nil
) async throws -> CreateWalletResult
```

### CreateWalletResult

```swift
public struct CreateWalletResult {
    public let credentialId: String         // Base64URL, no padding
    public let contractId: String           // deterministic C-address
    public let publicKey: Data              // 65 bytes, uncompressed secp256r1
    public let signedTransactionXdr: String // always populated, even when autoSubmit == false
    public let transactionHash: String?     // nil unless autoSubmit succeeded
    public let nickname: String?
}
```

```swift
// WRONG: wallet.transactionHash is always set — it is nil when autoSubmit == false
// CORRECT: signedTransactionXdr is always set; transactionHash only after a successful autoSubmit
// WRONG: wallet.publicKey.count == 32 — that is Ed25519, not secp256r1
// CORRECT: wallet.publicKey.count == 65 (0x04 prefix + 32-byte X + 32-byte Y)
```

### autoSubmit vs autoFund

| Flag | Meaning |
|------|---------|
| `autoSubmit` | Submit the deploy transaction immediately. When `false`, the result carries `signedTransactionXdr` only — submit later via `deployPendingCredential(...)`. |
| `autoFund` | After deploy, fund the new smart account via Friendbot (**testnet only**). Requires `autoSubmit == true` and a non-`nil` `nativeTokenContract`. |

Production coupling rule: drive `autoFund` from `autoSubmit` (you can only fund what you deploy), and pass `nativeTokenContract` ONLY when funding — `nil` otherwise:

```swift
let autoFund = autoSubmit
let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: autoSubmit,
    autoFund: autoFund,
    nativeTokenContract: autoFund ? nativeTokenContractCAddress : nil
)
```

```swift
// WRONG: createWallet(autoFund: true) — nativeTokenContract is required when autoFund is true
//        Throws ValidationException.InvalidInput before any WebAuthn or network side effect.
// CORRECT:
let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: true,
    autoFund: true,
    nativeTokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
)
```

`autoFund` is **testnet-only**: it routes through the kit's Friendbot helper, which is hard-coded to `https://friendbot.stellar.org`. On mainnet, leave `autoFund: false` and fund the wallet out-of-band.

### Basic example

```swift
// Create and deploy in one call
let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: true
)
print("Contract:    \(wallet.contractId)")
print("Credential:  \(wallet.credentialId)")
print("Deploy hash: \(wallet.transactionHash ?? "<not submitted>")")
```

### Create-then-deploy-later

```swift
// Step 1: register the credential and build a signed deploy transaction without submitting.
let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: false
)
// wallet.signedTransactionXdr is populated; wallet.transactionHash is nil.
// The credential is stored with deploymentStatus == .pending.

// Step 2: submit later via deployPendingCredential, keyed by the stored credential.
let deploy = try await kit.walletOperations.deployPendingCredential(
    credentialId: wallet.credentialId,
    autoSubmit: true
)
print("Deployed: \(deploy.contractId), tx: \(deploy.transactionHash ?? "")")
```

### Create, deploy, and fund on testnet

On a fresh testnet, the default deployer's `G…` account may not exist on-chain, in which case the deploy transaction fails. Fund the deployer via Friendbot first. Skip this when a relayer pays deploy fees, or when a funded custom `deployerKeypair` is supplied.

```swift
let deployer = try await OZSmartAccountConfig.createDefaultDeployer()
let server = SorobanServer(endpoint: config.rpcUrl)
let accountResponse = await server.getAccount(accountId: deployer.accountId)
if case .failure = accountResponse {
    // Default deployer not on-chain yet — fund it via the testnet Friendbot.
    let sdk = StellarSDK.testNet()
    _ = await sdk.accounts.createTestAccount(accountId: deployer.accountId)
    try await Task.sleep(nanoseconds: 5_000_000_000)   // allow propagation
}

let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: true,
    autoFund: true,
    nativeTokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
)
```

### deployPendingCredential

```swift
public func deployPendingCredential(
    credentialId: String,
    autoSubmit: Bool = true,
    autoFund: Bool = false,
    nativeTokenContract: String? = nil,
    forceMethod: SubmissionMethod? = nil
) async throws -> DeployPendingResult

public struct DeployPendingResult {
    public let contractId: String
    public let signedTransactionXdr: String
    public let transactionHash: String?   // nil when autoSubmit == false
}
```

The credential must already exist in storage with a valid `publicKey` and `contractId` (created by a prior `createWallet(autoSubmit: false)`). After a successful deploy the transitional credential is deleted from storage.

### Failures

`createWallet` and `deployPendingCredential` throw from `WebAuthnException`, `ValidationException`, `TransactionException`, `CredentialException`, or `StorageException`. See [Error Handling](#error-handling).

### WebAuthn provider required

```swift
// WRONG: call createWallet(...) without setting webauthnProvider in the config
//        Throws WebAuthnException.NotSupported.
// CORRECT: set config.webauthnProvider to a platform implementation first.
```

`webauthnProvider` is required for `createWallet`, `authenticatePasskey`, `connectWallet(options:)` with `prompt: true` or `fresh: true`, and any passkey-signing flow. A silent `connectWallet()` that restores a live session does NOT need it. See [smart_accounts_webauthn.md](./smart_accounts_webauthn.md).

---

## Connecting to a Wallet

`walletOperations.connectWallet(options:)` restores a session, prompts WebAuthn, or connects directly with known credentials. It supports the two-phase app-launch pattern (silent restore, then user-initiated connect).

### Signature

```swift
public func connectWallet(
    options: ConnectWalletOptions = ConnectWalletOptions()
) async throws -> ConnectWalletResult?
```

### ConnectWalletOptions

`ConnectWalletOptions` is a top-level public struct.

```swift
public struct ConnectWalletOptions {
    public let credentialId: String?   // Base64URL
    public let contractId: String?     // C-address; must be paired with credentialId
    public let fresh: Bool             // skip session, always WebAuthn
    public let prompt: Bool            // restore session, else WebAuthn

    public init(
        credentialId: String? = nil,
        contractId: String? = nil,
        fresh: Bool = false,
        prompt: Bool = false
    )
}
```

### Decision matrix

| Options | Behavior | Returns |
|---------|----------|---------|
| (default) | Silent session restore | Session result or `nil` |
| `prompt: true` | Restore session, else WebAuthn | Non-`nil` on success |
| `fresh: true` | Skip session, always WebAuthn (takes priority over `prompt`) | Non-`nil` on success |
| `credentialId` [+ `contractId`] | Direct connect, skip session and WebAuthn | Non-`nil` on success; throws `WalletException.NotFound` if the contract does not exist on-chain |

### ConnectWalletResult

A two-case enum. `.connected` means a single contract was resolved (the kit's connected state is set and a session is saved). `.ambiguous` means the indexer reported multiple contracts where the passkey is registered as a signer — the connected state is NOT set; the caller must let the user pick and reconnect with the chosen `contractId`.

```swift
public enum ConnectWalletResult {
    case connected(credentialId: String, contractId: String, restoredFromSession: Bool)
    case ambiguous(credentialId: String, candidates: [String])   // contract addresses

    public var credentialId: String { get }   // carried by both arms
}
```

`.ambiguous` is by construction unreachable when an explicit `contractId` is supplied — that path bypasses the cascade and always returns `.connected`.

### Phase 1: silent restore at app launch

```swift
let kit = OZSmartAccountKit.create(config: config)

switch try await kit.walletOperations.connectWallet() {
case nil:
    // No saved session — show a Connect button.
    break
case .connected(_, let contractId, _):
    print("Reconnected to \(contractId)")
case .ambiguous:
    // Unreachable for silent restore: the saved session supplies an explicit
    // contractId, which bypasses the cascade.
    break
}
```

### Phase 2: user taps Connect

```swift
let result = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(prompt: true)
)
switch result {
case nil:
    break   // unreachable when prompt == true
case .connected(_, let contractId, _):
    print("Connected: \(contractId)")
case .ambiguous(let credentialId, let candidates):
    // Show a picker, then reconnect with the chosen contract.
    let chosen = candidates[0]   // user's selection
    _ = try await kit.walletOperations.connectWallet(
        options: ConnectWalletOptions(credentialId: credentialId, contractId: chosen)
    )
}
```

### Force fresh authentication

Required for sensitive operations (for example before changing signers):

```swift
let fresh = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(fresh: true)
)
```

### Direct connect with known credentials

No WebAuthn ceremony, no session check — useful after a user picks a wallet from the indexer.

```swift
let direct = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(
        credentialId: "abc123_...",   // Base64URL, from the indexer
        contractId: "CABC..."
    )
)
// Always returns .connected on success; throws WalletException.NotFound if the
// contract does not exist on-chain.
```

### Contract lookup cascade

When `credentialId` is provided (or after a WebAuthn prompt) without an explicit `contractId`, the SDK resolves the contract address in this order:

1. **Local storage.** A storage hit means the deployment is `pending` or `failed`. A `failed` entry throws `WalletException.NotFound` with a message pointing to `deployPendingCredential()` for retry. A `pending` entry's stored `contractId` is used directly.
2. **Deterministic address derivation** from the configured deployer. The derived address is verified on-chain. If no contract exists there, the cascade falls through to the indexer (the passkey was added as a signer to an existing wallet rather than deploying its own under this deployer).
3. **Indexer fallback** (when configured). Looks up contracts where the passkey is registered as a signer:
   - 0 contracts → throws `WalletException.NotFound`.
   - 1 contract → verified on-chain, returns `.connected`.
   - N > 1 contracts → returns `.ambiguous(credentialId, candidates)`; connection state is NOT set.

When an explicit `contractId` is supplied (direct connect or session restore), the cascade is bypassed and only the on-chain verification runs.

---

## Standalone Passkey Authentication

`authenticatePasskey(...)` runs a WebAuthn ceremony without connecting the kit. Use it when a signature is needed first and contracts are discovered afterward (for example via the indexer), or for multi-signer authorization.

```swift
public func authenticatePasskey(
    challenge: Data? = nil,        // nil → a fresh 32-byte random challenge is generated
    credentialIds: [String]? = nil // optional allow-list, Base64URL-encoded
) async throws -> AuthenticatePasskeyResult

public struct AuthenticatePasskeyResult {
    public let credentialId: String          // Base64URL, no padding
    public let signature: OZWebAuthnSignature // normalized (DER → compact r||s, low-S)
    public let publicKey: Data               // 65 bytes if in local storage; empty Data otherwise
}
```

Typical flow:

```swift
// 1. Authenticate.
let auth = try await kit.walletOperations.authenticatePasskey()

// 2. Look up contracts via the indexer.
if let indexer = kit.indexerClient {
    let response = try await indexer.lookupByCredentialId(credentialId: auth.credentialId)
    if let first = response.contracts.first {
        // 3. Connect to the chosen contract.
        _ = try await kit.walletOperations.connectWallet(
            options: ConnectWalletOptions(
                credentialId: auth.credentialId,
                contractId: first.contractId
            )
        )
    }
}
```

---

## Signer Types

Smart-account signers conform to the `OZSmartAccountSigner` protocol:

```swift
public protocol OZSmartAccountSigner: Sendable {
    func toScVal() throws -> SCValXDR
    var uniqueKey: String { get }   // "delegated:<address>" or "external:<verifier>:<keyDataHex>"
}
```

Two concrete types implement it. This section documents the signer **types**; using them in context rules and multi-signer ceremonies is covered in [smart_accounts_policies.md](./smart_accounts_policies.md).

### OZDelegatedSigner

A Stellar address (`G…` or `C…`) that authorizes via Soroban's native `require_auth`. No verifier contract.

```swift
public struct OZDelegatedSigner: OZSmartAccountSigner, Equatable, Hashable {
    public let address: String
    public init(address: String) throws   // throws ValidationException.InvalidAddress on bad strkey
}
```

```swift
let accountSigner  = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
let contractSigner = try OZDelegatedSigner(address: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC")
```

On-chain SCVal: `Vec([Symbol("Delegated"), Address(address)])`.

### OZExternalSigner

A verifier contract plus key-data bytes. Used for passkeys and Ed25519 keys.

```swift
public struct OZExternalSigner: OZSmartAccountSigner, Equatable, Hashable {
    public let verifierAddress: String   // must be a C-address
    public let keyData: Data
    public init(verifierAddress: String, keyData: Data) throws
}
```

On-chain SCVal: `Vec([Symbol("External"), Address(verifierAddress), Bytes(keyData)])`.

Do not construct `OZExternalSigner` directly for passkeys — use the `webAuthn` factory, which assembles `keyData` correctly.

### OZExternalSigner.webAuthn (factory)

```swift
let signer = try OZExternalSigner.webAuthn(
    verifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY",
    publicKey: secp256r1PublicKey,   // 65 bytes, uncompressed (0x04 prefix + X + Y)
    credentialId: credentialIdBytes  // raw bytes, NOT Base64URL-encoded
)
```

```swift
// WRONG: OZExternalSigner.WebAuthn(...) — no such PascalCase API
// CORRECT: OZExternalSigner.webAuthn(...) — camelCase static factory
// WRONG: publicKey.count == 33 — that is the compressed format, rejected
// CORRECT: publicKey.count == 65 and publicKey[0] == 0x04
// WRONG: credentialId: Data("abc123_...".utf8) — pass the raw credential bytes
// CORRECT: credentialId is the raw Data returned by the WebAuthn ceremony
```

The factory validates the 65-byte size and `0x04` prefix; the stored `keyData` is `publicKey || credentialId`.

### OZExternalSigner.ed25519 (factory)

```swift
let signer = try OZExternalSigner.ed25519(
    verifierAddress: "CDEF...",   // Ed25519 verifier contract
    publicKey: ed25519PublicKey   // 32 bytes
)
```

The factory validates `publicKey.count == 32`. No credential-ID suffix — `keyData` is the 32-byte public key.

### OZSmartAccountBuilders (factory + inspection helpers)

`OZSmartAccountBuilders` offers the same factories with descriptive names plus inspection helpers:

```swift
let delegated = try OZSmartAccountBuilders.createDelegatedSigner(publicKey: "GA7Q...")
let passkey   = try OZSmartAccountBuilders.createWebAuthnSigner(
    webauthnVerifierAddress: "CB26VN37...",
    publicKey: publicKey65,
    credentialId: credentialIdBytes
)
let ed25519Signer = try OZSmartAccountBuilders.createEd25519Signer(
    ed25519VerifierAddress: "CDEF...",
    publicKey: publicKey32
)

// Inspection
let isPasskey: Bool   = OZSmartAccountBuilders.isExternalSigner(signer: passkey)
let credId: Data?     = OZSmartAccountBuilders.getCredentialIdFromSigner(signer: passkey)
let credIdStr: String? = OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: passkey) // Base64URL
let typeLabel: String = OZSmartAccountBuilders.describeSignerType(signer: passkey)               // "Passkey (WebAuthn)"

// Matching and dedup
let matches = OZSmartAccountBuilders.signerMatchesCredentialId(signer: passkey, credentialId: "base64url-id")
let same    = OZSmartAccountBuilders.signersEqual(passkey, otherSigner)
let unique  = OZSmartAccountBuilders.collectUniqueSigners(signers: signerList)
```

### Signer constants

```swift
SmartAccountConstants.ed25519PublicKeySize     // 32
SmartAccountConstants.ed25519SecretSeedSize    // 32
SmartAccountConstants.ed25519SignatureSize     // 64
SmartAccountConstants.secp256r1PublicKeySize   // 65
SmartAccountConstants.uncompressedPubkeyPrefix // 0x04
```

---

## Transactions

`kit.transactionOperations` handles token transfers and arbitrary contract calls for the connected smart account. Each state-changing operation runs a WebAuthn ceremony to sign authorization entries.

### TransactionResult

```swift
public struct TransactionResult {
    public let success: Bool      // true only when confirmed on-chain
    public let hash: String?      // nil only when submission failed before a hash was assigned
    public let ledger: UInt32?    // present after successful confirmation polling
    public let error: String?     // nil on success
}
```

### transfer

SEP-41-compatible token transfer (XLM via the SAC, or any Soroban token). The decimal amount is converted to stroops internally.

```swift
public func transfer(
    tokenContract: String,   // C-address of the token contract
    recipient: String,       // G-address or C-address
    amount: String,          // decimal string, up to 7 places
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
let result = try await kit.transactionOperations.transfer(
    tokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC", // native SAC
    recipient: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
    amount: "10.5"
)
if result.success {
    print("Hash: \(result.hash ?? ""), ledger: \(result.ledger.map(String.init) ?? "")")
} else {
    print("Failed: \(result.error ?? "")")
}
```

```swift
// WRONG: amount: 10 — must be a String
// CORRECT: amount: "10"
// WRONG: amount: "10500000" — that is 10.5 million XLM, not 10.5 XLM
// CORRECT: amount: "10.5" — the SDK converts to stroops automatically
// WRONG: transfer to the smart account's own contractId — throws ValidationException
// CORRECT: recipient must differ from the connected smart account address
```

Throws `WalletException.NotConnected` when no wallet is connected, `ValidationException` for a bad recipient or amount, `TransactionException.*` for simulation/submission failures, and `WebAuthnException.*` on a cancelled biometric prompt.

### contractCall

Calls an arbitrary function on an external contract, authorized by the smart account via `require_auth` (context-rule type `CallContract(target)`).

```swift
public func contractCall(
    target: String,                  // C-address of the target contract
    targetFn: String,                // function name
    targetArgs: [SCValXDR] = [],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Example — approve a token spender:

```swift
let from    = try SCAddressXDR(contractId: smartAccountId)
let spender = try SCAddressXDR(contractId: spenderContract)
// 100 XLM in stroops as Int64 (1 XLM = 10_000_000 stroops).
let stroops = 100 * StellarProtocolConstants.stroopsPerXlm

let args: [SCValXDR] = [
    .address(from),
    .address(spender),
    .i128(stroops: stroops),   // amount as i128 (Int64 stroops)
    .u32(720)                  // expiration ledger
]

let result = try await kit.transactionOperations.contractCall(
    target: tokenContract,
    targetFn: "approve",
    targetArgs: args
)
```

`ResolveContextRuleIds` is `@Sendable (SorobanAuthorizationEntryXDR, Int) async throws -> [UInt32]`. It overrides automatic context-rule resolution for a single auth entry — see [smart_accounts_policies.md](./smart_accounts_policies.md).

### executeAndSubmit

Like `contractCall`, but routes through the smart-account contract's `execute(target, target_fn, target_args)` entry point. Use it when the target contract should see the smart account as the invoker via `execute` rather than via `require_auth`.

```swift
public func executeAndSubmit(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

### submit (low-level escape hatch)

Escape hatch for arbitrary host functions. `transfer`, `contractCall`, and `executeAndSubmit` all funnel into `submit` after building an `InvokeContract` host function. Use `submit` directly when the host function is not `InvokeContract` (for example `CreateContract` or `UploadContractWasm`) or when you need hand-crafted auth entries.

```swift
public func submit(
    hostFunction: HostFunctionXDR,
    auth: [SorobanAuthorizationEntryXDR],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

The SDK simulates the host function, signs auth entries whose address matches the connected smart account, re-simulates (WebAuthn signatures are larger than the simulation placeholders), and submits. Pass an empty `auth` array in most cases — simulation discovers the entries. Pre-supplied entries are forwarded unchanged.

```swift
// WRONG: kit.transactionOperations.submit(hostFunction: hf) — auth is a required parameter
// CORRECT: pass [] when you want simulation to discover the entries
let result = try await kit.transactionOperations.submit(
    hostFunction: myHostFunctionXdr,   // e.g. HostFunctionXDR.createContract(...) — see xdr.md
    auth: []
)
```

### fundWallet

Post-deploy testnet top-up helper. Generates a throwaway keypair, funds it via Friendbot, and transfers the balance (minus `OZConstants.friendbotReserveXlm`, currently 5 XLM) to the connected smart account via the native SAC. Works only on testnet — mainnet has no Friendbot.

```swift
public func fundWallet(
    nativeTokenContract: String,   // XLM SAC C-address
    forceMethod: SubmissionMethod? = nil
) async throws -> String           // funded amount as a decimal XLM string
```

```swift
// WRONG: kit.transactionOperations.fundWallet() — nativeTokenContract is required
// CORRECT:
let amount = try await kit.transactionOperations.fundWallet(
    nativeTokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
)
print("Funded \(amount) XLM")
```

Use this after `createWallet(autoSubmit: true, autoFund: false)` to defer funding, or to top up an existing wallet during development. `createWallet(autoFund: true, nativeTokenContract:)` calls it internally. Throws `WalletException.NotConnected`, `ValidationException.InvalidAddress`, or `TransactionException.*`.

### SubmissionMethod

The kit auto-selects: relayer if `relayerUrl` is configured, otherwise direct Soroban RPC. Override with `forceMethod`.

```swift
public enum SubmissionMethod {
    case relayer
    case rpc
}

// Force direct RPC even if a relayer is configured.
let result = try await kit.transactionOperations.transfer(
    tokenContract: tokenId,
    recipient: to,
    amount: "10",
    forceMethod: .rpc
)
// Forcing .relayer with no relayer configured throws TransactionException.SubmissionFailed.
```

### Relayer modes

When a relayer is configured, the SDK auto-selects the submission mode from the simulated auth entries; it is not caller-controllable.

**Trust model.** The relayer receives the signed envelope (or host function + auth entries) and submits on the user's behalf. It cannot steal funds — signatures are bound to the auth payload. It can see every transaction in plaintext, censor/drop/delay submissions, and reorder them. For mainnet: use a relayer you operate or trust contractually, require HTTPS (pin where possible), and prefer direct RPC (`forceMethod: .rpc`) for high-value transfers when a delegated signer can pay the fee directly.

### Transaction lifecycle

Each `transfer` / `contractCall` / `executeAndSubmit` call simulates, prompts WebAuthn once per matching auth entry (usually one per transaction), re-simulates, submits, then polls for confirmation. Relayer vs RPC is auto-selected; override with `forceMethod`.

---

## Credential Management

`kit.credentialManagerConcrete` manages local credential storage. Credentials are WebAuthn passkeys with metadata about deployment state and usage.

### StoredCredential

```swift
public struct StoredCredential {
    public let credentialId: String                       // Base64URL, no padding
    public let publicKey: Data                            // 65 bytes (uncompressed secp256r1)
    public let contractId: String?
    public let deploymentStatus: CredentialDeploymentStatus // default .pending
    public let deploymentError: String?
    public let createdAt: Int64                           // ms since epoch
    public let lastUsedAt: Int64?
    public let nickname: String?
    public let isPrimary: Bool
    public let transports: [String]?                      // "usb" | "nfc" | "ble" | "internal" | "hybrid"
    public let deviceType: String?                        // "singleDevice" | "multiDevice"
    public let backedUp: Bool?
}

public enum CredentialDeploymentStatus: String {
    case pending = "PENDING"
    case failed = "FAILED"
    // No `success` arm: a credential is deleted from storage after a successful deploy.
}
```

### Credential lifecycle

```
pending --[deploy success]--------------> deleted from storage
pending --[deploy failure]--------------> failed (deploymentError set)
pending --[sync discovers contract]-----> deleted from storage
failed  --[deleteCredential]------------> deleted from storage
```

After deployment succeeds, the credential is removed from storage. Reconnection is via sessions (short-term) or the indexer (long-term); the public key stays on-chain as part of the context-rule signers.

### Common operations

```swift
let cm = kit.credentialManagerConcrete

// Save or upsert (overwrites existing by ID; no deployment metadata captured).
let cred = try await cm.saveCredential(
    credentialId: "abc123_...",
    publicKey: publicKey65,
    nickname: "MacBook Touch ID",
    contractId: "CABC..."
)

// Lookup
let found: StoredCredential?       = try await cm.getCredential(credentialId: "abc123_...")
let all: [StoredCredential]        = try await cm.getAllCredentials()
let byContract: [StoredCredential] = try await cm.getCredentialsByContract(contractId: "CABC...")
let forCurrent: [StoredCredential] = try await cm.getForConnectedWallet()
let pending: [StoredCredential]    = try await cm.getPendingCredentials()

// Update
try await cm.updateNickname(credentialId: "abc123_...", nickname: "MacBook Pro Touch ID")

// Delete (refuses if the contract is already deployed on-chain)
try await cm.deleteCredential(credentialId: "abc123_...")

// Bulk clear (irreversible)
try await cm.clearAll()
```

`deleteCredential` first runs `sync` to confirm the contract is not on-chain. When the wallet already exists on-chain it throws `CredentialException.Invalid` because the local entry is no longer authoritative.

### Syncing with on-chain state

`sync` and `syncAll` reconcile local storage against the chain — essential for apps that may be killed mid-deployment.

```swift
let deployed: Bool = try await cm.sync(credentialId: "abc123_...")
// true  -> contract exists on-chain; credential deleted from storage
// false -> not yet on-chain; credential remains

let summary: SyncResult = try await cm.syncAll()
print("Deployed: \(summary.deployed), pending: \(summary.pending), failed: \(summary.failed)")

public struct SyncResult {
    public let deployed: Int
    public let pending: Int
    public let failed: Int
}
```

An RPC failure during `sync` is treated as "not deployed" (returns `false`) and emits a `credentialSyncFailed` event rather than throwing.

### Storage adapter

`config.storage` defaults to `InMemoryStorageAdapter` (non-persistent, tests-only). Production apps supply a `StorageAdapter`:

```swift
public protocol StorageAdapter: AnyObject, Sendable {
    func save(credential: StoredCredential) async throws
    func get(credentialId: String) async throws -> StoredCredential?
    func getByContract(contractId: String) async throws -> [StoredCredential]
    func getAll() async throws -> [StoredCredential]
    func delete(credentialId: String) async throws
    func update(credentialId: String, updates: StoredCredentialUpdate) async throws
    func clear() async throws
    func saveSession(_ session: StoredSession) async throws
    func getSession() async throws -> StoredSession?
    func clearSession() async throws
}
```

`KeychainStorageAdapter` (encrypted, Apple Keychain) and `UserDefaultsStorageAdapter` (non-sensitive metadata) ship with the SDK. See [smart_accounts_webauthn.md](./smart_accounts_webauthn.md) for adapter selection.

---

## External Signer Manager

`OZExternalSignerManager` is the kit-owned front door for all external (non-passkey) signers, accessed as `kit.externalSigners` (always non-`nil`). The multi-signer pipeline routes every `G…`-address and Ed25519 signing through it. It is a Swift `actor`, so every call from outside requires `await` — including the synchronous-looking ones.

```swift
// WRONG: kit.externalSignerManager — no such property
// CORRECT: kit.externalSigners — non-optional, kit-owned actor
let mgr = kit.externalSigners
```

It handles two signer kinds, each with two custody models:

| Signer kind | In-memory custody (SDK holds the key) | Adapter custody (SDK never sees the key) |
|---|---|---|
| Wallet / `G…` | `kit.externalSigners.addFromSecret(secretKey:)` at runtime | `config.externalWallet` (`ExternalWalletAdapter`) at kit construction |
| Ed25519 external | `kit.externalSigners.addEd25519FromRawKey(secretKeyBytes:verifierAddress:)` at runtime | `config.externalEd25519Adapter` (`OZExternalEd25519SignerAdapter`) at kit construction |

Resolution precedence differs by kind: a wallet (`G…`) slot resolves to the in-memory keypair first, then the adapter; an Ed25519 slot resolves to the adapter first, then the in-memory key.

### Two Ed25519 custody paths (alternatives)

For Ed25519, in-memory and adapter custody are **alternatives** for one slot, not layers to combine:

- **In-memory** — `addEd25519FromRawKey(secretKeyBytes:verifierAddress:)`. The raw seed lives in the manager's own registry; resolved from that registry.
- **Adapter** — `config.externalEd25519Adapter`. The seed never enters process memory; the SDK consults the adapter **first** (`canSignEd25519For` / `signEd25519AuthDigest` check the adapter before the in-memory registry).

This precedence ties into cleanup below: clearing the in-memory registry never touches the adapter — adapter custody is cleared separately.

### Multi-signer signer cleanup (runtime footgun — no compile-time signal)

Any in-memory signing material you register on `kit.externalSigners` for a multi-signer submit (`addFromSecret` for delegated `G…` keys, `addEd25519FromRawKey` for Ed25519) MUST be cleared on BOTH success AND failure, so raw key material never persists across operations. Wrap the submit in do/catch (or `defer`) and clear on every path.

The straightforward cleanup is `removeAll()`: it clears the in-memory delegated and Ed25519 keypair registries, disconnects every connected wallet adapter, and clears persisted wallet connections — one call covering everything you registered.

```swift
// Register in-memory material, submit inside do/catch, clear on BOTH paths.
_ = try await kit.externalSigners.addFromSecret(secretKey: delegatedSecretSeed) // S-strkey
_ = try await kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSeedBytes,        // exactly 32 bytes
    verifierAddress: ed25519Verifier     // C-address
)
do {
    let result = try await kit.transactionOperations.submit(hostFunction: hf, auth: [])
    // ... use result ...
} catch {
    // handle / rethrow as needed
}
// Clear registered key material whether the submit succeeded or threw.
try? await kit.externalSigners.removeAll()
```

> `removeAll()` does NOT clear an Ed25519 adapter supplied via `config.externalEd25519Adapter` — adapter custody is immutable, set at construction. If you used adapter custody, clear the adapter's own key state separately (e.g. its `clearAll()`).

When to prefer TARGETED removal instead — `remove(address:)` per delegated `G…` address and `removeEd25519(verifierAddress:publicKey:)` per Ed25519 identity: only when you must keep a live wallet-connector session alive across operations. `removeAll()` disconnects every wallet adapter, so if you registered an in-memory keypair while a wallet is also connected and you want that wallet to stay connected, remove just the keys you registered:

```swift
// removeEd25519 has no throws, but OZExternalSignerManager is an actor, so the call still needs await.
try? await kit.externalSigners.remove(address: gAddress)
await kit.externalSigners.removeEd25519(verifierAddress: ed25519Verifier, publicKey: ed25519PublicKey)
```

> `removeAll()` is also the teardown counterpart to `restoreConnections()` for a full logout / reset of the external-signer manager. It is distinct from `kit.disconnect()`, which only clears the connection session and does NOT touch `externalSigners`.

> Removed / never-existed symbols — these appear ONLY as traps, not as live API:
> ```swift
> // WRONG: config.externalSignerManager — there is no such config field
> // WRONG: kit.externalSignerManager / kit.externalWallet — no such kit accessors
> // WRONG: kit.externalSigners.setEd25519Adapter(...) — no such method
> // WRONG: kit.externalSigners.ed25519Adapter = adapter — the adapter is an immutable init param
> // CORRECT: supply the Ed25519 adapter via config.externalEd25519Adapter at kit construction;
> //          register in-memory keys at runtime via addEd25519FromRawKey(...).
> ```

The four registration paths:

```swift
let config = try OZSmartAccountConfig.builder(
    rpcUrl: rpcUrl,
    networkPassphrase: networkPassphrase,
    accountWasmHash: wasmHash,
    webauthnVerifierAddress: verifier
)
    .externalWallet(myWalletAdapter)            // wallet adapter custody
    .externalEd25519Adapter(myHardwareAdapter)  // Ed25519 adapter custody
    .build()
let kit = OZSmartAccountKit.create(config: config)

// Wallet in-memory custody: register a secret seed at runtime.
let gAddress = try await kit.externalSigners.addFromSecret(
    secretKey: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34REYB6WBMG7CKKFJHYAEGQ"
)

// Ed25519 in-memory custody: register a raw 32-byte seed at runtime.
let ed25519PublicKey = try await kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSeedBytes,   // exactly 32 bytes
    verifierAddress: "CDEF..."      // Ed25519 verifier contract C-address
)
```

### Wallet-side API

```swift
public actor OZExternalSignerManager {
    public var hasWalletAdapter: Bool { get }   // actor-isolated; access with await

    public func addFromSecret(secretKey: String) async throws -> String   // returns the derived G-address
    public func addFromWallet() async throws -> ConnectedWallet?          // nil if the user cancelled
    public func canSignFor(address: String) async -> Bool
    public func get(address: String) async -> ExternalSignerInfo?
    public func getAll() async -> [ExternalSignerInfo]
    public func hasSigners() async -> Bool
    public func signAuthEntry(address: String, authEntry: String) async throws -> SignAuthEntryResult
    public func remove(address: String) async throws
    public func removeAll() async throws
    public func restoreConnections() async throws -> [ConnectedWallet]
}
```

```swift
// WRONG: addFromSecret(secretKey: "GA7Q...") — secret seeds are S-addresses, not G-addresses
// CORRECT: addFromSecret(secretKey: "S...") — a Stellar secret seed
```

`addFromSecret` keypairs are held in memory only and never persisted. A keypair signer takes precedence over a wallet signer with the same `G…` address. `canSignFor` checks keypair signers first, then the wallet adapter. `getAll` lists keypair signers first, then wallet signers deduplicated by address (keypair wins). Throws `SignerException.Invalid` on a bad seed.

`signAuthEntry` signs a Base64-encoded `HashIDPreimage::SorobanAuthorization` XDR: keypair signers SHA-256-hash the preimage and Ed25519-sign locally; wallet signers delegate to the adapter.

```swift
public struct SignAuthEntryResult {
    public let signedAuthEntry: String   // Base64 raw 64-byte Ed25519 signature
    public let signerAddress: String?
}
```

```swift
// WRONG: authEntry is hex — it must be Base64
// CORRECT: authEntry is the Base64 of the HashIDPreimage::SorobanAuthorization XDR
// WRONG: signedAuthEntry is DER — it is a raw 64-byte Ed25519 signature, Base64-encoded
```

### ExternalSignerInfo and ExternalSignerType

```swift
public struct ExternalSignerInfo {
    public let address: String           // G-address
    public let type: ExternalSignerType
    public let walletName: String?       // only for .wallet
    public let walletId: String?         // only for .wallet
}

public enum ExternalSignerType: String {
    case keypair = "KEYPAIR"
    case wallet = "WALLET"
}
```

### addFromWallet and restoreConnections

`addFromWallet` prompts the user through the configured `ExternalWalletAdapter`. It throws `ConfigurationException.MissingConfig` when no adapter is configured.

`restoreConnections` reads persisted wallet-connection metadata and reconnects each entry via the adapter. Call it once at app launch — wallet signers are invisible to the adapter's `canSignFor` until restore runs.

```swift
// WRONG: call restoreConnections() lazily on the first multi-signer op
// CORRECT: call it once at app launch
_ = try await kit.externalSigners.restoreConnections()
```

The kit-owned manager uses an in-memory wallet-connection store. To persist external-wallet connections across launches, construct a standalone manager with a platform `WalletConnectionStorage` (see [Standalone construction](#standalone-construction-advanced)).

### ExternalWalletAdapter (consumer-implemented `G…` custody)

`config.externalWallet` takes an object you implement to bridge a real `G…` wallet (Freighter, LOBSTR, a WalletConnect bridge, etc.) into `kit.externalSigners`. The manager-level `signAuthEntry(address:authEntry:)` above is the SDK-side entry point; this protocol is the adapter side you write. `connect`/`signAuthEntry` are the only required members — the rest have default implementations.

```swift
public protocol ExternalWalletAdapter: AnyObject, Sendable {
    func connect() async throws -> ConnectedWallet?            // nil if the user cancelled
    func disconnect() async throws
    func disconnectByAddress(address: String) async throws     // default: no-op
    func signAuthEntry(
        preimageXdr: String,                                   // Base64 HashIDPreimage XDR
        options: SignAuthEntryOptions?                         // options.address selects the signer
    ) async throws -> SignAuthEntryResult                       // .signedAuthEntry = Base64 raw 64-byte Ed25519 sig
    func getConnectedWallets() -> [ConnectedWallet]
    func canSignFor(address: String) -> Bool
    func getWalletForAddress(address: String) -> ConnectedWallet?  // default: nil
    func reconnect(walletId: String) async throws -> ConnectedWallet?  // default: nil
}

public struct ConnectedWallet: Sendable, Equatable, Hashable {
    public let address: String      // G-address
    public let walletId: String     // e.g. "freighter"; used by reconnect(walletId:)
    public let walletName: String   // display name
    public init(address: String, walletId: String, walletName: String)
}

public struct SignAuthEntryOptions: Sendable, Equatable, Hashable {
    public let networkPassphrase: String?
    public let address: String?     // which signer to use when several are connected
}
```

Inside `signAuthEntry`: Base64-decode `preimageXdr`, SHA-256 it, Ed25519-sign the 32-byte hash, and return the 64-byte raw signature as Base64 in `SignAuthEntryResult(signedAuthEntry:signerAddress:)`. The SDK handles auth-entry construction and signature wrapping; the adapter only produces the raw signature.

```swift
// WRONG: return a DER signature, or sign the preimage bytes directly
// CORRECT: SHA-256(preimage) → Ed25519-sign the 32-byte digest → Base64 of the 64-byte raw sig
// WRONG: ignore options?.address when several wallets are connected
// CORRECT: route to the wallet whose address == options?.address; throw if none matches
```

### Ed25519 API

Ed25519 external signers are keyed by the tuple `(verifierAddress, publicKey)`, matching the on-chain `External(verifier, keyData)` slot. Resolution is adapter-first: `config.externalEd25519Adapter` is consulted before the in-memory registry.

```swift
// Register an in-memory key (raw 32-byte seed, NOT an S-strkey). Sync throws, but actor → await.
public func addEd25519FromRawKey(secretKeyBytes: Data, verifierAddress: String) throws -> Data

// Pure getter — sync, but actor-isolated, so callers await it.
public func canSignEd25519For(verifierAddress: String, publicKey: Data) -> Bool

// 64-byte raw Ed25519 signature over the 32-byte authDigest (adapter-first).
public func signEd25519AuthDigest(verifierAddress: String, publicKey: Data, authDigest: Data) async throws -> Data

// Removes the in-memory key for the slot. No-op if absent; does not affect the adapter.
public func removeEd25519(verifierAddress: String, publicKey: Data)
```

```swift
// WRONG: addEd25519FromRawKey is async — it is declared sync throws.
//        But OZExternalSignerManager is an actor, so calling it still requires await:
// WRONG: let pk = kit.externalSigners.addEd25519FromRawKey(...) — missing await, won't compile
// CORRECT:
let publicKey = try await kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSeedBytes,
    verifierAddress: "CDEF..."
)

// WRONG: canSignEd25519For is non-async, so call it directly — it is actor-isolated:
// CORRECT:
let canSign = await kit.externalSigners.canSignEd25519For(
    verifierAddress: "CDEF...",
    publicKey: publicKey
)
```

`addEd25519FromRawKey` throws `ValidationException.InvalidInput` when `secretKeyBytes` is not exactly 32 bytes or `verifierAddress` is not a valid `C…` strkey. For hardware wallets, HSMs, or remote signers, supply `config.externalEd25519Adapter` so the raw seed never enters process memory:

```swift
public protocol OZExternalEd25519SignerAdapter: Sendable {
    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool
    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data
}
```

### Standalone construction (advanced)

The multi-signer pipeline always uses `kit.externalSigners`. Construct a manager directly only for advanced use outside a kit — for example to supply a custom `WalletConnectionStorage` for cross-launch wallet-connection persistence.

```swift
public init(
    networkPassphrase: String,
    walletAdapter: ExternalWalletAdapter? = nil,
    walletConnectionStorage: WalletConnectionStorage? = nil,
    ed25519Adapter: OZExternalEd25519SignerAdapter? = nil
)

public protocol WalletConnectionStorage: Sendable {
    func getItem(key: String) async throws -> String?
    func setItem(key: String, value: String) async throws
    func removeItem(key: String) async throws
}
```

`InMemoryWalletConnectionStorage` is the default fallback (loses data on process exit). Implement `WalletConnectionStorage` with `UserDefaults` or the Keychain for persistence.

---

## Events

`kit.events` is a `SmartAccountEventEmitter`. Subscribe to a specific event type via `on(_:listener:)`, to all events via `addListener(_:)`, or once via `once(_:listener:)`.

> Subscribe to `kit.events` BEFORE the first kit use so synchronously-emitted events (e.g. `walletConnected` during a connect) are not missed. `emit` runs each listener synchronously on the calling thread — hop to the main actor inside the closure before touching UI state.

### Event types

```swift
public enum SmartAccountEvent {
    case walletConnected(contractId: String, credentialId: String)
    case walletDisconnected(contractId: String)
    case credentialCreated(credential: StoredCredential)
    case credentialDeleted(credentialId: String)
    case sessionExpired(contractId: String, credentialId: String)
    case transactionSigned(contractId: String, credentialId: String?)
    case transactionSubmitted(hash: String, success: Bool)
    case credentialSyncFailed(credentialId: String, error: Error)
}

public enum SmartAccountEventType: String {
    case walletConnected = "WalletConnected"
    case walletDisconnected = "WalletDisconnected"
    case credentialCreated = "CredentialCreated"
    case credentialDeleted = "CredentialDeleted"
    case sessionExpired = "SessionExpired"
    case transactionSigned = "TransactionSigned"
    case transactionSubmitted = "TransactionSubmitted"
    case credentialSyncFailed = "CredentialSyncFailed"
}
```

### Type-specific subscription

```swift
let unsub: SmartAccountEventUnsubscribe = kit.events.on(.walletConnected) { event in
    if case let .walletConnected(contractId, _) = event {
        print("Connected to \(contractId)")
    }
}
// Later:
unsub()
```

```swift
// WRONG: kit.events.on { event in ... } — `on` requires an event-type discriminator
// CORRECT: kit.events.on(.transactionSubmitted) { event in ... }
//          (use addListener(_:) for a type-agnostic listener)
```

### One-shot subscription

```swift
kit.events.once(.transactionSubmitted) { event in
    if case let .transactionSubmitted(hash, success) = event {
        print("First tx: \(hash), ok=\(success)")
    }
}
```

### Type-agnostic subscription

```swift
let unsub = kit.events.addListener { event in
    switch event {
    case let .walletConnected(contractId, _):
        print("Connected: \(contractId)")
    case let .transactionSubmitted(hash, success):
        print("Tx \(hash): success=\(success)")
    default:
        break
    }
}
```

### Error handler

Listener errors are swallowed by default to protect other listeners. Install an error handler for debugging:

```swift
kit.events.setErrorHandler { event, error in
    print("Listener failed on \(event.eventTypeTag): \(error)")
}
```

### Other API

```swift
kit.events.removeAllListeners(eventType: "WalletConnected")  // clears only that type's listeners
kit.events.removeAllListeners()                              // clears typed + global listeners
let n = kit.events.listenerCount(eventType: "WalletConnected")
```

### transactionSubmitted semantics

`success == true` on `transactionSubmitted` means the network accepted the transaction for inclusion — not that it was confirmed in a ledger. Use `TransactionResult.success` (from `transfer`/`contractCall`) for confirmed state.

---

## Indexer

`OZIndexerClient` queries an off-chain index of smart-account contracts keyed by credential ID and signer address. Use it for "Connect Wallet" discovery (find a user's contracts by passkey) and for fetching on-chain state without iterating context rules by hand.

`kit.indexerClient` is populated when `config.indexerUrl` is set, **or** when `OZIndexerClient.defaultIndexerUrls` has a default URL for `config.networkPassphrase` (testnet and mainnet are covered). It is `nil` only for custom networks with no explicit `indexerUrl`.

```swift
// WRONG: kit.indexerClient!.lookupByCredentialId(...) — force-unwrap; guard instead
// CORRECT: guard let indexer = kit.indexerClient else { /* no indexer configured */ return }
```

### Construction

```swift
public init(
    indexerUrl: String,
    timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,  // 10_000
    urlSession: URLSession? = nil
) throws

public static let defaultIndexerUrls: [String: String]
public static func getDefaultUrl(networkPassphrase: String) -> String?
public static func forNetwork(
    networkPassphrase: String,
    timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
    urlSession: URLSession? = nil
) -> OZIndexerClient?
```

Direct construction (standalone, outside the kit):

```swift
guard let indexer = OZIndexerClient.forNetwork(networkPassphrase: Network.testnet.passphrase) else {
    fatalError("No default indexer URL for this network")
}
```

The initializer throws `ConfigurationException.InvalidConfig` for a blank, non-HTTPS (except `http://localhost`), or host-less URL. `close()` releases the underlying `URLSession`; the kit handles this automatically when the client is reached via `kit.indexerClient`.

### lookupByCredentialId

Finds contracts where a WebAuthn credential is registered as a signer. Accepts the Base64URL-encoded credential ID; the client converts it to hex for the HTTP call.

```swift
public func lookupByCredentialId(credentialId: String) async throws -> OZCredentialLookupResponse

let response = try await indexer.lookupByCredentialId(credentialId: auth.credentialId)
for c in response.contracts {
    print("\(c.contractId) (\(c.contextRuleCount) rules)")
}
```

Throws `ValidationException.InvalidInput` when `credentialId` is not valid Base64URL, `IndexerException.RequestFailed` on HTTP errors, or `IndexerException.Timeout`.

### lookupByAddress

Finds contracts where an address is a delegated or native signer. Accepts both `G…` and `C…` addresses.

```swift
public func lookupByAddress(address: String) async throws -> OZAddressLookupResponse

let contracts = try await indexer.lookupByAddress(address: "GA7Q...").contracts
```

### getContract / getStats / isHealthy

```swift
public func getContract(contractId: String) async throws -> OZContractDetailsResponse
public func getStats() async throws -> OZIndexerStatsResponse
public func isHealthy() async -> Bool   // never throws; false on any error
```

```swift
let details = try await indexer.getContract(contractId: "CABC...")
for rule in details.contextRules {
    print("Rule \(rule.contextRuleId): \(rule.signers.count) signers, \(rule.policies.count) policies")
}

if await indexer.isHealthy() == false {
    // Fall back to deterministic derivation + on-chain verification.
}
```

### Response types

```swift
public struct OZCredentialLookupResponse {
    public let credentialId: String                  // Base64URL
    public let contracts: [OZIndexedContractSummary]
    public let count: Int
}

public struct OZAddressLookupResponse {
    public let signerAddress: String
    public let contracts: [OZIndexedContractSummary]
    public let count: Int
}

public struct OZContractDetailsResponse {
    public let contractId: String
    public let summary: OZIndexedContractSummary
    public let contextRules: [OZIndexedContextRule]
}

public struct OZIndexedContractSummary {
    public let contractId: String
    public let contextRuleCount: Int
    public let externalSignerCount: Int
    public let delegatedSignerCount: Int
    public let nativeSignerCount: Int
    public let firstSeenLedger: Int
    public let lastSeenLedger: Int
    public let contextRuleIds: [Int]
}

public struct OZIndexedContextRule {
    public let contextRuleId: Int
    public let signers: [OZIndexedSigner]
    public let policies: [OZIndexedPolicy]
}

public struct OZIndexedSigner {
    public let signerType: String      // "External" | "Delegated" | "Native"
    public let signerAddress: String?  // populated for Delegated/Native
    public let credentialId: String?   // HEX, populated for External
}

public struct OZIndexedPolicy {
    public let policyAddress: String
    public let installParams: [String: OZJSONValue]?
}
```

```swift
// WRONG: OZIndexedSigner.credentialId is Base64URL — the indexer returns HEX here
// CORRECT: hex-encoded (no 0x). Convert to Base64URL before matching against the
//          SDK's internal credential IDs.
```

---

## Deterministic Address Derivation

A smart account's contract address is deterministic given the same credential ID, deployer, and network passphrase — a direct consequence of how Soroban computes contract IDs.

```swift
public static func deriveContractAddress(
    credentialId: Data,           // raw bytes, NOT Base64URL
    deployerPublicKey: String,    // deployer G-address
    networkPassphrase: String
) throws -> String                // C-address
```

```swift
// Data(base64URLEncoded:) is a throwing initializer (NOT an optional init) — do not force-unwrap.
let credentialIdBytes = try Data(base64URLEncoded: walletResult.credentialId)
let derived = try SmartAccountUtils.deriveContractAddress(
    credentialId: credentialIdBytes,
    deployerPublicKey: deployer.accountId,
    networkPassphrase: Network.testnet.passphrase
)
```

Algorithm:

```
salt          = SHA-256(credentialId)
deployerAddr  = SCAddress::Account(deployerPublicKey)
networkId     = SHA-256(networkPassphrase as UTF-8)
preimage      = HashIDPreimage::ContractID { networkId, FromAddress { deployerAddr, salt } }
contractBytes = SHA-256(XDR_encode(preimage))
contractId    = StrKey.encodeContract(contractBytes)
```

Use this for wallet discovery without an indexer: derive the address, then verify it exists via the RPC `getContractData` for the contract-instance ledger key.

### Also exposed

```swift
public static func getContractSalt(credentialId: Data) -> Data
public static func normalizeSignature(_ derSignature: Data) throws -> Data
public static func extractPublicKeyFromRegistration(
    publicKey: Data? = nil,
    authenticatorData: Data? = nil,
    attestationObject: Data? = nil
) throws -> Data
```

`normalizeSignature` converts a DER-encoded secp256r1 signature to 64-byte compact `r || s` with low-S normalization — required for Soroban verification.

---

## Deployer Details

The deployer is the Stellar keypair whose `G…` address signs the deploy transaction. Its public key participates in contract-address derivation, so the address is deterministic per deployer + credential.

### Default deployer

```swift
// Internally: KeyPair from a seed of SHA-256("openzeppelin-smart-account-kit")
let defaultDeployer = try await OZSmartAccountConfig.createDefaultDeployer()
```

When `deployerKeypair` is `nil`, this default is used. The default deployer's seed is **publicly derivable** — anyone who knows the SDK can reconstruct the keypair. This is safe by design: the deployer has no post-deploy authority. After deployment only the configured signers can authorize operations; the deployer is not a signer, not an admin, and cannot move funds.

The shared default address has no attribution and, if funded on mainnet, anyone can spend its XLM on deploys — so keep it funded only via a relayer (deployer never holds funds), or set `deployerKeypair` to a keypair you control for mainnet.

### Custom deployer

```swift
let myDeployer = try KeyPair(secretSeed: secretSeedString)

let config = try OZSmartAccountConfig(
    rpcUrl: rpcUrl,
    networkPassphrase: passphrase,
    accountWasmHash: wasmHash,
    webauthnVerifierAddress: verifier,
    deployerKeypair: myDeployer
)
```

Tradeoff: clients without the deployer keypair cannot derive addresses locally — run an indexer for discovery.

### Fee payment summary

| Setup | Who pays the deploy fee |
|-------|--------------------------|
| Relayer configured | Relayer (via fee-bump) |
| No relayer, default deployer | Default deployer `G…` address (must be funded) |
| No relayer, custom deployer | Your custom deployer `G…` address (must be funded) |

### Going to mainnet

- Set `networkPassphrase = Network.public.passphrase`.
- Point `rpcUrl` at a mainnet Soroban RPC (not `https://soroban-testnet.stellar.org`).
- Stop using Friendbot; leave `autoFund: false` on `createWallet` and never call `fundWallet` on mainnet — both route to the testnet Friendbot URL. Fund mainnet accounts out-of-band with real XLM.
- Replace the default deployer with a custom `deployerKeypair`, or fund the default `G…` address / configure a relayer.
- Shorten `signatureExpirationLedgers` for high-value flows.
- Audit the `storage` adapter — `InMemoryStorageAdapter` silently loses credentials on process exit, permanently locking users out of mainnet funds.
- Replace testnet-only contract addresses (WASM hash, WebAuthn verifier, policy contracts) with their mainnet values; cross-check against the network passphrase.

---

## Error Handling

Every error is a subclass of `SmartAccountException` carrying a `code: SmartAccountErrorCode` and a `message: String`.

```swift
public class SmartAccountException: Error, CustomStringConvertible {
    public let code: SmartAccountErrorCode
    public let message: String
    public let cause: Error?
}
```

### Exception hierarchy

Each domain exception is a subclass with nested concrete classes (`NotConnected`, `NotFound`, etc.) and lowercase static factory methods.

| Base | Codes | Nested variants |
|------|-------|-----------------|
| `ConfigurationException` | 1001–1002 | `InvalidConfig`, `MissingConfig` |
| `WalletException` | 2001–2003 | `NotConnected`, `AlreadyExists`, `NotFound` |
| `CredentialException` | 3001–3004 | `NotFound`, `AlreadyExists`, `Invalid`, `DeploymentFailed` |
| `WebAuthnException` | 4001–4004 | `RegistrationFailed`, `AuthenticationFailed`, `NotSupported`, `Cancelled` |
| `TransactionException` | 5001–5004 | `SimulationFailed`, `SigningFailed`, `SubmissionFailed`, `Timeout` |
| `SignerException` | 6001–6002 | `NotFound`, `Invalid` |
| `ValidationException` | 7001–7003 | `InvalidAddress`, `InvalidAmount`, `InvalidInput` |
| `StorageException` | 8001–8002 | `ReadFailed`, `WriteFailed` |
| `SessionException` | 9001–9002 | `Expired`, `Invalid` |
| `IndexerException` | 10001–10002 | `RequestFailed`, `Timeout` |

### Handling pattern

```swift
do {
    let wallet = try await kit.walletOperations.createWallet(userName: "Alice", autoSubmit: true)
    print("Created: \(wallet.contractId)")
} catch let e as WebAuthnException.Cancelled {
    print("User cancelled biometric prompt")
} catch let e as WebAuthnException.AuthenticationFailed {
    print("WebAuthn authentication failed: \(e.message)")
} catch let e as WebAuthnException.NotSupported {
    print("WebAuthn not configured: \(e.message)")
} catch let e as ConfigurationException.MissingConfig {
    print("Missing configuration: \(e.message)")
} catch let e as TransactionException.SimulationFailed {
    print("Simulation failed: \(e.message)")
} catch let e as WalletException.NotFound {
    print("Wallet not found on-chain: \(e.message)")
} catch let e as SmartAccountException {
    print("Error [\(e.code.code)]: \(e.message)")
}
```

### wrapError (utility)

```swift
let wrapped = SmartAccountException.wrapError(someError, defaultCode: .invalidInput)
```

Wraps a non-SDK error into the appropriate `SmartAccountException` subclass; an existing `SmartAccountException` passes through unchanged.

---

## Contract Limits

OZ smart-account limits, enforced client-side in `OZConstants` and on-chain:

| Constant | Value |
|----------|-------|
| `OZConstants.maxSigners` (per context rule) | 15 |
| `OZConstants.maxPolicies` (per context rule) | 5 |
| `OZConstants.defaultSessionExpiryMs` | 604_800_000 (7 days) |
| `OZConstants.defaultTimeoutSeconds` | 30 |
| `OZConstants.defaultRelayerTimeoutMs` | 360_000 (6 min) |
| `OZConstants.defaultIndexerTimeoutMs` | 10_000 |
| `OZConstants.webAuthnTimeoutMs` | 60_000 |
| `OZConstants.friendbotReserveXlm` | 5 |

See [smart_accounts_policies.md](./smart_accounts_policies.md) for adding signers and policies under these limits.
