# Smart Accounts API Reference

> Canonical reference for every public symbol shipped under `stellarsdk/smartaccount/`. Conceptual material and walk-throughs live in `onboarding.md`; platform setup steps for the bundled WebAuthn provider live in `webauthn-ios.md` and `webauthn-macos.md`; the package-level overview lives in `README.md`. This file documents the API surface only; refer to the linked guides for ceremony narrative, entitlement plumbing, and end-to-end examples.

## Table of Contents

- [Quick Start](#quick-start)
- [OZSmartAccountKit (Main Entry Point)](#ozsmartaccountkit-main-entry-point)
- [OZSmartAccountConfig](#ozsmartaccountconfig)
- [Wallet Operations](#wallet-operations)
- [Transaction Operations](#transaction-operations)
- [Credential Management](#credential-management)
- [Signer Management](#signer-management)
- [Context Rule Management](#context-rule-management)
- [Policy Management](#policy-management)
- [Multi-Signer Operations](#multi-signer-operations)
- [External Signer Management](#external-signer-management)
- [Events](#events)
- [Errors](#errors)
- [Constants](#constants)
- [WebAuthn Provider](#webauthn-provider)
- [Storage Adapter](#storage-adapter)
- [Indexer and Relayer Clients](#indexer-and-relayer-clients)
- [Auth Helpers](#auth-helpers)
- [Builder Helpers](#builder-helpers)
- [Signer Types](#signer-types)
- [Signature Types](#signature-types)

---

## Quick Start

```swift
import stellarsdk

// 1. Build the WebAuthn provider for Apple platforms.
let webauthnProvider = try AppleWebAuthnProvider(
    rpId: "example.com",
    rpName: "Example Wallet"
)

// 2. Build the configuration.
// Real testnet values; replace for mainnet or your own deployment.
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY",
    webauthnProvider: webauthnProvider,
    storage: KeychainStorageAdapter()
)

// 3. Create the kit (synchronous, no network I/O).
let kit = OZSmartAccountKit.create(config: config)

// 4. Subscribe to lifecycle events (optional).
let unsubscribe = kit.events.on(.walletConnected) { event in
    if case let .walletConnected(contractId, _) = event {
        print("Connected: \(contractId)")
    }
}

// 5. Register a passkey, deploy the contract, and fund the wallet.
let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: true,
    autoFund: true,
    nativeTokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
)
print("Created wallet: \(wallet.contractId)")

// 6. Transfer tokens from the smart account.
let result = try await kit.transactionOperations.transfer(
    tokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
    recipient: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
    amount: "10"
)
print("Transfer success: \(result.success), hash: \(result.hash ?? "n/a")")

// 7. Tear down when the kit is no longer needed.
unsubscribe()
try await kit.disconnect()
await kit.close()
```

---

## OZSmartAccountKit (Main Entry Point)

```swift
public final class OZSmartAccountKit: @unchecked Sendable { ... }
```

Composition root that owns every operations module, every manager, the shared `SorobanServer`, and the optional indexer and relayer HTTP clients. Connected-state accessors (`isConnected`, `credentialId`, `contractId`) are thread-safe (protected by an internal `NSLock`); the configuration and resolved transports are immutable for the kit's lifetime.

### Factory Method

```swift
public static func create(config: OZSmartAccountConfig) -> OZSmartAccountKit
```

Creates a new `OZSmartAccountKit` instance. Synchronous; no network I/O. The kit owns its Soroban server, indexer client, and relayer client and tears them down on `close()`.

**Parameters**:
- `config`: The configuration for the kit.

**Returns**: A new `OZSmartAccountKit` bound to the supplied configuration.

### Properties

#### config

```swift
public let config: OZSmartAccountConfig
```

The immutable configuration the kit was constructed with.

#### sorobanServer

```swift
public let sorobanServer: SorobanServer
```

The Soroban RPC client shared by every operations module and manager.

#### indexerClient

```swift
public let indexerClient: OZIndexerClient?
```

Optional indexer client used for credential-to-contract discovery. `nil` when no explicit `indexerUrl` is set and the configured `networkPassphrase` has no built-in default in `OZIndexerClient.defaultIndexerUrls`.

#### relayerClient

```swift
public let relayerClient: OZRelayerClient?
```

Optional relayer client used for fee-sponsored transaction submission. Present when `config.relayerUrl` is non-`nil` at construction time. When `nil`, automatic submission-method selection falls back to RPC.

#### events

```swift
public let events: SmartAccountEventEmitter
```

The event emitter shared by every manager bound to this kit. See the [Events](#events) section for the listener API.

#### isConnected

```swift
public var isConnected: Bool { get }
```

`true` when both a credential identifier and a contract address are set. Reflects in-memory state only; after an app restart, call `walletOperations.connectWallet(_:)` to restore a saved session.

#### credentialId

```swift
public var credentialId: String? { get }
```

The Base64URL-encoded (unpadded) WebAuthn credential identifier of the currently connected wallet, or `nil` when no wallet is connected.

#### contractId

```swift
public var contractId: String? { get }
```

The smart-account contract address (`C…` strkey, 56 characters) of the currently connected wallet, or `nil` when no wallet is connected.

#### externalSigners

```swift
public var externalSigners: OZExternalSignerManager { get }
```

The kit-owned `OZExternalSignerManager`. Always non-`nil`; constructed at kit initialization from `config.externalWallet` and `config.externalEd25519Adapter`. Use this property to register in-memory keypairs at runtime (`addFromSecret(secretKey:)`, `addEd25519FromRawKey(secretKeyBytes:verifierAddress:)`) and to check signer availability (`hasWalletAdapter`, `canSignFor(address:)`, `canSignEd25519For(verifierAddress:publicKey:)`). The multi-signer pipeline resolves all external-signer calls through this property. See [External Signer Management](#external-signer-management) for the full manager API.

### Manager Properties

#### walletOperations

```swift
public var walletOperations: OZWalletOperations { get }
```

The [Wallet Operations](#wallet-operations) module. Drives wallet creation, connection, standalone passkey authentication, and retry of a previously incomplete or failed deployment.

#### transactionOperations

```swift
public var transactionOperations: OZTransactionOperations { get }
```

The [Transaction Operations](#transaction-operations) module. Provides the SEP-41 token transfer entry point, the direct external-contract call entry point, the smart-account-mediated `execute` entry point, the low-level `submit(hostFunction:auth:)` escape hatch, and the testnet Friendbot funding helper.

#### signerManager

```swift
public var signerManager: OZSignerManager { get }
```

The [Signer Management](#signer-management) manager. Adds and removes WebAuthn, Ed25519, and delegated signers on a context rule.

#### policyManager

```swift
public var policyManager: OZPolicyManager { get }
```

The [Policy Management](#policy-management) manager. Installs and removes the built-in policy types (Simple Threshold, Weighted Threshold, Spending Limit) and exposes a generic entry point for custom policy contracts.

#### contextRuleManagerConcrete

```swift
public var contextRuleManagerConcrete: OZContextRuleManager { get }
```

The concrete [Context Rule Management](#context-rule-management) manager. Use this accessor in code that needs the full public surface of the manager type (the alias `contextRuleManager` returns a protocol type that is internal to the SDK module and not accessible to consumers).

#### credentialManagerConcrete

```swift
public var credentialManagerConcrete: OZCredentialManager { get }
```

The concrete [Credential Management](#credential-management) manager. Use this accessor in code that needs the full public surface of the manager type (the alias `credentialManager` returns a protocol type that is internal to the SDK module and not accessible to consumers).

#### multiSignerManager

```swift
public var multiSignerManager: OZMultiSignerManager { get }
```

The [Multi-Signer Operations](#multi-signer-operations) manager. Coordinates ceremonies that combine multiple passkeys, Ed25519 external signers, and external-wallet signers.

### Lifecycle

#### disconnect()

```swift
public func disconnect() async throws
```

Ends the active session. Clears the in-memory connection state under the kit's internal lock, releases the lock, calls `storage.clearSession()`, and emits `SmartAccountEvent.walletDisconnected(contractId:)`. Stored credentials are NOT deleted — they remain in storage and can be reconnected with `walletOperations.connectWallet(_:)`. Safe to call when no wallet is connected.

**Throws**: `StorageException` when the storage adapter fails to clear the session.

#### close()

```swift
public func close() async
```

Releases the HTTP-client, event-emitter, and manager resources the kit owns. Treat the kit as unusable after this call; manager and operations accessors trap after `close()` returns.

#### getStorage()

```swift
public func getStorage() -> StorageAdapter
```

Returns the storage adapter resolved from `config.storage`. Thread-safe; the adapter reference is immutable for the kit's lifetime.

#### getDeployer()

```swift
public func getDeployer() async throws -> KeyPair
```

Returns the deployer keypair. When the configuration supplies an explicit `deployerKeypair`, it is returned; otherwise the deterministic default deployer is derived from `SHA-256("openzeppelin-smart-account-kit")` and cached on first use. The cache is unsynchronized — concurrent first callers may compute the deterministic deployer more than once, but the result is idempotent.

**Throws**: `ConfigurationException.InvalidConfig` when default-deployer derivation fails.

---

## OZSmartAccountConfig

```swift
public struct OZSmartAccountConfig: @unchecked Sendable, Equatable, Hashable { ... }
```

Immutable configuration value type passed to `OZSmartAccountKit.create(config:)`. Construct directly through the throwing initializer below or through `OZSmartAccountConfig.builder(...)` for a fluent API. Both entry points perform identical validation and produce identical instances.

### Required Fields

| Field | Type | Description |
|---|---|---|
| `rpcUrl` | `String` | Soroban RPC endpoint URL. Must not be blank. |
| `networkPassphrase` | `String` | Stellar network passphrase. Must not be blank. |
| `accountWasmHash` | `String` | 64-character hex SHA-256 of the smart-account contract WASM. Must match `[0-9a-fA-F]{64}`. |
| `webauthnVerifierAddress` | `String` | Contract address (`C…` strkey) of the WebAuthn verifier contract. Must be a valid `C…` strkey. |

### Optional Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `deployerKeypair` | `KeyPair?` | `nil` | Optional deployer keypair. When `nil`, the deterministic default deployer (derived from `SHA-256("openzeppelin-smart-account-kit")`) is used. |
| `rpId` | `String?` | `nil` | Optional WebAuthn Relying Party identifier. Stored on the configuration only; not passed automatically to the WebAuthn provider — construct `AppleWebAuthnProvider(rpId:rpName:)` separately and supply it via `webauthnProvider`. |
| `rpName` | `String` | `"Smart Account"` | WebAuthn Relying Party display name. Same caveat as `rpId`. |
| `sessionExpiryMs` | `Int64` | `OZConstants.defaultSessionExpiryMs` (604 800 000 — seven days) | Session expiry in milliseconds. |
| `signatureExpirationLedgers` | `Int` | `StellarProtocolConstants.ledgersPerHour` (720) | Signature expiration in ledgers. Validated to be in `[1, 535 680]` (one ledger to approximately one month at five-second ledgers). |
| `timeoutInSeconds` | `Int` | `OZConstants.defaultTimeoutSeconds` (30) | Transaction validity window in seconds. Validated to be in `[1, 600]`. |
| `relayerUrl` | `String?` | `nil` | Optional relayer endpoint URL. Must be `https://` or `http://localhost`. |
| `indexerUrl` | `String?` | `nil` | Optional indexer endpoint URL. When `nil`, `effectiveIndexerUrl()` falls back to the built-in default for the configured network. |
| `webauthnProvider` | `WebAuthnProvider?` | `nil` | WebAuthn provider used by `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, `addNewPasskeySigner`, and the per-entry signing pass. Required for every flow that prompts for biometric authentication. |
| `storage` | `StorageAdapter` | `InMemoryStorageAdapter()` | Adapter for persisting credentials and sessions. Production apps pass `KeychainStorageAdapter()` or `UserDefaultsStorageAdapter()`. |
| `externalWallet` | `ExternalWalletAdapter?` | `nil` | Optional external-wallet adapter injected into `kit.externalSigners` at construction. Required when `SelectedSigner.wallet(accountId:)` participates in a multi-signer ceremony and the wallet key is managed by an external service rather than an in-memory keypair. |
| `externalEd25519Adapter` | `OZExternalEd25519SignerAdapter?` | `nil` | Optional Ed25519 adapter injected into `kit.externalSigners` at construction. Provides out-of-process Ed25519 signing (hardware wallets, remote signing services) as an alternative to in-memory keypairs registered via `kit.externalSigners.addEd25519FromRawKey(...)`. |
| `maxContextRuleScanId` | `UInt32` | `50` | Maximum context-rule identifier to scan during `getAllContextRules()` / `listContextRules()`. Increase when the account has had many add / remove cycles. |

### Initialization

```swift
public init(
    rpcUrl: String,
    networkPassphrase: String,
    accountWasmHash: String,
    webauthnVerifierAddress: String,
    deployerKeypair: KeyPair? = nil,
    rpId: String? = nil,
    rpName: String = "Smart Account",
    sessionExpiryMs: Int64 = OZConstants.defaultSessionExpiryMs,
    signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour,
    timeoutInSeconds: Int = OZConstants.defaultTimeoutSeconds,
    relayerUrl: String? = nil,
    indexerUrl: String? = nil,
    webauthnProvider: WebAuthnProvider? = nil,
    storage: StorageAdapter = InMemoryStorageAdapter(),
    externalWallet: ExternalWalletAdapter? = nil,
    externalEd25519Adapter: OZExternalEd25519SignerAdapter? = nil,
    maxContextRuleScanId: UInt32 = 50
) throws
```

Parameters match the fields documented above.

**Throws**: `ConfigurationException.MissingConfig` (blank `rpcUrl`, `networkPassphrase`, or `accountWasmHash`); `ConfigurationException.InvalidConfig` (invalid `accountWasmHash` format, invalid `webauthnVerifierAddress` strkey, `signatureExpirationLedgers` outside `[1, 535 680]`, `timeoutInSeconds` outside `[1, 600]`).

### Static Factories

#### createDefaultDeployer()

```swift
public static func createDefaultDeployer() async throws -> KeyPair
```

Derives the deterministic default deployer keypair from `SHA-256("openzeppelin-smart-account-kit")`. The seed string is fixed and produces the same keypair on every invocation, so the deterministic deployer address is stable and predictable. The keypair pays deployment fees only and never controls user wallets.

**Throws**: `ConfigurationException.InvalidConfig` when seed generation fails.

#### builder(...)

```swift
public static func builder(
    rpcUrl: String,
    networkPassphrase: String,
    accountWasmHash: String,
    webauthnVerifierAddress: String
) -> Builder
```

Returns a new `Builder` pre-populated with the four required fields. See [OZSmartAccountConfig.Builder](#ozsmartaccountconfigbuilder) for the chainable setters.

### Instance Methods

#### effectiveDeployer()

```swift
public func effectiveDeployer() async throws -> KeyPair
```

Returns the configured deployer when one is set; otherwise returns the deterministic default from `createDefaultDeployer()`. Async because deriving the default involves cryptographic operations.

**Throws**: `ConfigurationException.InvalidConfig` when default-deployer derivation fails.

#### effectiveIndexerUrl()

```swift
public func effectiveIndexerUrl() -> String?
```

Returns the configured `indexerUrl` when set, otherwise returns the built-in default for the configured `networkPassphrase` resolved through `OZIndexerClient.getDefaultUrl(networkPassphrase:)`. Returns `nil` when neither source supplies a URL.

### OZSmartAccountConfig.Builder

```swift
public final class Builder: @unchecked Sendable { ... }
```

Fluent builder. All setters are `@discardableResult` and return `Builder` for chaining.

#### init(...)

```swift
public init(
    rpcUrl: String,
    networkPassphrase: String,
    accountWasmHash: String,
    webauthnVerifierAddress: String
)
```

#### Setters

Setters match every optional field name on the config; each returns the builder for chaining.

#### build()

```swift
public func build() throws -> OZSmartAccountConfig
```

Constructs the configuration through the initializer; the same validation rules apply.

**Throws**: `ConfigurationException` for any validation failure.

---

## Wallet Operations

```swift
public final class OZWalletOperations: @unchecked Sendable { ... }
```

Accessed via `kit.walletOperations`. Handles wallet creation (WebAuthn registration plus deterministic contract derivation plus deploy-transaction build and submission), wallet connection (session restore, storage-to-derivation-to-indexer cascade, ambiguous multi-contract handling), standalone passkey authentication, and retry of a previously incomplete or failed deployment. Every state-changing method respects task cancellation at each `await` point.

### createWallet(...)

```swift
public func createWallet(
    userName: String = "Smart Account User",
    autoSubmit: Bool = false,
    autoFund: Bool = false,
    nativeTokenContract: String? = nil,
    forceMethod: SubmissionMethod? = nil
) async throws -> CreateWalletResult
```

Registers a fresh WebAuthn credential, derives the deterministic smart-account contract address, persists the credential as `pending` in storage, sets the kit's connected state, builds and signs the deploy transaction, and (when `autoSubmit == true`) submits it. The returned result's `signedTransactionXdr` is always populated regardless of `autoSubmit`, so an off-line submission flow can pick it up later.

When `autoFund == true`, the freshly deployed contract is funded through Friendbot after deployment confirmation; this branch requires `autoSubmit == true` and a non-`nil` `nativeTokenContract`.

**Parameters**:
- `userName`: Display name persisted with the credential.
- `autoSubmit`: Submit the deploy transaction. Defaults to `false`.
- `autoFund`: Fund the wallet via Friendbot after deployment (testnet only). Defaults to `false`.
- `nativeTokenContract`: Native token (XLM SAC) contract address used when `autoFund == true`.
- `forceMethod`: Optional submission-method override.

**Returns**: A `CreateWalletResult` describing the new wallet.

**Throws**: `WebAuthnException` (missing provider, ceremony failure), `ValidationException` (input validation), `TransactionException` (build, sign, submit failure), `CredentialException`, `StorageException`.

### connectWallet(...)

```swift
public func connectWallet(
    options: ConnectWalletOptions = ConnectWalletOptions()
) async throws -> ConnectWalletResult?
```

Connects to an existing smart-account wallet. The tri-state return distinguishes "no session, no prompt" (`nil`) from a happy-path single-contract resolution (`.connected(...)`) and from an ambiguous multi-contract resolution (`.ambiguous(...)`). When `options.prompt == false` (default) and no valid session exists, returns `nil` so the caller can show a login UI. The kit's connected state is set on `.connected` and is NOT set on `.ambiguous` — the caller must let the user pick a candidate from `.ambiguous.candidates` and re-call with `options.contractId` set to the chosen address.

The cascade for resolving the contract address is: stored credential lookup → deterministic contract derivation from the credential id and the deployer's account id → indexer lookup. The indexer step runs only when the previous two short-circuit.

**Parameters**:
- `options`: Connect-wallet options. Defaults to a silent session-only restore.

**Returns**: A `ConnectWalletResult` or `nil`.

**Throws**: `WebAuthnException` (prompt path), `WalletException` (no contract resolved), `ValidationException` (options validation), `TransactionException` (RPC failure), `IndexerException` (indexer transport failure).

### authenticatePasskey(...)

```swift
public func authenticatePasskey(
    challenge: Data? = nil,
    credentialIds: [String]? = nil
) async throws -> AuthenticatePasskeyResult
```

Runs a standalone WebAuthn authentication ceremony without setting the kit's connected state. Typically used to drive an indexer lookup that discovers the contracts the credential is registered on before issuing an explicit `connectWallet(...)` call. When `challenge` is `nil` a 32-byte challenge is drawn from the system CSPRNG; when `credentialIds` is `nil` the authenticator's default credential discovery is used.

**Parameters**:
- `challenge`: Optional explicit challenge bytes; defaults to a fresh 32-byte CSPRNG draw.
- `credentialIds`: Optional Base64URL-encoded credential identifiers to restrict the authenticator picker.

**Returns**: An `AuthenticatePasskeyResult` carrying the credential id, the normalised WebAuthn signature, and the stored public key (when locally available).

**Throws**: `WebAuthnException` (missing provider, ceremony failure), `ValidationException`.

### deployPendingCredential(...)

```swift
public func deployPendingCredential(
    credentialId: String,
    autoSubmit: Bool = true,
    autoFund: Bool = false,
    nativeTokenContract: String? = nil,
    forceMethod: SubmissionMethod? = nil
) async throws -> DeployPendingResult
```

Retries deployment for a credential whose previous deploy attempt was skipped or failed. The credential must already exist in storage with `deploymentStatus == .pending` or `.failed`. Behaves like `createWallet(...)` from the deploy-transaction step onward: builds and signs the deploy transaction, submits when `autoSubmit == true`, optionally funds the wallet when both `autoSubmit` and `nativeTokenContract` are supplied.

**Parameters**:
- `credentialId`: Base64URL-encoded credential identifier to retry.
- `autoSubmit`: Submit the deploy transaction. Defaults to `true`.
- `autoFund`: Fund the wallet via Friendbot after deployment. Defaults to `false`.
- `nativeTokenContract`: Native token contract address used when `autoFund == true`.
- `forceMethod`: Optional submission-method override.

**Returns**: A `DeployPendingResult`.

**Throws**: `CredentialException.NotFound`, `WebAuthnException`, `ValidationException`, `TransactionException`, `StorageException`.

### Result Types

#### CreateWalletResult

```swift
public struct CreateWalletResult: Sendable, Hashable {
    public let credentialId: String
    public let contractId: String
    public let publicKey: Data
    public let signedTransactionXdr: String
    public let transactionHash: String?
    public let nickname: String?
}
```

| Field | Type | Description |
|---|---|---|
| `credentialId` | `String` | Base64URL-encoded WebAuthn credential identifier. |
| `contractId` | `String` | Smart-account contract address (`C…` strkey). |
| `publicKey` | `Data` | Uncompressed secp256r1 public key (65 bytes starting with `0x04`). |
| `signedTransactionXdr` | `String` | Base64-encoded signed deploy transaction envelope. Always populated. |
| `transactionHash` | `String?` | Transaction hash assigned at submission time. `nil` when `autoSubmit == false`. |
| `nickname` | `String?` | Display name supplied during wallet creation. |

Equality compares every field with a constant-time comparison on `publicKey` so byte-level timing inference is not possible from equality side channels. A `copy(...)` helper is provided for field-level immutable updates.

#### DeployPendingResult

```swift
public struct DeployPendingResult: Sendable, Equatable, Hashable {
    public let contractId: String
    public let signedTransactionXdr: String
    public let transactionHash: String?
}
```

| Field | Type | Description |
|---|---|---|
| `contractId` | `String` | Smart-account contract address. |
| `signedTransactionXdr` | `String` | Base64-encoded signed deploy envelope. |
| `transactionHash` | `String?` | Transaction hash; `nil` when not submitted. |

Includes a `copy(...)` helper.

#### ConnectWalletResult

```swift
public enum ConnectWalletResult: Sendable, Equatable, Hashable {
    case connected(credentialId: String, contractId: String, restoredFromSession: Bool)
    case ambiguous(credentialId: String, candidates: [String])

    public var credentialId: String { get }
}
```

The `connected` arm reports a successful single-contract resolution; `restoredFromSession` is `true` when the connection was restored from a stored session, `false` for fresh authentications. The `ambiguous` arm reports a multi-contract resolution from the indexer — the kit's connected state is NOT set on `.ambiguous`; the caller must let the user pick a candidate and re-call `connectWallet(options:)` with `contractId` set to the chosen value.

#### ConnectWalletOptions

```swift
public struct ConnectWalletOptions: Sendable, Equatable, Hashable {
    public let credentialId: String?
    public let contractId: String?
    public let fresh: Bool
    public let prompt: Bool

    public init(
        credentialId: String? = nil,
        contractId: String? = nil,
        fresh: Bool = false,
        prompt: Bool = false
    )
}
```

Default-constructed options request a silent session-only restore. Supplying `credentialId` and/or `contractId` selects a direct connect that skips the session check. `fresh = true` skips the session and always triggers WebAuthn; `prompt = true` triggers WebAuthn when no valid session exists. When both `fresh` and `prompt` are true, `fresh` takes priority. A `copy(...)` helper is provided.

#### AuthenticatePasskeyResult

```swift
public struct AuthenticatePasskeyResult: Sendable, Hashable {
    public let credentialId: String
    public let signature: OZWebAuthnSignature
    public let publicKey: Data
}
```

| Field | Type | Description |
|---|---|---|
| `credentialId` | `String` | Base64URL-encoded credential identifier. |
| `signature` | `OZWebAuthnSignature` | Normalised WebAuthn signature produced during the ceremony. |
| `publicKey` | `Data` | Stored secp256r1 public key (65 bytes) when locally available; empty `Data` otherwise. |

Equality uses constant-time comparison on `publicKey`.

---

## Transaction Operations

```swift
public final class OZTransactionOperations: @unchecked Sendable { ... }
```

Accessed via `kit.transactionOperations`. Builds, signs, and submits transactions on behalf of the connected smart-account wallet. Drives the full simulate / sign / re-simulate / submit pipeline, including WebAuthn-based auth-entry signing, automatic relayer-versus-RPC selection, and result polling.

### transfer(...)

```swift
public func transfer(
    tokenContract: String,
    recipient: String,
    amount: String,
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Transfers SEP-41-compatible tokens from the connected smart account to a recipient. The decimal amount is converted to stroops (seven decimal places) before submission. Compatible with native XLM via the Stellar Asset Contract and with any custom Soroban token implementing the SEP-41 interface. The recipient may be a `G…` account or a `C…` contract; the method rejects self-transfers.

Delegates to `contractCall(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)` to drive the pipeline.

**Throws**: `WalletException.NotConnected`, `ValidationException` (invalid address, invalid amount, self-transfer), `TransactionException`, `WebAuthnException`.

### contractCall(...)

```swift
public func contractCall(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Calls a function on an external contract directly from the smart account. The smart account authorizes the call via Soroban's `require_auth` mechanism triggered by the target contract. Use this for any external-contract interaction (token approvals, token transfers, DeFi protocol calls) where the smart account is the authorized party.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`, `WebAuthnException`, `CredentialException`.

### executeAndSubmit(...)

```swift
public func executeAndSubmit(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Calls `execute(target, target_fn, target_args)` on the smart-account contract itself. The contract dispatches the inner call on behalf of the smart account after evaluating its context rules and policies. Use this when the call must flow through the smart account's `execute` entry point rather than originate from the smart account directly.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`, `WebAuthnException`, `CredentialException`.

### submit(...)

```swift
public func submit(
    hostFunction: HostFunctionXDR,
    auth: [SorobanAuthorizationEntryXDR],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Low-level escape hatch. Submits a manually constructed host function through the full simulate / sign / re-simulate / submit pipeline. `transfer`, `contractCall`, and `executeAndSubmit` all delegate to this method internally. Callers needing to construct a host function whose shape is not covered by the higher-level entry points use this method directly. The simulation discovers auth entries when `auth` is empty; the signing pass writes the OpenZeppelin AuthPayload Map directly into the credentials' `signature` field; the transaction is re-simulated after signing because WebAuthn signatures are larger than the placeholders the initial simulation used.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`, `WebAuthnException`, `CredentialException`.

### fundWallet(...)

```swift
public func fundWallet(
    nativeTokenContract: String,
    forceMethod: SubmissionMethod? = nil
) async throws -> String
```

Funds the connected smart-account wallet using Friendbot. Testnet only; hard-codes the Friendbot URL `https://friendbot.stellar.org/` and has no mainnet equivalent. Generates a fresh temporary keypair, funds it via Friendbot, queries its XLM balance via the native token contract, and transfers the surplus (balance minus the protocol minimum-balance reserve) to the smart-account contract. Source-account authorization entries from the inner transfer simulation are converted to classical Ed25519 `Address` credentials so the relayer can substitute its own channel accounts for fee sponsoring.

**Returns**: Funded amount as a decimal XLM string (for example `"100"` or `"12.34567"`); trailing zeros in the fractional component are trimmed.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### Result Types

#### TransactionResult

```swift
public struct TransactionResult: Sendable, Equatable, Hashable {
    public let success: Bool
    public let hash: String?
    public let ledger: UInt32?
    public let error: String?
}
```

| Field | Type | Description |
|---|---|---|
| `success` | `Bool` | `true` when the transaction was accepted by the network and confirmed successfully on-chain; `false` for every other outcome (simulation failure, network rejection, polling timeout, on-chain `FAILED` status). |
| `hash` | `String?` | Stellar transaction hash assigned at submission. `nil` only when submission failed before a hash could be assigned. |
| `ledger` | `UInt32?` | Ledger sequence number that included the transaction. Present only after successful confirmation polling. |
| `error` | `String?` | Human-readable failure description; `nil` on success. |

Includes a `copy(...)` helper.

#### ResolveContextRuleIds

```swift
public typealias ResolveContextRuleIds = @Sendable (
    _ entry: SorobanAuthorizationEntryXDR,
    _ index: Int
) async throws -> [UInt32]
```

Callback used to override the automatic context-rule resolution that runs during the signing loop. Invoked once per matching auth entry. The first argument carries the authorization entry being signed; the second is the entry's index in the simulation-supplied list. The returned identifiers replace the resolution that otherwise runs against the connected signer set. Errors thrown from the callback propagate to the caller of `submit(...)`.

---

## Credential Management

```swift
public final class OZCredentialManager: @unchecked Sendable { ... }
```

Accessed via `kit.credentialManagerConcrete`. Persists, queries, updates, and deletes stored credentials, and reconciles local credential state against on-chain deployment status.

### Credential State Machine

Stored credentials occupy two persistent states after creation: `pending` and `failed`. There is no `success` state — credentials are deleted from storage on successful deployment (or when a sync discovers the contract on-chain). Failed deployments can be retried by deleting the credential and re-creating one with the same identifier, or by calling `walletOperations.deployPendingCredential(...)`.

### createPendingCredential(...)

```swift
public func createPendingCredential(
    credentialId: String,
    publicKey: Data,
    contractId: String,
    nickname: String? = nil,
    transports: [String]? = nil,
    deviceType: String? = nil,
    backedUp: Bool? = nil
) async throws -> StoredCredential
```

Creates a new pending credential and persists it to storage. The credential is created with `deploymentStatus == .pending`, `isPrimary == false`, and `createdAt` set to the current wall-clock time in milliseconds. The `contractId` is required and non-optional.

Validation: `publicKey` must be exactly `SmartAccountConstants.secp256r1PublicKeySize` (65) bytes; `credentialId` must not be empty and must be unique within storage.

**Returns**: The persisted `StoredCredential`.

**Throws**: `ValidationException.InvalidInput`, `CredentialException.AlreadyExists`, `StorageException.WriteFailed`.

### saveCredential(...)

```swift
public func saveCredential(
    credentialId: String,
    publicKey: Data,
    nickname: String? = nil,
    contractId: String? = nil
) async throws -> StoredCredential
```

Saves a credential with looser validation than `createPendingCredential(...)`. Does NOT check for duplicates, does NOT capture deployment-time WebAuthn metadata (`transports`, `deviceType`, `backedUp`), persists `isPrimary = false`, and stores `contractId == nil` as the empty string to match the on-chain "not yet derived" sentinel used by other call sites.

**Throws**: `ValidationException.InvalidInput`, `StorageException.WriteFailed`.

### sync(...)

```swift
@discardableResult
public func sync(credentialId: String) async throws -> Bool
```

Reconciles a single stored credential with on-chain state. Returns `true` when the credential's contract is now confirmed deployed on-chain (in which case the credential is removed from storage), `false` otherwise. RPC failures that prevent the on-chain check emit `SmartAccountEvent.credentialSyncFailed(credentialId:error:)` and leave the credential in storage for a subsequent retry.

### syncAll()

```swift
public func syncAll() async throws -> SyncResult
```

Reconciles every stored credential with on-chain state and returns a summary of how many were confirmed deployed (and removed), how many remain pending, and how many failed deployment.

### deleteCredential(...)

```swift
public func deleteCredential(credentialId: String) async throws
```

Removes the named credential from storage and emits `SmartAccountEvent.credentialDeleted(credentialId:)`. Throws `CredentialException.NotFound` if no such credential exists.

### getCredential(...)

```swift
public func getCredential(credentialId: String) async throws -> StoredCredential?
```

Returns the stored credential matching the supplied identifier, or `nil` when absent.

### getCredentialsByContract(...)

```swift
public func getCredentialsByContract(contractId: String) async throws -> [StoredCredential]
```

Returns every stored credential whose `contractId` matches the supplied address.

### getAllCredentials()

```swift
public func getAllCredentials() async throws -> [StoredCredential]
```

Returns every stored credential.

### getForConnectedWallet()

```swift
public func getForConnectedWallet() async throws -> [StoredCredential]
```

Returns every stored credential whose `contractId` matches the kit's currently connected contract.

### getPendingCredentials()

```swift
public func getPendingCredentials() async throws -> [StoredCredential]
```

Returns every stored credential whose `deploymentStatus` is `.pending` or `.failed`.

### updateNickname(...)

```swift
public func updateNickname(credentialId: String, nickname: String?) async throws
```

Updates the nickname of the named credential. Throws `CredentialException.NotFound` if no such credential exists.

### clearAll()

```swift
public func clearAll() async throws
```

Removes every stored credential. Does not clear the active session.

### Result Types

#### SyncResult

```swift
public struct SyncResult: Sendable, Equatable, Hashable {
    public let deployed: Int
    public let pending: Int
    public let failed: Int
}
```

Number of credentials confirmed deployed on-chain (and removed from storage during the sync), still pending deployment, and with `failed` deployment status.

#### StoredCredential

```swift
public struct StoredCredential: Sendable, Equatable, Hashable {
    public let credentialId: String
    public let publicKey: Data
    public let contractId: String?
    public let deploymentStatus: CredentialDeploymentStatus
    public let deploymentError: String?
    public let createdAt: Int64
    public let lastUsedAt: Int64?
    public let nickname: String?
    public let isPrimary: Bool
    public let transports: [String]?
    public let deviceType: String?
    public let backedUp: Bool?
}
```

`publicKey` is the uncompressed secp256r1 public key (65 bytes). `contractId` is `nil` when the contract address has not yet been derived. `lastUsedAt` is updated after successful transaction signatures. Equality compares `publicKey` in constant time.

#### CredentialDeploymentStatus

```swift
public enum CredentialDeploymentStatus: String, Sendable, CaseIterable {
    case pending = "PENDING"
    case failed = "FAILED"
}
```

There is no `success` arm; successful deployment removes the credential from storage rather than transitioning it to a third state.

#### StoredCredentialUpdate

```swift
public struct StoredCredentialUpdate: Sendable, Equatable, Hashable
```

Sparse update value used by the underlying `StorageAdapter.update(credentialId:updates:)` contract; consumer code typically reaches it only when implementing a custom `StorageAdapter`.

#### StoredSession

```swift
public struct StoredSession: Sendable, Equatable, Hashable
```

Persisted session record consumed by the `StorageAdapter` session methods.

---

## Signer Management

```swift
public final class OZSignerManager: @unchecked Sendable { ... }
```

Accessed via `kit.signerManager`. Adds and removes signers bound to a context rule. Supported signer kinds:

- WebAuthn passkeys (secp256r1 verified through a verifier contract).
- Delegated signers (Stellar `G…` accounts or `C…` contract addresses authorising through the host's built-in `require_auth`).
- Ed25519 signers (32-byte Ed25519 keys verified by a verifier contract).

Every state-changing method accepts an optional `selectedSigners: [SelectedSigner]` parameter. When empty (default), the operation uses single-signer authorization through the connected passkey credential. When non-empty, the operation routes through the multi-signer ceremony coordinator that collects signatures from every listed signer and assembles the final authorization payload.

### addNewPasskeySigner(...)

```swift
public func addNewPasskeySigner(
    contextRuleId: UInt32,
    userName: String,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> AddPasskeySignerResult
```

Runs the full end-to-end "register a fresh passkey and add it as a signer" flow: validates the kit's connection state and the WebAuthn provider, generates 32-byte random challenge and user-id buffers, prompts for biometric registration, persists the new credential as `pending` in storage, emits `SmartAccountEvent.credentialCreated(credential:)`, and finally adds the resulting public key as a signer on the smart-account contract by delegating to `addPasskey(...)`. In single-signer mode the user is prompted for biometric authentication twice: once for the new passkey registration and once for the existing signer to authorize the addition.

**Throws**: `WalletException.NotConnected`, `WebAuthnException.NotSupported`, `WebAuthnException`, `CredentialException`, `TransactionException`.

### addPasskey(...)

```swift
public func addPasskey(
    contextRuleId: UInt32,
    publicKey: Data,
    credentialId: Data,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Adds a WebAuthn passkey signer to a context rule when the credential identifier and public key are already in hand. Builds an `OZExternalSigner.webAuthn(verifierAddress:publicKey:credentialId:)` (the verifier address is sourced from `config.webauthnVerifierAddress`) and submits an `add_signer` invocation against the smart-account contract. The on-chain transaction requires authorization from an existing signer on the supplied context rule.

`publicKey` must be the canonical uncompressed 65-byte secp256r1 form starting with `0x04`; `credentialId` must be non-empty.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### addDelegated(...)

```swift
public func addDelegated(
    contextRuleId: UInt32,
    address: String,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Adds a delegated signer (Stellar `G…` account or `C…` contract) to a context rule. The signer authorises through the host's built-in `require_auth` mechanism; no verifier contract is required.

**Throws**: `WalletException.NotConnected`, `ValidationException.InvalidAddress`, `TransactionException`.

### addEd25519(...)

```swift
public func addEd25519(
    contextRuleId: UInt32,
    verifierAddress: String,
    publicKey: Data,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Adds an Ed25519 signer to a context rule. Constructs an `OZExternalSigner.ed25519(verifierAddress:publicKey:)` and submits an `add_signer` invocation. `publicKey` must be the canonical 32-byte Ed25519 encoding.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### removeSigner(...)

```swift
public func removeSigner(
    contextRuleId: UInt32,
    signerId: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Removes a signer from a context rule by its on-chain numeric identifier. The id is assigned by the smart-account contract when the signer is added and surfaces on `ParsedContextRule.signerIds` after a rule fetch. The contract returns error code 3004 if the last signer is removed from a rule with no configured policies.

**Throws**: `WalletException.NotConnected`, `TransactionException`.

### removeSignerBySigner(...)

```swift
public func removeSignerBySigner(
    contextRuleId: UInt32,
    signer: any OZSmartAccountSigner,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Removes a signer by matching the signer value. Resolves the numeric signer id internally with one extra RPC round trip (fetches and parses the target context rule), then delegates to `removeSigner(contextRuleId:signerId:...)`. The `BySigner` suffix disambiguates this method from the id-based overload.

**Throws**: `WalletException.NotConnected`, `ValidationException` (signer not found, signer / signerId array misalignment), `ConfigurationException` (when the manager was constructed without a context-rule parser), `TransactionException`.

### Result Types

#### AddPasskeySignerResult

```swift
public struct AddPasskeySignerResult: Sendable, Hashable {
    public let credentialId: String
    public let publicKey: Data
    public let transactionResult: TransactionResult
}
```

| Field | Type | Description |
|---|---|---|
| `credentialId` | `String` | Base64URL-encoded credential identifier. |
| `publicKey` | `Data` | Uncompressed secp256r1 public key bytes. |
| `transactionResult` | `TransactionResult` | On-chain signer-addition transaction outcome. |

Equality uses constant-time comparison on `publicKey`.

---

## Context Rule Management

```swift
public final class OZContextRuleManager: @unchecked Sendable { ... }
```

Accessed via `kit.contextRuleManagerConcrete`. Creates, lists, parses, updates, and removes context rules on the connected smart-account contract. Contract limits enforced before submission:

- Maximum `OZConstants.maxSigners` (15) signers per rule.
- Maximum `OZConstants.maxPolicies` (5) policies per rule.

A context rule must have at least one signer or one policy.

### addContextRule(...)

```swift
public func addContextRule(
    contextType: ContextRuleType,
    name: String,
    validUntil: UInt32? = nil,
    signers: [any OZSmartAccountSigner],
    policies: [String: SCValXDR] = [:],
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Adds a new context rule. `contextType` selects the matching policy (default rule, call-contract, or create-contract). `name` is the human-readable rule name. `validUntil` is the optional ledger number at which the rule expires (`nil` for non-expiring). `signers` lists the signers authorised by the rule. `policies` maps policy contract addresses (`C…` strkey) to their installation parameters encoded as `SCValXDR`; map keys are sorted by XDR-byte order before submission to satisfy Soroban's `ScMap` ordering invariant.

**Throws**: `WalletException.NotConnected`, `ValidationException.InvalidInput`, `ValidationException.InvalidAddress`, `TransactionException`.

### getContextRule(...)

```swift
public func getContextRule(id: UInt32) async throws -> SCValXDR
```

Returns the raw `SCValXDR` payload for a single context rule. Callers that need a typed view should parse the result with the kit's parser or use `listContextRules()`, which performs the parse step internally. Read-only — issues a simulated invocation against the connected contract.

**Throws**: `WalletException.NotConnected`, `TransactionException.SimulationFailed` (commonly when the rule does not exist on chain).

### getContextRulesCount()

```swift
public func getContextRulesCount() async throws -> UInt32
```

Returns the number of context rules currently configured on the connected smart account. Read-only.

**Throws**: `WalletException.NotConnected`, `TransactionException`, `ValidationException.InvalidInput` (when the on-chain result is not a `U32`).

### getAllContextRules()

```swift
public func getAllContextRules() async throws -> [SCValXDR]
public func getAllContextRules(maxScanId: UInt32? = nil) async throws -> [SCValXDR]
```

Retrieves every active context rule as raw `SCValXDR` map payloads in ascending id order. The contract assigns monotonically increasing identifiers; removed rules leave numeric gaps. The method iterates identifiers from zero upward, skipping gaps reported as `TransactionException.SimulationFailed`, until either the active rule count has been collected or the effective scan upper bound is reached. The zero-argument overload uses `config.maxContextRuleScanId`; the override overload accepts a per-call upper bound (pass `nil` to use the kit default).

**Throws**: `WalletException.NotConnected`, `TransactionException`, `ValidationException`.

### listContextRules()

```swift
public func listContextRules() async throws -> [ParsedContextRule]
public func listContextRules(maxScanId: UInt32? = nil) async throws -> [ParsedContextRule]
```

Returns the parsed view of every active context rule. Internally calls `getAllContextRules(...)` and parses each entry through the internal context-rule parser.

**Throws**: Same as `getAllContextRules(...)`.

### resolveContextRuleIdsForEntry(...)

```swift
public func resolveContextRuleIdsForEntry(
    entry: SorobanAuthorizationEntryXDR,
    signers: [any OZSmartAccountSigner],
    contextRules: [ParsedContextRule]
) async throws -> [UInt32]
```

Resolves the on-chain context-rule identifiers that bind into the auth digest for a single authorization entry. Consumed by the transaction-operations signing pass and by the multi-signer manager; available publicly for callers that build a custom signing pipeline.

**Throws**: `ValidationException`, `TransactionException`.

### updateName(...)

```swift
public func updateName(
    id: UInt32,
    name: String,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Updates the human-readable name of an existing rule. The `name` field is metadata only — it has no effect on rule matching or enforcement. Must be non-empty.

**Throws**: `WalletException.NotConnected`, `ValidationException.InvalidInput`, `TransactionException`.

### updateValidUntil(...)

```swift
public func updateValidUntil(
    id: UInt32,
    validUntil: UInt32?,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Updates the expiration ledger of an existing rule. Pass `nil` to clear the expiration (the rule becomes non-expiring). On chain the field is `Option<u32>` encoded as `Void` for `None` and `U32` for `Some`.

**Throws**: `WalletException.NotConnected`, `TransactionException`.

### removeContextRule(...)

```swift
public func removeContextRule(
    id: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Removes a context rule. Removed rules leave a numeric gap in the identifier sequence that the scan-based enumeration helpers skip.

**Throws**: `WalletException.NotConnected`, `TransactionException`.

### Result Types

#### ContextRuleType

```swift
public enum ContextRuleType: Sendable, Hashable {
    case defaultRule
    case callContract(contractAddress: String)
    case createContract(wasmHash: Data)

    public func toScVal() throws -> SCValXDR
}
```

Three operation-matching types:
- `defaultRule` — matches any operation (fallback / default rule).
- `callContract(contractAddress:)` — matches invocations to a specific contract address (`C…`, 56 characters).
- `createContract(wasmHash:)` — matches contract deployments using a specific 32-byte WASM hash.

Equality and hashing use constant-time comparison on the `wasmHash` field to avoid leaking information about the byte content through timing side channels. `toScVal()` produces the on-chain encoding: `Default` is `vec([Symbol("Default")])`; `CallContract` is `vec([Symbol("CallContract"), Address(contractAddress)])`; `CreateContract` is `vec([Symbol("CreateContract"), Bytes(wasmHash)])`.

#### ParsedContextRule

```swift
public struct ParsedContextRule: Sendable, Hashable {
    public let id: UInt32
    public let contextType: ContextRuleType
    public let name: String
    public let signers: [any OZSmartAccountSigner]
    public let signerIds: [UInt32]
    public let policies: [String]
    public let policyIds: [UInt32]
    public let validUntil: UInt32?
}
```

`signers` / `signerIds` and `policies` / `policyIds` are positionally aligned: the i-th element of `signerIds` is the on-chain numeric identifier of the i-th element of `signers`, and likewise for policies. `validUntil` is `nil` for a non-expiring rule.

---

## Policy Management

```swift
public final class OZPolicyManager: @unchecked Sendable { ... }
```

Accessed via `kit.policyManager`. Adds and removes policies on context rules. Policies are authorization rules that must be satisfied for a transaction to authorize on the smart account; a context rule may carry up to `OZConstants.maxPolicies` (5) policies, and every attached policy must be satisfied.

Three built-in policy contracts ship with the OpenZeppelin suite. The manager exposes convenience methods for each plus a generic `addPolicy(...)` entry point for custom policy contracts.

All state-changing methods accept the same `selectedSigners` / `forceMethod` pair as the other managers.

### addSimpleThreshold(...)

```swift
public func addSimpleThreshold(
    contextRuleId: UInt32,
    policyAddress: String,
    threshold: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Installs a simple threshold policy requiring at least `threshold` of the context rule's signers to authorize, with equal weight per signer. `threshold` must be greater than zero. Encodes the parameters through `PolicyInstallParams.simpleThreshold(threshold:)` and delegates to `addPolicy(...)`.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### addWeightedThreshold(...)

```swift
public func addWeightedThreshold(
    contextRuleId: UInt32,
    policyAddress: String,
    signerWeights: [SignerWeightEntry],
    threshold: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Installs a weighted threshold policy. Authorization succeeds when the summed weights of authorizing signers meet or exceed `threshold`. `signerWeights` must be non-empty. Encoded through `PolicyInstallParams.weightedThreshold(signerWeights:threshold:)`.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### addSpendingLimit(...)

```swift
public func addSpendingLimit(
    contextRuleId: UInt32,
    policyAddress: String,
    spendingLimit: String,
    periodLedgers: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Installs a spending limit policy that caps cumulative spend within a rolling `periodLedgers`-ledger window (Stellar produces a ledger approximately every five seconds; one hour is `StellarProtocolConstants.ledgersPerHour`, one day is approximately 17 280 ledgers). The amount is supplied as a positive decimal XLM string and converted to stroops via the protocol-standard 7-decimal-place fixed-point shift (one XLM equals ten million stroops).

For amounts whose stroops value exceeds the `Int64` ceiling (approximately 9.2x10^18 stroops), construct the policy directly via `PolicyInstallParams.spendingLimit(spendingLimit:periodLedgers:)` with a stroops-denominated decimal-integer string and pass it through `addPolicy(...)`.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### removePolicy(...)

```swift
public func removePolicy(
    contextRuleId: UInt32,
    policyId: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Removes a policy from a context rule by its on-chain numeric id. The id surfaces on `ParsedContextRule.policyIds`.

**Throws**: `WalletException.NotConnected`, `TransactionException`.

### removePolicyByAddress(...)

```swift
public func removePolicyByAddress(
    contextRuleId: UInt32,
    policyAddress: String,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Removes a policy by matching the policy contract address. Resolves the numeric id internally with one extra RPC round trip (fetches and parses the target rule, locates the policy address within `policies`), then delegates to `removePolicy(...)`. The Swift method name has the explicit `ByAddress` suffix for the same overload-resolution reason as `removeSignerBySigner(...)`.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`.

### addPolicy(...)

```swift
public func addPolicy(
    contextRuleId: UInt32,
    policyAddress: String,
    installParams: SCValXDR,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

Generic policy installation. Use this method directly when installing a custom policy contract not covered by the three convenience helpers. The structure of `installParams` depends on the target policy contract; for the three built-in policy types, build a `PolicyInstallParams` value and call its `toScVal()` (the value is internal — prefer the convenience helpers).

**Throws**: `WalletException.NotConnected`, `ValidationException` (when `policyAddress` is malformed), `TransactionException`.

### Static Helpers

#### sortMapByKeyXdr(_:)

```swift
public static func sortMapByKeyXdr(_ entries: [SCMapEntryXDR]) -> [SCMapEntryXDR]
```

Sorts a list of `SCMapEntryXDR` entries by the lexicographic byte ordering of their keys' XDR encoding. Soroban's host enforces strict byte-lexicographic ordering of `ScMap` keys for canonicality and uniqueness checks. Use this helper whenever a dynamically-keyed map is built from caller-supplied data so the on-chain shape is deterministic regardless of insertion order. The input list is not mutated.

### Supporting Types

#### PolicyInstallParams

```swift
public enum PolicyInstallParams: Sendable {
    case simpleThreshold(threshold: UInt32)
    case weightedThreshold(signerWeights: [SignerWeightEntry], threshold: UInt32)
    case spendingLimit(spendingLimit: String, periodLedgers: UInt32)
}
```

Installation parameters for the three built-in policy types. The `toScVal()` encoder is internal so consumers cannot accidentally produce malformed encodings; reach the on-chain `SCValXDR` shape through the matching convenience method on `OZPolicyManager` (which calls the internal encoder for you), or through `OZSmartAccountBuilders.create*Params(...)` for the typed parameter structs.

#### SignerWeightEntry

```swift
public struct SignerWeightEntry: Sendable {
    public let signer: any OZSmartAccountSigner
    public let weight: UInt32

    public init(signer: any OZSmartAccountSigner, weight: UInt32)
}
```

A single signer-weight pair used by `PolicyInstallParams.weightedThreshold` and by `addWeightedThreshold(...)`. Weight must be greater than zero — a zero-weight signer is indistinguishable from no signer at all and is rejected by the smart-account contract.

The SDK ships a parallel struct `OZSignerWeight` (with `Int` weight) used by `OZSmartAccountBuilders.createWeightedThresholdParams(...)` for the typed parameter struct API. `SignerWeightEntry` and `OZSignerWeight` are distinct types and are not interchangeable; use `SignerWeightEntry` for direct calls into the policy manager and `OZSignerWeight` for the builder-produced parameter struct.

---

## Multi-Signer Operations

```swift
public class OZMultiSignerManager: @unchecked Sendable { ... }
```

Accessed via `kit.multiSignerManager`. Collects signatures from a caller-supplied list of signers (passkeys, Ed25519 external signers, and external-wallet addresses) and submits the resulting transaction through the kit's transaction operations.

### Signer Collection Semantics

Signatures are collected sequentially in the order supplied via `selectedSigners`. Each `SelectedSigner.passkey(...)` triggers exactly one OS WebAuthn authentication prompt; each `SelectedSigner.wallet(...)` triggers exactly one external-wallet signing request; each `SelectedSigner.ed25519(...)` calls `OZExternalSignerManager.signEd25519AuthDigest(...)` using the signing source registered for that `(verifierAddress, publicKey)` pair. Sequential collection enables fail-fast behaviour on user cancellation. The connected passkey is NOT added implicitly — include it explicitly via `SelectedSigner.passkey(...)` when the connected passkey should sign.

### multiSignerTransfer(...)

```swift
public func multiSignerTransfer(
    tokenContract: String,
    recipient: String,
    amount: String,
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

SEP-41 token transfer signed by an explicit list of signers. Validates the connection, the recipient address, the self-transfer guard, the amount, and that `selectedSigners` is non-empty before delegating to `multiSignerContractCall(...)`.

**Throws**: `WalletException.NotConnected`, `ValidationException`, `TransactionException`, `WebAuthnException`, `ConfigurationException` (when wallet signers are supplied but no external-wallet adapter is configured).

### multiSignerContractCall(...)

```swift
public func multiSignerContractCall(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Multi-signer counterpart to `OZTransactionOperations.contractCall(...)`. Builds a host function that invokes `target.targetFn(targetArgs)` directly so a context rule of type `callContract(target)` matches the authorization, allowing contract-specific multi-signer rules to apply.

**Throws**: `WalletException`, `ValidationException`, `TransactionException`, `WebAuthnException`, `ConfigurationException`.

### multiSignerExecuteAndSubmit(...)

```swift
public func multiSignerExecuteAndSubmit(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Multi-signer counterpart to `OZTransactionOperations.executeAndSubmit(...)`. Routes the call through the smart-account contract's `execute(target, target_fn, target_args)` entry point with multi-signer authorization. Use this when a contract call must be authorized by multiple signers — for example a governance vote, a multi-sig swap, or any operation gated by a multi-signer context rule.

**Throws**: `WalletException`, `ValidationException`, `TransactionException`, `WebAuthnException`, `ConfigurationException`.

### submitWithMultipleSigners(...)

```swift
public func submitWithMultipleSigners(
    hostFunction: HostFunctionXDR,
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Shared low-level multi-signer signing pipeline. Validates the complete signer set, simulates the host function to discover authorization entries, signs every matching entry with every supplied signer, re-simulates so the resource fees reflect the real signature payload size, and submits the final envelope. The three higher-level entry points delegate here; the signer, policy, and context-rule managers also reach this method internally when a non-empty `selectedSigners` list is supplied to one of their state-changing methods.

Validation order: connection check, per-wallet-signer reachability via `kit.externalSigners.canSignFor(address:)` (covers both in-memory keypairs and the configured wallet adapter), per-passkey-signer `keyData` precondition (every passkey entry must carry pre-fetched `keyData` so context-rule resolution and signature binding can run without an extra on-chain lookup), per-Ed25519-signer registration check via `kit.externalSigners.canSignEd25519For(verifierAddress:publicKey:)` and public-key length enforcement (must be 32 bytes), initial simulation surface error, re-simulation surface error.

**Throws**: `WalletException`, `ValidationException`, `TransactionException`, `WebAuthnException`, `ConfigurationException`.

### SelectedSigner

```swift
public enum SelectedSigner: Sendable, Hashable {
    case passkey(
        credentialId: String,
        credentialIdBytes: Data? = nil,
        keyData: Data? = nil,
        transports: [String]? = nil
    )
    case wallet(accountId: String)
    case ed25519(verifierAddress: String, publicKey: Data)
}
```

A signer selected for participation in a multi-signer authorization ceremony. Three kinds of signers are supported: WebAuthn passkeys, delegated Stellar wallet accounts, and Ed25519 external signers backed by a verifier contract.

`passkey`:
- `credentialId` — Base64URL-encoded WebAuthn credential identifier.
- `credentialIdBytes` — Optional raw credential identifier bytes. When supplied, the multi-signer pipeline includes a matching `AllowCredential` (with `transports`) on the WebAuthn authentication request so the OS can route to the correct passkey. When `nil`, the authenticator falls back to its default credential discovery.
- `keyData` — Optional pre-fetched secp256r1 public key followed by credential id bytes (`publicKey || credentialId`). Supplying this avoids an indexer lookup during signature collection. In multi-signer ceremonies every `passkey` entry must carry non-`nil` `keyData`; the auth pipeline reconstructs external signers once per call, not per entry, so a `nil` entry fails at runtime.
- `transports` — Optional WebAuthn transport hints (`"internal"`, `"hybrid"`, `"usb"`, `"ble"`, `"nfc"`) propagated into the `AllowCredential` when `credentialIdBytes` is non-`nil`.

`wallet`:
- `accountId` — Stellar `G…` strkey of the wallet that will produce the signature. The signing source is resolved via `kit.externalSigners`: an in-memory keypair registered via `kit.externalSigners.addFromSecret(secretKey:)` takes precedence; when no in-memory keypair is registered for the address, the configured `ExternalWalletAdapter` is used.

`ed25519`:
- `verifierAddress` — C-strkey of the Ed25519 verifier contract registered as part of the on-chain `External(verifierAddress, publicKey)` signer entry. The smart-account contract calls this verifier during `__check_auth` to validate the Ed25519 signature.
- `publicKey` — 32-byte Ed25519 public key that identifies the signer slot on the smart account. Must match the public key registered in the on-chain signer entry.

The `ed25519` case carries no signing material. It is purely an identifier; the actual signing capability is provided by registering an in-memory keypair via `kit.externalSigners.addEd25519FromRawKey(secretKeyBytes:verifierAddress:)` at runtime, or by supplying an `OZExternalEd25519SignerAdapter` via `config.externalEd25519Adapter` at kit construction.

```swift
// Example: transfer authorized by three different signer kinds in one call.
let ed25519VerifierAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

// 1. Build the config. For the wallet signer, supply a wallet adapter at construction time
//    if the key is managed externally; omit it if you will register an in-memory keypair
//    at runtime. For the Ed25519 signer, supply an adapter via externalEd25519Adapter
//    for out-of-process signing, or register an in-memory key after kit construction.
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY",
    externalWallet: myExternalWalletAdapter   // optional; omit for in-memory wallet keypair path
)
let kit = OZSmartAccountKit.create(config: config)

// 2. Register the Ed25519 signing key in memory at runtime.
//    rawSecretKeyBytes must be exactly 32 bytes (the raw Ed25519 seed).
let derivedPublicKey = try kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSecretKeyBytes,
    verifierAddress: ed25519VerifierAddress
)

// 3. Call the multi-signer method; kit.externalSigners resolves signing sources.
let result = try await kit.multiSignerManager.multiSignerTransfer(
    tokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
    recipient: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
    amount: "10",
    selectedSigners: [
        .passkey(credentialId: savedCredId, keyData: savedKeyData),
        .wallet(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"),
        .ed25519(verifierAddress: ed25519VerifierAddress, publicKey: derivedPublicKey)
    ]
)
```

---

## External Signer Management

```swift
public actor OZExternalSignerManager
```

Manager for non-passkey signers used by multi-signer smart-account operations. Coordinates Stellar account signers (raw Ed25519 secret keys in memory or external wallet connections through `ExternalWalletAdapter`), and Ed25519 signers identified by a `(verifierAddress, publicKey)` tuple. The kit constructs and owns one instance, accessible via `kit.externalSigners`. Two custody models are available for each signer kind: supply an adapter at kit-construction time via the config, or register an in-memory key at runtime via the manager methods.

```swift
public init(
    networkPassphrase: String,
    walletAdapter: ExternalWalletAdapter? = nil,
    walletConnectionStorage: WalletConnectionStorage? = nil,
    ed25519Adapter: OZExternalEd25519SignerAdapter? = nil
)
```

`walletAdapter` enables wallet-based signers via `addFromWallet()`. `walletConnectionStorage` persists wallet-connection metadata for cross-launch restoration via `restoreConnections()`; when `nil`, the manager's wallet connections are in-memory only. `ed25519Adapter` provides out-of-process Ed25519 signing at construction time; in-memory keypairs are registered at runtime via `addEd25519FromRawKey(secretKeyBytes:verifierAddress:)`. Keypair signers are never persisted — secret material is reachable only through the in-memory `KeyPair` instance.

The kit-owned instance (accessed via `kit.externalSigners`) is constructed with `walletConnectionStorage: nil`, so `restoreConnections()` is a no-op on that instance. For cross-launch wallet-connection persistence, the demo or application layer should construct its own `OZExternalSignerManager` with a non-`nil` storage.

All public methods are `async` (or `async throws`) due to actor isolation.

### Static Constants

```swift
public static let walletStorageKey: String = "oz_smart_account.connected_wallets"
```

Storage key under which the manager persists wallet connections in the supplied `WalletConnectionStorage`. Exposed for diagnostic and migration tooling; production code should prefer the manager API.

### Properties

#### hasWalletAdapter

```swift
public var hasWalletAdapter: Bool { get }
```

`true` when a non-`nil` `walletAdapter` was supplied at construction time.

### Methods

#### addFromSecret(secretKey:)

```swift
public func addFromSecret(secretKey: String) async throws -> String
```

Decodes the supplied Stellar `S…` secret-key strkey into an in-memory `KeyPair` and registers it as a signer. Returns the corresponding `G…` account address.

**Throws**: `SignerException.Invalid` when the secret key is malformed.

#### addFromWallet()

```swift
public func addFromWallet() async throws -> ConnectedWallet?
```

Prompts the configured `walletAdapter` to connect a new wallet and registers it as a signer. Returns the resulting `ConnectedWallet` value, or `nil` if the adapter reports no connection. Persists the connection metadata into `walletConnectionStorage`.

**Throws**: `ConfigurationException.MissingConfig` when no wallet adapter is configured; `SignerException.Invalid` when the adapter reports a malformed connection.

#### canSignFor(address:)

```swift
public func canSignFor(address: String) async -> Bool
```

`true` when the manager has either a keypair-based signer or a wallet-based signer registered for the given `G…` address.

#### get(address:)

```swift
public func get(address: String) async -> ExternalSignerInfo?
```

Returns the registered signer metadata for the given address, or `nil` when none exists.

#### getAll()

```swift
public func getAll() async -> [ExternalSignerInfo]
```

Returns metadata for every registered signer.

#### hasSigners()

```swift
public func hasSigners() async -> Bool
```

`true` when at least one signer (keypair or wallet) is registered.

#### signAuthEntry(address:authEntry:)

```swift
public func signAuthEntry(
    address: String,
    authEntry: String
) async throws -> SignAuthEntryResult
```

Signs a base64-encoded Soroban authorization preimage on behalf of the named signer. Keypair signers run an in-process Ed25519 sign; wallet signers delegate to the configured `walletAdapter`. Returns a `SignAuthEntryResult` containing the signature and (when available) the address that produced it.

**Throws**: `SignerException.NotFound` when no signer matches the address; `TransactionException.SigningFailed` when signing fails.

#### remove(address:)

```swift
public func remove(address: String) async throws
```

Removes the signer registered for the supplied address, clearing any persisted wallet-connection metadata.

**Throws**: `SignerException.NotFound` when no signer matches.

#### removeAll()

```swift
public func removeAll() async throws
```

Removes every registered signer: clears all in-memory keypair signers (registered via `addFromSecret`), clears all Ed25519 keypairs (registered via `addEd25519FromRawKey`), disconnects all external wallets, and removes all persisted wallet-connection records.

#### restoreConnections()

```swift
public func restoreConnections() async throws -> [ConnectedWallet]
```

Reads the persisted wallet connections from `walletConnectionStorage` and rebuilds the registered-signer set for the wallet-based signers. Idempotent within a single instance — the second invocation returns the same connection list without re-reading storage.

**Throws**: `ConfigurationException.MissingConfig` when no wallet adapter or no connection storage is configured.

#### addEd25519FromRawKey(secretKeyBytes:verifierAddress:)

```swift
public func addEd25519FromRawKey(secretKeyBytes: Data, verifierAddress: String) throws -> Data
```

Creates an Ed25519 keypair from the supplied raw 32-byte secret seed and registers it in memory under the `(verifierAddress, publicKey)` tuple. The keypair is never persisted to storage; it is cleared when `removeEd25519(verifierAddress:publicKey:)` is called or when the manager is deinitialized.

If a keypair is already registered for the same tuple, it is silently overwritten.

**Parameters**:
- `secretKeyBytes`: Raw 32-byte Ed25519 secret seed. Must be exactly 32 bytes.
- `verifierAddress`: C-strkey of the Ed25519 verifier contract under which this key is registered on-chain.

**Returns**: The derived 32-byte Ed25519 public key. Pass this as the `publicKey` argument of `SelectedSigner.ed25519(verifierAddress:publicKey:)` to route multi-signer signing through this keypair.

**Throws**: `ValidationException.InvalidInput` when `secretKeyBytes` is not exactly 32 bytes; `SignerException.Invalid` when keypair construction fails from the supplied seed.

```swift
// Create the kit first.
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
)
let kit = OZSmartAccountKit.create(config: config)

// Register the Ed25519 signing key in memory at runtime.
let ed25519VerifierAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
// rawSecretKeyBytes is the raw 32-byte Ed25519 seed (not a Stellar S-strkey).
let ed25519PublicKey = try kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSecretKeyBytes,
    verifierAddress: ed25519VerifierAddress
)

// Pass the identifier to the multi-signer call.
let signer = SelectedSigner.ed25519(
    verifierAddress: ed25519VerifierAddress,
    publicKey: ed25519PublicKey
)
```

See also: [`SelectedSigner.ed25519`](#selectedsigner) in the Multi-Signer Operations section.

#### canSignEd25519For(verifierAddress:publicKey:)

```swift
public func canSignEd25519For(verifierAddress: String, publicKey: Data) -> Bool
```

Registry lookup that returns `true` when a signing source is available for the given `(verifierAddress, publicKey)` tuple. Checks the adapter (supplied via `config.externalEd25519Adapter`) first: if `adapter.canSignFor(verifierAddress:publicKey:)` returns `true`, this method returns `true` without consulting the in-memory registry. Falls back to checking whether an in-memory keypair is registered for the tuple.

This method is synchronous (no `await` needed) because actor isolation guarantees serial access to the in-memory registry, and `OZExternalEd25519SignerAdapter.canSignFor` is synchronous by contract.

**Parameters**:
- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot.

**Returns**: `true` when a signing source (adapter or in-memory keypair) can sign for this tuple.

#### signEd25519AuthDigest(verifierAddress:publicKey:authDigest:)

```swift
public func signEd25519AuthDigest(
    verifierAddress: String,
    publicKey: Data,
    authDigest: Data
) async throws -> Data
```

Produces a 64-byte Ed25519 signature over the supplied auth digest. Resolves the signing source using adapter-first precedence: the adapter is consulted first; if it claims it can sign, it signs. Otherwise the in-memory keypair registry is used. Throws when neither source is available.

The multi-signer pipeline calls this method automatically for each `SelectedSigner.ed25519(...)` entry in `selectedSigners`. Direct calls are available for advanced integrations that need to produce signatures outside the pipeline.

**Parameters**:
- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot.
- `authDigest`: 32-byte auth digest to sign, computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.

**Returns**: 64-byte raw Ed25519 signature over `authDigest`.

**Throws**: `ValidationException.InvalidInput` (field `"selectedSigners"`) when no signing source is registered; `TransactionException.SigningFailed` when the adapter or in-memory keypair fails to produce a valid signature.

> **Quirk — adapter-first precedence**: when an `OZExternalEd25519SignerAdapter` is supplied via `config.externalEd25519Adapter` and its `canSignFor(verifierAddress:publicKey:)` returns `true`, the adapter always signs, even if an in-memory keypair is also registered for the same tuple. To force the in-memory path, construct the kit without `externalEd25519Adapter`.

> **Quirk — tuple-keyed storage**: the same 32-byte public key registered under two different verifier addresses is stored as two distinct entries. This matches the on-chain signer identity, where an `External(verifierAddress, publicKey)` entry is uniquely identified by both fields. Passing the wrong `verifierAddress` results in `ValidationException.InvalidInput` even when the public key is correct.

See also: [`OZExternalEd25519SignerAdapter`](#external-signer-management).

#### removeEd25519(verifierAddress:publicKey:)

```swift
public func removeEd25519(verifierAddress: String, publicKey: Data)
```

Removes the keypair registered under `(verifierAddress, publicKey)` from the in-memory registry. No-op when no keypair is registered for that tuple. The adapter supplied via `config.externalEd25519Adapter` is not affected by this call.

**Parameters**:
- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot to remove.

### Supporting Types

#### OZExternalEd25519SignerAdapter

```swift
public protocol OZExternalEd25519SignerAdapter: Sendable {
    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool
    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data
}
```

Adapter protocol for out-of-process Ed25519 signing sources such as hardware wallets and remote signing services. Supply a conforming instance via `config.externalEd25519Adapter` at kit construction to intercept signing requests before the in-memory keypair registry is consulted.

`canSignFor(verifierAddress:publicKey:)`:
- Called synchronously by the pipeline before every Ed25519 sign request.
- `verifierAddress` — C-strkey of the Ed25519 verifier contract.
- `publicKey` — 32-byte Ed25519 public key identifying the signer slot.
- Return `true` if and only if a subsequent `signAuthDigest(authDigest:publicKey:)` call for the same `publicKey` will succeed without error. The pipeline trusts this return value.

`signAuthDigest(authDigest:publicKey:)`:
- Called only when `canSignFor` returned `true` for the same `publicKey`.
- `authDigest` — 32-byte digest computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
- `publicKey` — the same 32-byte Ed25519 public key passed to `canSignFor`.
- Returns a 64-byte raw Ed25519 signature over `authDigest`. The pipeline locally verifies the returned signature via `KeyPair.verify(signature:message:)` before incorporating it into the authorization payload; a wrong signature throws `TransactionException.SigningFailed`.
- Throws any error that prevents signing (hardware unavailable, user cancelled, etc.).

```swift
// Example adapter for a hypothetical hardware wallet.
final class MyHardwareWalletAdapter: OZExternalEd25519SignerAdapter {
    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool {
        // Check whether the hardware wallet holds the key for this public key.
        return hardwareWallet.hasSigner(for: publicKey)
    }

    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data {
        // Request a 64-byte Ed25519 signature from the hardware wallet.
        return try await hardwareWallet.sign(digest: authDigest, publicKey: publicKey)
    }
}

// Supply the adapter via config.externalEd25519Adapter at kit construction.
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
    webauthnVerifierAddress: "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY",
    externalEd25519Adapter: MyHardwareWalletAdapter()
)
let kit = OZSmartAccountKit.create(config: config)
// kit.externalSigners automatically uses the adapter for signing.
```

> **Quirk — adapter-first precedence**: the adapter always signs when `canSignFor` returns `true`, even when an in-memory keypair is registered for the same `(verifierAddress, publicKey)` pair. To force the in-memory path, construct the kit without `externalEd25519Adapter`.

See also: [`OZExternalSignerManager.signEd25519AuthDigest`](#external-signer-management).

#### ExternalSignerType

```swift
public enum ExternalSignerType: String, Sendable, Codable, CaseIterable {
    case keypair = "KEYPAIR"
    case wallet = "WALLET"
}
```

#### ExternalSignerInfo

```swift
public struct ExternalSignerInfo: Sendable, Codable, Equatable, Hashable {
    public let address: String
    public let type: ExternalSignerType
    public let walletName: String?
    public let walletId: String?
}
```

`walletName` and `walletId` are populated only when `type == .wallet`.

#### WalletConnectionStorage

```swift
public protocol WalletConnectionStorage: Sendable {
    func getItem(key: String) async throws -> String?
    func setItem(key: String, value: String) async throws
    func removeItem(key: String) async throws
}
```

Simple key-value storage interface for persisting external wallet connections. Implementations must be safe to call from arbitrary concurrent contexts.

#### InMemoryWalletConnectionStorage

```swift
public actor InMemoryWalletConnectionStorage: WalletConnectionStorage {
    public init()
}
```

In-memory implementation. Used when no `WalletConnectionStorage` is supplied to the manager. Data is not persisted across application restarts.

#### ConnectedWallet

```swift
public struct ConnectedWallet: Sendable, Equatable, Hashable
```

Wallet-connection record returned by `addFromWallet()` and `restoreConnections()`.

#### SignAuthEntryOptions / SignAuthEntryResult

```swift
public struct SignAuthEntryOptions: Sendable, Equatable, Hashable
public struct SignAuthEntryResult: Sendable, Equatable, Hashable
```

Options bag and result value used by `ExternalWalletAdapter.signAuthEntry(preimageXdr:options:)` and by `OZExternalSignerManager.signAuthEntry(...)`.

---

## Events

> **Scope — SDK lifecycle events only.** `kit.events` emits **kit-level** events (wallet connected/disconnected, credential created/deleted, session expired, transaction signed/submitted). It does **not** emit on-chain smart-account contract events such as `SignerAdded`, `SignerRemoved`, `PolicyInstalled`, `PolicyRemoved`, `ContextRuleAdded`, or `ContextRuleRemoved`. Those are emitted by the OpenZeppelin smart-account contract and must be queried via `SorobanServer.getEvents(...)` with the account's contract ID as a filter.
>
> To fetch on-chain contract events (after the wallet is connected):
>
> ```swift
> let filter = EventFilter(
>     type: "contract",
>     contractIds: [contractId]
> )
> let response = await kit.sorobanServer.getEvents(
>     startLedger: fromLedger,
>     eventFilters: [filter]
> )
> switch response {
> case .success(let eventsResponse):
>     for event in eventsResponse.events {
>         // event.topic and event.value are base64-XDR-encoded SCVal entries
>     }
> case .failure(let error):
>     // handle error
> }
> ```
>
> Each event's `topic` and `value` are base64-XDR-encoded `SCVal` entries that can be parsed with the SDK's XDR utilities.

```swift
public final class SmartAccountEventEmitter: @unchecked Sendable { ... }
```

Accessed via `kit.events`. Manages event subscriptions and dispatches events to all registered listeners. Subscription management and event emission are thread-safe; listener callbacks are invoked outside the internal lock so a listener may freely call back into the emitter (for example to unsubscribe itself) without deadlocking.

The emitter's public API is synchronous on purpose — async listener registration would force an extra suspension that would lose ordering for self-unsubscribe operations performed from inside `emit`.

### init()

```swift
public init()
```

Initializes an emitter with no listeners and no error handler. Production code obtains the kit-owned emitter through `kit.events`; direct construction is supported for advanced integrations and unit tests.

### setErrorHandler(_:)

```swift
public func setErrorHandler(_ handler: SmartAccountEventErrorHandler?)
```

Sets the error handler invoked when a listener throws. The error handler receives both the event being dispatched and the error thrown by the failing listener. Pass `nil` to disable error reporting (listener errors are then silently caught so a single failing listener cannot abort emission to the remaining listeners).

### addListener(_:)

```swift
@discardableResult
public func addListener(_ listener: @escaping SmartAccountEventListener) -> SmartAccountEventUnsubscribe
```

Subscribes a global listener that receives every emitted event regardless of type. Use this from call sites that dispatch with a `switch` over the event itself. Returns a closure that unsubscribes the listener when called; calling the returned closure more than once is a no-op.

### on(_:listener:)

```swift
@discardableResult
public func on(
    _ eventType: SmartAccountEventType,
    listener: @escaping SmartAccountEventListener
) -> SmartAccountEventUnsubscribe
```

Subscribes to events of a specific type. The listener is invoked only when an event matching `eventType` is emitted.

### once(_:listener:)

```swift
@discardableResult
public func once(
    _ eventType: SmartAccountEventType,
    listener: @escaping SmartAccountEventListener
) -> SmartAccountEventUnsubscribe
```

Subscribes to a single occurrence of an event type. The listener is automatically unsubscribed before its body runs, so even a throwing listener is still removed exactly once. The returned closure unsubscribes the listener before it ever fires; calling it after the event has already fired is a no-op.

### removeAllListeners(eventType:)

```swift
public func removeAllListeners(eventType: String? = nil)
public func removeAllListeners()
```

When `eventType` is non-`nil`, only type-specific listeners registered via `on(_:listener:)` for that event type are removed; global listeners registered via `addListener(_:)` are left intact. Passing `nil` (or calling the no-argument overload) removes every type-specific listener and every global listener.

### listenerCount(eventType:)

```swift
public func listenerCount(eventType: String) -> Int
```

Returns the number of listeners currently registered for the supplied event tag. The count is the sum of type-specific listeners registered for `eventType` plus every global listener registered via `addListener(_:)`.

### SmartAccountEvent

```swift
public enum SmartAccountEvent: Sendable, Equatable, Hashable {
    case walletConnected(contractId: String, credentialId: String)
    case walletDisconnected(contractId: String)
    case credentialCreated(credential: StoredCredential)
    case credentialDeleted(credentialId: String)
    case sessionExpired(contractId: String, credentialId: String)
    case transactionSigned(contractId: String, credentialId: String?)
    case transactionSubmitted(hash: String, success: Bool)
    case credentialSyncFailed(credentialId: String, error: Error)

    public var eventTypeTag: String { get }
}
```

| Arm | Payload | Emitted when |
|---|---|---|
| `walletConnected` | `contractId, credentialId` | A wallet is connected (fresh registration or session restore). |
| `walletDisconnected` | `contractId` | `kit.disconnect()` is called. The session is cleared; stored credentials remain. |
| `credentialCreated` | `credential` | A WebAuthn credential is registered (during initial wallet setup or when adding a new signer). The wallet may not be deployed yet. |
| `credentialDeleted` | `credentialId` | A credential is removed from storage. |
| `sessionExpired` | `contractId, credentialId` | A connect attempt finds an expired session. The application should prompt to reconnect. |
| `transactionSigned` | `contractId, credentialId?` | All required signatures are collected for a transaction, before submission. `credentialId` is `nil` when only external signers contributed. |
| `transactionSubmitted` | `hash, success` | A signed transaction is sent to Soroban RPC or the relayer. `success` indicates whether the submission succeeded at the network boundary, not whether the transaction was included in a ledger. |
| `credentialSyncFailed` | `credentialId, error` | `OZCredentialManager.sync(credentialId:)` cannot reach the RPC endpoint. The credential is retained in storage so a subsequent sync can retry. |

`eventTypeTag` returns the un-namespaced arm name (`"WalletConnected"`, `"WalletDisconnected"`, etc.) and matches the strings consumed by `removeAllListeners(eventType:)` and `listenerCount(eventType:)`. Equality on the `credentialSyncFailed` arm compares `error.localizedDescription` because `Error` does not conform to `Equatable`.

### SmartAccountEventType

```swift
public enum SmartAccountEventType: String, Sendable, CaseIterable {
    case walletConnected = "WalletConnected"
    case walletDisconnected = "WalletDisconnected"
    case credentialCreated = "CredentialCreated"
    case credentialDeleted = "CredentialDeleted"
    case sessionExpired = "SessionExpired"
    case transactionSigned = "TransactionSigned"
    case transactionSubmitted = "TransactionSubmitted"
    case credentialSyncFailed = "CredentialSyncFailed"

    public var tag: String { get }
}
```

Type-tag enumeration used to register typed subscriptions. The raw value is the stable string key consumed by `removeAllListeners(eventType:)` and `listenerCount(eventType:)`.

### Typealiases

```swift
public typealias SmartAccountEventListener = @Sendable (SmartAccountEvent) throws -> Void
public typealias SmartAccountEventErrorHandler = @Sendable (SmartAccountEvent, Error) -> Void
public typealias SmartAccountEventUnsubscribe = @Sendable () -> Void
```

The listener may throw; the emitter catches the error and routes it to the configured error handler so a failing listener never aborts dispatch to the remaining registrants. The unsubscribe closure is the only mechanism for listener removal — there is no `removeListener(handle:)` method.

---

## Errors

Every error path in the kit funnels into a `SmartAccountException` subclass so callers can rely on a single typed channel for error handling and can map errors back to a stable numeric `SmartAccountErrorCode`.

### SmartAccountErrorCode

> **Two independent namespaces share the 3xxx range.** `SmartAccountErrorCode` is the **SDK** error enum, surfaced via `SmartAccountException.code` when the kit raises a credential / wallet / WebAuthn / etc. error locally. A separate set of error codes — also in the 3xxx range — is defined by the **on-chain** OpenZeppelin smart-account contract and surfaced in transaction simulation / result XDR (typically wrapped in `TransactionException.simulationFailed`). The two overlap but do not collide at runtime because they arrive through different channels:
>
> | Numeric code | SDK meaning (`SmartAccountErrorCode`) | On-chain meaning (OZ contract) |
> |---|---|---|
> | 3002 | `.credentialAlreadyExists` | `UnvalidatedContext` |
> | 3003 | `.credentialInvalid` | `ExternalVerificationFailed` |
>
> The table above shows only the two codes the SDK enum reuses; the on-chain enum spans `3000` and `3002`-`3016`. When inspecting an error code, first check the exception type to determine which namespace it belongs to. SDK-defined contract codes that the SDK interprets directly are declared in [`ContractErrorCodes`](#contracterrorcodes); see the [OpenZeppelin contracts source](https://github.com/OpenZeppelin/stellar-contracts/blob/main/packages/accounts/src/smart_account/mod.rs) for the full on-chain `SmartAccountError` enum, along with the `WebAuthnError` and policy error enums.


```swift
public enum SmartAccountErrorCode: Int, Sendable, CaseIterable {
    case invalidConfig = 1001
    case missingConfig = 1002
    case walletNotConnected = 2001
    case walletAlreadyExists = 2002
    case walletNotFound = 2003
    case credentialNotFound = 3001
    case credentialAlreadyExists = 3002
    case credentialInvalid = 3003
    case credentialDeploymentFailed = 3004
    case webAuthnRegistrationFailed = 4001
    case webAuthnAuthenticationFailed = 4002
    case webAuthnNotSupported = 4003
    case webAuthnCancelled = 4004
    case transactionSimulationFailed = 5001
    case transactionSigningFailed = 5002
    case transactionSubmissionFailed = 5003
    case transactionTimeout = 5004
    case signerNotFound = 6001
    case signerInvalid = 6002
    case invalidAddress = 7001
    case invalidAmount = 7002
    case invalidInput = 7003
    case storageReadFailed = 8001
    case storageWriteFailed = 8002
    case sessionExpired = 9001
    case sessionInvalid = 9002
    case indexerRequestFailed = 10001
    case indexerTimeout = 10002

    public var code: Int { get }
}
```

Code ranges: `1xxx` configuration, `2xxx` wallet state, `3xxx` credential, `4xxx` WebAuthn, `5xxx` transaction, `6xxx` signer, `7xxx` validation, `8xxx` storage, `9xxx` session, `10xxx` indexer.

### SmartAccountException

```swift
public class SmartAccountException: Error, CustomStringConvertible, @unchecked Sendable {
    public let code: SmartAccountErrorCode
    public let message: String
    public let cause: Error?
    public var description: String { get }

    public static func wrapError(
        _ err: Error,
        defaultCode: SmartAccountErrorCode = .invalidInput
    ) -> SmartAccountException
}
```

The base class is not directly constructible by consumers (its initializer is `fileprivate`). `wrapError(_:defaultCode:)` maps any `Error` into the matching subclass; if the input is already a `SmartAccountException`, it is returned unchanged so typed information is preserved through pass-through layers.

### Domain Subclasses

Every grouping below is `public class ... : SmartAccountException` with `public final class` arm subclasses. Construct arm instances through the factory methods on each grouping rather than the initializers.

#### ConfigurationException

```swift
public class ConfigurationException: SmartAccountException {
    public final class InvalidConfig: ConfigurationException { ... }
    public final class MissingConfig: ConfigurationException { ... }

    public static func invalidConfig(details: String, cause: Error? = nil) -> InvalidConfig
    public static func missingConfig(param: String, cause: Error? = nil) -> MissingConfig
}
```

Thrown by `OZSmartAccountConfig` validation, by URL validation in `OZIndexerClient` / `OZRelayerClient`, by `AppleWebAuthnProvider` initialization, and by managers when a required collaborator is missing.

#### WalletException

```swift
public class WalletException: SmartAccountException {
    public final class NotConnected: WalletException { ... }
    public final class AlreadyExists: WalletException { ... }
    public final class NotFound: WalletException { ... }

    public static func notConnected(details: String? = nil, cause: Error? = nil) -> NotConnected
    public static func alreadyExists(identifier: String, cause: Error? = nil) -> AlreadyExists
    public static func notFound(identifier: String, cause: Error? = nil) -> NotFound
}
```

`NotConnected` is thrown by every state-changing manager method when the kit is not connected. `NotFound` is thrown by `connectWallet(...)` when no contract can be resolved for the credential.

#### CredentialException

```swift
public class CredentialException: SmartAccountException {
    public final class NotFound: CredentialException { ... }
    public final class AlreadyExists: CredentialException { ... }
    public final class Invalid: CredentialException { ... }
    public final class DeploymentFailed: CredentialException { ... }

    public static func notFound(credentialId: String, cause: Error? = nil) -> NotFound
    public static func alreadyExists(credentialId: String, cause: Error? = nil) -> AlreadyExists
    public static func invalid(reason: String, cause: Error? = nil) -> Invalid
    public static func deploymentFailed(reason: String, cause: Error? = nil) -> DeploymentFailed
}
```

Thrown by `OZCredentialManager` and by the wallet-operations module during credential creation and lifecycle transitions.

#### WebAuthnException

```swift
public class WebAuthnException: SmartAccountException {
    public final class RegistrationFailed: WebAuthnException { ... }
    public final class AuthenticationFailed: WebAuthnException { ... }
    public final class NotSupported: WebAuthnException { ... }
    public final class Cancelled: WebAuthnException { ... }

    public static func registrationFailed(reason: String, cause: Error? = nil) -> RegistrationFailed
    public static func authenticationFailed(reason: String, cause: Error? = nil) -> AuthenticationFailed
    public static func notSupported(details: String? = nil, cause: Error? = nil) -> NotSupported
    public static func cancelled(cause: Error? = nil) -> Cancelled
}
```

`NotSupported` is thrown when a flow requires a WebAuthn provider but none is configured. `Cancelled` is thrown when the user cancels a passkey prompt.

#### TransactionException

```swift
public class TransactionException: SmartAccountException {
    public final class SimulationFailed: TransactionException { ... }
    public final class SigningFailed: TransactionException { ... }
    public final class SubmissionFailed: TransactionException { ... }
    public final class Timeout: TransactionException { ... }

    public static func simulationFailed(reason: String, cause: Error? = nil) -> SimulationFailed
    public static func signingFailed(reason: String, cause: Error? = nil) -> SigningFailed
    public static func submissionFailed(reason: String, cause: Error? = nil) -> SubmissionFailed
    public static func timeout(details: String? = nil, cause: Error? = nil) -> Timeout
}
```

`SimulationFailed` is the common arm thrown by every read-only context-rule method when the on-chain rule does not exist.

#### SignerException

```swift
public class SignerException: SmartAccountException {
    public final class NotFound: SignerException { ... }
    public final class Invalid: SignerException { ... }

    public static func notFound(signerId: String, cause: Error? = nil) -> NotFound
    public static func invalid(reason: String, cause: Error? = nil) -> Invalid
}
```

#### ValidationException

```swift
public class ValidationException: SmartAccountException {
    public final class InvalidAddress: ValidationException { ... }
    public final class InvalidAmount: ValidationException { ... }
    public final class InvalidInput: ValidationException { ... }

    public static func invalidAddress(address: String, cause: Error? = nil) -> InvalidAddress
    public static func invalidAmount(amount: String, reason: String? = nil, cause: Error? = nil) -> InvalidAmount
    public static func invalidInput(field: String, reason: String, cause: Error? = nil) -> InvalidInput
}
```

#### StorageException

```swift
public class StorageException: SmartAccountException {
    public final class ReadFailed: StorageException { ... }
    public final class WriteFailed: StorageException { ... }

    public static func readFailed(key: String, cause: Error? = nil) -> ReadFailed
    public static func writeFailed(key: String, cause: Error? = nil) -> WriteFailed
}
```

#### SessionException

```swift
public class SessionException: SmartAccountException {
    public final class Expired: SessionException { ... }
    public final class Invalid: SessionException { ... }

    public static func expired(sessionId: String? = nil, cause: Error? = nil) -> Expired
    public static func invalid(reason: String, cause: Error? = nil) -> Invalid
}
```

#### IndexerException

```swift
public class IndexerException: SmartAccountException {
    public final class RequestFailed: IndexerException { ... }
    public final class Timeout: IndexerException { ... }

    public static func requestFailed(reason: String, cause: Error? = nil) -> RequestFailed
    public static func timeout(url: String, cause: Error? = nil) -> Timeout
}
```

### ContractErrorCodes

```swift
public enum ContractErrorCodes { ... }
```

Namespace exposing the on-chain error codes the smart-account contract may surface during simulation or submission:

| Code | Name |
|---|---|
| 3012 | `mathOverflow` |
| 3013 | `keyDataTooLarge` |
| 3014 | `contextRuleIdsLengthMismatch` |
| 3015 | `nameTooLong` |
| 3016 | `unauthorizedSigner` |

These integers appear inside `TransactionException.SimulationFailed` / `SubmissionFailed` messages when the contract refuses an operation.

---

## Constants

### SmartAccountConstants

```swift
public enum SmartAccountConstants {
    public static let ed25519PublicKeySize: Int = 32
    public static let secp256r1PublicKeySize: Int = 65
    public static let uncompressedPubkeyPrefix: UInt8 = 0x04
}
```

Cryptographic-shape constants used by the validation paths in `OZExternalSigner`, `OZCredentialManager`, and the WebAuthn pipeline.

### OZConstants

```swift
public enum OZConstants {
    public static let defaultSessionExpiryMs: Int64 = 604_800_000  // 7 days
    public static let defaultIndexerTimeoutMs: Int64 = 10_000      // 10 seconds
    public static let defaultRelayerTimeoutMs: Int64 = 360_000     // 6 minutes
    public static let webAuthnTimeoutMs: Int64 = 60_000            // 60 seconds
    public static let friendbotReserveXlm: Int = 5
    public static let defaultTimeoutSeconds: Int = 30
    public static let maxSigners: Int = 15
    public static let maxPolicies: Int = 5
    public static let clientNameHeader: String = "X-Client-Name"
    public static let clientVersionHeader: String = "X-Client-Version"
    public static let clientName: String = "ios-stellar-sdk"
    public static let maxIndexerResponseBytes: Int = 1 * 1024 * 1024
    public static let maxRelayerResponseBytes: Int = 256 * 1024
}
```

Timeouts and budgets used by the kit, the WebAuthn provider, and the HTTP clients. `maxSigners` and `maxPolicies` are the contract limits enforced at validation time inside `OZContextRuleManager.addContextRule(...)`. `friendbotReserveXlm` is the protocol minimum-balance reserve retained on the funded temporary account during `OZTransactionOperations.fundWallet(...)`. The HTTP identification headers are pinned at the `URLSession` configuration layer by both `OZIndexerClient` and `OZRelayerClient`.

---

## WebAuthn Provider

### WebAuthnProvider (protocol)

```swift
public protocol WebAuthnProvider: Sendable {
    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult

    func authenticate(
        challenge: Data,
        allowCredentials: [AllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult
}
```

Abstraction over platform WebAuthn ceremonies. Implementations must:
- Throw `WebAuthnException.RegistrationFailed` / `AuthenticationFailed` for ceremony-side failures.
- Throw `WebAuthnException.NotSupported` when the platform cannot run the ceremony.
- Throw `WebAuthnException.Cancelled` when the user cancels the prompt.

Custom implementations are supported. Most consumers use the bundled `AppleWebAuthnProvider` on iOS 16+ / macOS 13+.

### WebAuthnRegistrationResult

```swift
public struct WebAuthnRegistrationResult: Equatable, Hashable, Sendable {
    public let credentialId: Data
    public let publicKey: Data
    public let attestationObject: Data
    public let transports: [String]?
    public let deviceType: String?
    public let backedUp: Bool?
}
```

`publicKey` is the COSE-formatted public key bytes returned by the platform; consumers that need the canonical uncompressed 65-byte secp256r1 form pass it through `SmartAccountUtils.extractPublicKeyFromRegistration(publicKey:authenticatorData:attestationObject:)`. `deviceType` is `"singleDevice"` (hardware security key, not synced) or `"multiDevice"` (synced passkey). Equality compares byte fields in constant time.

### WebAuthnAuthenticationResult

```swift
public struct WebAuthnAuthenticationResult: Equatable, Hashable, Sendable {
    public let credentialId: Data
    public let authenticatorData: Data
    public let clientDataJSON: Data
    public let signature: Data
}
```

`signature` is in DER form as returned by the platform; pass it through `SmartAccountUtils.normalizeSignature(_:)` to produce the compact 64-byte low-S form expected by the on-chain verifier.

### AllowCredential

```swift
public struct AllowCredential: Equatable, Hashable, Sendable {
    public let id: Data
    public let transports: [String]?

    public static func fromId(_ id: Data) -> AllowCredential
    public static func fromIds(_ ids: [Data]) -> [AllowCredential]
}
```

Credential descriptor passed to `WebAuthnProvider.authenticate(challenge:allowCredentials:)` to restrict the authenticator picker. Transport hints (`"internal"`, `"hybrid"`, `"usb"`, `"ble"`, `"nfc"`) are advisory.

### AppleWebAuthnProvider

```swift
@available(iOS 16.0, macOS 13.0, *)
public final class AppleWebAuthnProvider: NSObject, WebAuthnProvider, @unchecked Sendable {
    public let rpId: String
    public let rpName: String
    public let timeout: Int64
    public var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?

    public init(
        rpId: String,
        rpName: String,
        timeout: Int64 = OZConstants.webAuthnTimeoutMs
    ) throws

    public static func create(
        rpId: String,
        rpName: String,
        timeout: Int64 = OZConstants.webAuthnTimeoutMs
    ) throws -> AppleWebAuthnProvider
}
```

The bundled `WebAuthnProvider` implementation built on `ASAuthorizationPlatformPublicKeyCredentialProvider`. Available on iOS 16+ and macOS 13+.

`rpId` must match an `Associated Domains` entitlement entry (`webcredentials:<rpId>`) in the host application and the relying-party domain must serve a matching `.well-known/apple-app-site-association` document. See `webauthn-ios.md` / `webauthn-macos.md` for the host-side setup steps.

`presentationContextProvider` must be set before any `register` / `authenticate` call on macOS — without it the system fails the request with `ASAuthorizationError` code 1004. On iOS the system handles presentation automatically and the property may remain `nil`.

The provider enforces `userVerificationPreference = .required` on assertion so the on-chain WebAuthn verifier accepts the signature (the verifier contract checks the UV bit and rejects assertions with `UV=false`).

`init` and `create(...)` perform identical validation: both throw `ConfigurationException.InvalidConfig` for blank `rpId`/`rpName` or non-positive `timeout`.

### SmartAccountUtils

```swift
public enum SmartAccountUtils {
    public static func normalizeSignature(_ derSignature: Data) throws -> Data
    public static func extractPublicKeyFromRegistration(
        publicKey: Data? = nil,
        authenticatorData: Data? = nil,
        attestationObject: Data? = nil
    ) throws -> Data
    public static func getContractSalt(credentialId: Data) -> Data
    public static func deriveContractAddress(
        credentialId: Data,
        deployerPublicKey: String,
        networkPassphrase: String
    ) throws -> String
}
```

Cryptographic helpers shared by the kit and available for advanced integrations:

- `normalizeSignature(_:)` — converts a DER-encoded ECDSA signature to the compact 64-byte form with low-S normalization required by the on-chain verifier.
- `extractPublicKeyFromRegistration(publicKey:authenticatorData:attestationObject:)` — extracts the canonical uncompressed 65-byte secp256r1 public key from a WebAuthn registration response. Tries the supplied `publicKey` (SPKI), then `authenticatorData` (CBOR-encoded attested credential data), then `attestationObject` (full CBOR attestation).
- `getContractSalt(credentialId:)` — returns the SHA-256 of the credential identifier, matching the salt the smart-account deployment uses.
- `deriveContractAddress(credentialId:deployerPublicKey:networkPassphrase:)` — derives the deterministic smart-account contract address from the credential id, the deployer's `G…` account, and the network passphrase. Used by the wallet-creation flow to compute the contract address without an RPC round trip.

---

## Storage Adapter

### StorageAdapter (protocol)

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

Required behavior: thread-safe; `update` throws `CredentialException.NotFound` when the credential does not exist; `getSession()` must return `nil` (and best-effort delete) for expired sessions.

### InMemoryStorageAdapter

```swift
public final actor InMemoryStorageAdapter: StorageAdapter {
    public init()
}
```

Non-persistent in-memory adapter used as the default when no storage is supplied via `OZSmartAccountConfig`. The header docstring explicitly warns that this adapter is not persistent and not secure; suitable for tests and ephemeral demos only.

### KeychainStorageAdapter

```swift
@available(iOS 13.0, macOS 10.15, *)
public final actor KeychainStorageAdapter: StorageAdapter {
    public static let defaultServiceName: String = "com.soneso.stellar.smartaccount"

    public init(
        serviceName: String = KeychainStorageAdapter.defaultServiceName,
        shim: SecItemShim = RealSecItemShim()
    )
}
```

Apple Keychain Services adapter with `kSecAttrAccessibleAfterFirstUnlock`. Pass a custom `serviceName` to scope storage to a specific application or feature. The optional `shim` parameter is a test seam over the C `SecItem*` functions; production code accepts the default `RealSecItemShim()`.

The header docstring notes that iOS Simulator and unsigned macOS test binaries need a `keychain-access-groups` entitlement to access Keychain at all. Stored credentials contain only public-key material and metadata, so the adapter does not apply biometric `SecAccessControl` flags — there is no secret to protect at the storage layer.

### UserDefaultsStorageAdapter

```swift
public final actor UserDefaultsStorageAdapter: StorageAdapter {
    public static let defaultSuiteName: String = "com.soneso.stellar.smartaccount"

    public init(
        suiteName: String = UserDefaultsStorageAdapter.defaultSuiteName
    ) throws
}
```

Scoped `UserDefaults` adapter. Throws if the supplied suite name cannot be resolved to a `UserDefaults` instance. The header docstring notes that `UserDefaults` writes plaintext property-list values to the app container and is therefore not encrypted at rest; apps storing sensitive data should prefer the Keychain adapter.

### SecItemShim

```swift
public protocol SecItemShim: Sendable
public struct RealSecItemShim: SecItemShim
```

Public test-seam protocol over the C `SecItem*` functions. Production code uses `RealSecItemShim`, which forwards directly to the system functions. Custom conformances exist for unit tests that exercise the Keychain adapter without touching the real Keychain.

### ExternalWalletAdapter (protocol)

```swift
public protocol ExternalWalletAdapter: AnyObject, Sendable {
    func connect() async throws -> ConnectedWallet?
    func disconnect() async throws
    func disconnectByAddress(address: String) async throws
    func signAuthEntry(
        preimageXdr: String,
        options: SignAuthEntryOptions?
    ) async throws -> SignAuthEntryResult
    func getConnectedWallets() -> [ConnectedWallet]
    func canSignFor(address: String) -> Bool
    func getWalletForAddress(address: String) -> ConnectedWallet?
    func reconnect(walletId: String) async throws -> ConnectedWallet?
}
```

Default protocol extension provides no-op implementations for `disconnectByAddress(address:)`, `getWalletForAddress(address:)`, and `reconnect(walletId:)`.

The `signAuthEntry(preimageXdr:options:)` contract: the adapter receives the base64-encoded `HashIDPreimage` XDR, must base64-decode it, compute its SHA-256, sign with Ed25519, and return a `SignAuthEntryResult` carrying the base64-encoded 64-byte signature.

---

## Indexer and Relayer Clients

### OZIndexerClient

```swift
public class OZIndexerClient: @unchecked Sendable {
    public static let defaultIndexerUrls: [String: String]

    public init(
        indexerUrl: String,
        timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
        urlSession: URLSession? = nil
    ) throws

    public static func getDefaultUrl(networkPassphrase: String) -> String?
    public static func forNetwork(
        networkPassphrase: String,
        timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
        urlSession: URLSession? = nil
    ) -> OZIndexerClient?
}
```

HTTP client for the smart-account indexer service. `open`-able for test doubles. Subclasses overriding `close()` must call `super.close()` (or invoke `performCloseInternal()` directly) so the owned `URLSession` is invalidated; otherwise the underlying transport leaks. Consumer code typically injects a custom `urlSession` rather than subclassing.

**URL validation**: `indexerUrl` must start with `https://` or `http://localhost` (with optional port and path). Throws `ConfigurationException.InvalidConfig` for malformed URLs.

**Built-in defaults** (`defaultIndexerUrls`):
- Testnet — `https://smart-account-indexer.sdf-ecosystem.workers.dev`
- Mainnet — `https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev`

`getDefaultUrl(networkPassphrase:)` returns the default URL for the supplied network passphrase, or `nil` for unknown networks. `forNetwork(networkPassphrase:timeoutMs:urlSession:)` is a convenience factory that resolves the URL and constructs the client; returns `nil` when no default is configured.

When the client owns the `URLSession`, it builds an ephemeral session whose redirect handler denies all 3xx redirects to protect signed payloads and pinned identification headers (`X-Client-Name`, `X-Client-Version`).

#### Public methods

```swift
public func lookupByCredentialId(credentialId: String) async throws -> OZCredentialLookupResponse
public func lookupByAddress(address: String) async throws -> OZAddressLookupResponse
public func getContract(contractId: String) async throws -> OZContractDetailsResponse
public func getStats() async throws -> OZIndexerStatsResponse
public func isHealthy() async -> Bool
public func close()
public final func performCloseInternal()
```

- `lookupByCredentialId(credentialId:)` — looks up smart-account contracts by WebAuthn credential id (Base64URL, unpadded; converted to hex before the request). Throws `ValidationException.InvalidInput` for malformed input; `IndexerException.RequestFailed` for network or decoding errors; `IndexerException.Timeout` for per-request timeouts.
- `lookupByAddress(address:)` — looks up smart-account contracts by signer address (`G…` or `C…`).
- `getContract(contractId:)` — fetches detailed information about a smart-account contract.
- `getStats()` — fetches aggregate statistics.
- `isHealthy()` — lightweight probe. Returns `true` only when the server responds with HTTP 2xx, a `Content-Type` of `application/json`, a body within `OZConstants.maxIndexerResponseBytes`, and a decoded `OZIndexerHealthCheckResponse` whose `status` is `"ok"`. Never throws.
- `close()` — invalidates the owned `URLSession` (when not injected) and marks the client closed.

#### Public DTOs

```swift
public struct OZCredentialLookupResponse
public struct OZAddressLookupResponse
public struct OZContractDetailsResponse
public struct OZIndexedContractSummary
public struct OZIndexedContextRule
public struct OZIndexedSigner
public struct OZIndexedPolicy
public struct OZIndexerStatsResponse
public struct OZIndexerStats
public struct OZEventTypeCount
public struct OZIndexerHealthCheckResponse
public enum OZJSONValue
```

Decoded JSON shapes consumed and returned by the indexer methods above. All types are `Codable` and `Sendable`.

### OZRelayerClient

```swift
public class OZRelayerClient: @unchecked Sendable {
    public init(
        relayerUrl: String,
        timeoutMs: Int64 = OZConstants.defaultRelayerTimeoutMs,
        urlSession: URLSession? = nil
    ) throws
}
```

HTTP client for the smart-account relayer service used for fee-sponsored transaction submission. `open`-able for test doubles with the same subclass contract as `OZIndexerClient`.

**URL validation**: `relayerUrl` must start with `https://` or `http://localhost`. Throws `ConfigurationException.InvalidConfig` otherwise.

The relayer client never throws on submission. All failure modes — network errors, timeouts, XDR encoding failures, non-2xx responses — are captured in the returned `OZRelayerResponse`. Callers must always inspect `response.success` rather than relying on `try`. This is unusual relative to most async-throws APIs in the SDK and is documented on every submission method.

#### Public methods

```swift
public func send(
    hostFunction: HostFunctionXDR,
    authEntries: [SorobanAuthorizationEntryXDR],
    perRequestTimeoutMs: Int64? = nil
) async -> OZRelayerResponse

public func sendXdr(
    transactionEnvelope: TransactionEnvelopeXDR,
    perRequestTimeoutMs: Int64? = nil
) async -> OZRelayerResponse

public func close()
public final func performCloseInternal()
```

- `send(hostFunction:authEntries:perRequestTimeoutMs:)` — submits a transaction by sending the host function and authorization entries; the relayer constructs the transaction and fee-bumps it. Used when every signed auth entry uses `Address` credentials.
- `sendXdr(transactionEnvelope:perRequestTimeoutMs:)` — submits a pre-signed transaction envelope. Used when source-account authentication is required (for example smart-account contract deployments). The relayer fee-bumps the signed envelope, preserving the inner signatures.
- `perRequestTimeoutMs` — overrides the constructor timeout for a single request.

#### Public DTOs

```swift
public enum OZRelayerErrorCodes {
    public static let INVALID_PARAMS: String = "INVALID_PARAMS"
    public static let INVALID_XDR: String = "INVALID_XDR"
    public static let POOL_CAPACITY: String = "POOL_CAPACITY"
    public static let SIMULATION_FAILED: String = "SIMULATION_FAILED"
    public static let ONCHAIN_FAILED: String = "ONCHAIN_FAILED"
    public static let INVALID_TIME_BOUNDS: String = "INVALID_TIME_BOUNDS"
    public static let FEE_LIMIT_EXCEEDED: String = "FEE_LIMIT_EXCEEDED"
    public static let UNAUTHORIZED: String = "UNAUTHORIZED"
    public static let TIMEOUT: String = "TIMEOUT"
}

public struct OZRelayerResponse
```

`OZRelayerErrorCodes` is a namespace exposing the relayer service's error-code identifiers. The string value of each constant equals the constant name so it can be compared directly against the `errorCode` field of an `OZRelayerResponse`. `OZRelayerResponse` carries `success`, optional transaction `hash`, optional `error` description, and optional `errorCode` mapped from the relayer's response payload.

---

## Auth Helpers

These helpers are the lower-level building blocks the kit uses internally to construct OpenZeppelin authorization payloads. They are exposed publicly as escape hatches for callers that need to build, sign, or attach authorization entries by hand.

### OZSmartAccountAuth

```swift
public enum OZSmartAccountAuth {
    public static func buildAuthDigest(
        signaturePayload: Data,
        contextRuleIds: [UInt32]
    ) async throws -> Data

    public static func buildAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) async throws -> Data

    public static func buildSourceAccountAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        nonce: Int64,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) async throws -> Data

    public static func signAuthEntry(
        entry: SorobanAuthorizationEntryXDR,
        signer: any OZSmartAccountSigner,
        signature: any OZSmartAccountSignature,
        expirationLedger: UInt32,
        contextRuleIds: [UInt32] = []
    ) async throws -> SorobanAuthorizationEntryXDR

    public static func addRawSignatureMapEntry(
        entry: SorobanAuthorizationEntryXDR,
        signerKey: SCValXDR,
        signatureValue: SCValXDR,
        contextRuleIds: [UInt32] = []
    ) throws -> SorobanAuthorizationEntryXDR
}
```

- `buildAuthDigest(signaturePayload:contextRuleIds:)` — computes `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
- `buildAuthPayloadHash(entry:expirationLedger:networkPassphrase:)` — computes the `HashIDPreimage::SorobanAuthorization` hash that must be signed to authorize an entry with address credentials.
- `buildSourceAccountAuthPayloadHash(entry:nonce:expirationLedger:networkPassphrase:)` — variant for source-account credentials, typically used when converting them to address credentials for relayer fee sponsoring.
- `signAuthEntry(entry:signer:signature:expirationLedger:contextRuleIds:)` — attaches a pre-computed signature to an authorization entry. Does NOT perform cryptographic signing. Returns a fresh entry; when `contextRuleIds` is non-empty it overrides any existing identifiers in the payload.
- `addRawSignatureMapEntry(entry:signerKey:signatureValue:contextRuleIds:)` — adds a raw key/value entry to the auth entry's signature map. Used for delegated-signer placeholders where the value is `Bytes` rather than a signature.

### OZSmartAccountAuthPayload

```swift
public final class OZSmartAccountAuthPayload {
    public var signers: [SignerEntry]
    public let contextRuleIds: [UInt32]

    public init(signers: [SignerEntry], contextRuleIds: [UInt32])

    public struct SignerEntry: Sendable {
        public let signer: any OZSmartAccountSigner
        public let signatureBytes: Data

        public init(signer: any OZSmartAccountSigner, signatureBytes: Data)
    }
}
```

In-memory representation of the AuthPayload accepted by the OpenZeppelin smart-account contract: a `Map` with two fields, `context_rule_ids` and `signers`. The `signers` list is mutable so callers and codecs can add or replace entries in place before encoding back to an `SCValXDR`.

### OZSmartAccountAuthPayloadCodec

```swift
public enum OZSmartAccountAuthPayloadCodec {
    public static func read(_ signatureScVal: SCValXDR) throws -> OZSmartAccountAuthPayload
    public static func write(_ payload: OZSmartAccountAuthPayload) throws -> SCValXDR
    public static func upsertSigner(
        payload: OZSmartAccountAuthPayload,
        signer: any OZSmartAccountSigner,
        signatureBytes: Data
    )
    public static func signerFromScVal(_ scVal: SCValXDR) throws -> any OZSmartAccountSigner
}
```

Codec for reading and writing `OZSmartAccountAuthPayload` to and from `SCValXDR`. Inner signer entries are sorted by lowercase-hex of their XDR-encoded keys for deterministic encoding. Signature bytes are verifier-dependent: WebAuthn and Policy entries are XDR-encoded `SCValXDR`; Ed25519 entries carry the raw 64-byte signature (no XDR wrapper).

- `read(_:)` — accepts `SCValXDR.void` (returns an empty payload) or `SCValXDR.map` (the full payload).
- `write(_:)` — builds the outer map with alphabetically ordered keys and sorts the inner signer entries.
- `upsertSigner(payload:signer:signatureBytes:)` — inserts or replaces a signer's entry, preserving insertion order for new entries.
- `signerFromScVal(_:)` — decodes a signer-key ScVal back into the matching `OZSmartAccountSigner` value.

---

## Builder Helpers

### OZBuilders

```swift
public enum OZBuilders {
    public static func createDefaultContext() -> ContextRuleType
    public static func createCallContractContext(contractAddress: String) throws -> ContextRuleType
    public static func createCreateContractContext(wasmHashHex: String) throws -> ContextRuleType
    public static func createCreateContractContext(wasmHash: Data) throws -> ContextRuleType

    public static func collectUniqueSignersFromRules(
        rules: [ParsedContextRule]
    ) -> [any OZSmartAccountSigner]
}
```

Type-safe constructors for `ContextRuleType` plus a deduplication helper across parsed context rules.

- `createDefaultContext()` — returns `ContextRuleType.defaultRule`.
- `createCallContractContext(contractAddress:)` — validates the supplied contract address (throws `ValidationException.InvalidAddress` for malformed values) and returns `ContextRuleType.callContract(contractAddress:)`.
- `createCreateContractContext(wasmHashHex:)` — validates a 64-character hex WASM hash (an optional `0x` prefix is accepted and stripped) and returns `ContextRuleType.createContract(wasmHash:)`. Throws `ValidationException.InvalidInput` for malformed input.
- `createCreateContractContext(wasmHash:)` — validates a 32-byte WASM hash and returns the matching enum case.
- `collectUniqueSignersFromRules(rules:)` — flattens the supplied rules' signers and returns a deduplicated list preserving the first occurrence of each signer (via `OZSmartAccountSigner.uniqueKey`).

### OZSmartAccountBuilders

```swift
public enum OZSmartAccountBuilders {
    // Signer builders
    public static func createDelegatedSigner(publicKey: String) throws -> OZDelegatedSigner
    public static func createExternalSigner(verifierAddress: String, keyData: Data) throws -> OZExternalSigner
    public static func createWebAuthnSigner(
        webauthnVerifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) throws -> OZExternalSigner
    public static func createEd25519Signer(
        ed25519VerifierAddress: String,
        publicKey: Data
    ) throws -> OZExternalSigner

    // Signer inspection
    public static func getCredentialIdFromSigner(signer: any OZSmartAccountSigner) -> Data?
    public static func getCredentialIdStringFromSigner(signer: any OZSmartAccountSigner) -> String?
    public static func isDelegatedSigner(signer: any OZSmartAccountSigner) -> Bool
    public static func isExternalSigner(signer: any OZSmartAccountSigner) -> Bool
    public static func describeSignerType(signer: any OZSmartAccountSigner) -> String

    // Signer matching
    public static func signerMatchesCredential(
        signer: any OZSmartAccountSigner,
        credentialId: Data
    ) -> Bool
    public static func signerMatchesCredentialId(
        signer: any OZSmartAccountSigner,
        credentialId: String
    ) -> Bool
    public static func signerMatchesAddress(
        signer: any OZSmartAccountSigner,
        address: String
    ) -> Bool

    // Comparison and deduplication
    public static func signersEqual(
        _ a: any OZSmartAccountSigner,
        _ b: any OZSmartAccountSigner
    ) -> Bool
    public static func getSignerKey(signer: any OZSmartAccountSigner) -> String
    public static func collectUniqueSigners(
        signers: [any OZSmartAccountSigner]
    ) -> [any OZSmartAccountSigner]

    // Policy parameter builders
    public static func createThresholdParams(threshold: Int) throws -> OZSimpleThresholdParams
    public static func createWeightedThresholdParams(
        threshold: Int,
        signerWeights: [OZSignerWeight]
    ) throws -> OZWeightedThresholdParams
    public static func createSpendingLimitParams(
        spendingLimit: String,
        periodLedgers: Int
    ) throws -> OZSpendingLimitParams
}
```

A `public enum` namespace of type-safe constructors and helpers for signers, signer inspection, and policy parameter structs. Signer builders forward to the corresponding `OZDelegatedSigner` / `OZExternalSigner` initializers and factories. The inspection helpers detect WebAuthn signers by their `keyData` shape (greater than 65 bytes — a 65-byte uncompressed public key followed by the credential id).

#### Typed policy parameter structs

```swift
public struct OZSimpleThresholdParams: Sendable, Hashable {
    public let threshold: Int
    public init(threshold: Int)
}

public struct OZSignerWeight: Sendable {
    public let signer: any OZSmartAccountSigner
    public let weight: Int
    public init(signer: any OZSmartAccountSigner, weight: Int)
}

public struct OZWeightedThresholdParams: Sendable {
    public let threshold: Int
    public let signerWeights: [OZSignerWeight]
    public init(threshold: Int, signerWeights: [OZSignerWeight])
}

public struct OZSpendingLimitParams: Sendable, Hashable {
    public let spendingLimit: Int64
    public let periodLedgers: Int
    // initializer is internal — construct through OZSmartAccountBuilders.createSpendingLimitParams
}
```

These are the typed parameter structs returned by the corresponding `OZSmartAccountBuilders.create*Params(...)` methods. Use `OZSignerWeight` only via `OZSmartAccountBuilders.createWeightedThresholdParams(...)`; pass `SignerWeightEntry` to `addWeightedThreshold(...)` directly. `OZSpendingLimitParams`'s initializer is intentionally internal so callers always go through the builder for input validation and unit conversion (decimal XLM string → stroops via `Int64`).

For amounts whose stroops value exceeds the `Int64` ceiling, encode the spending limit directly as `SCValXDR.i128(stringValue:)` and pass it through `OZPolicyManager.addPolicy(...)`.

---

## Signer Types

### OZSmartAccountSigner (protocol)

```swift
public protocol OZSmartAccountSigner: Sendable {
    func toScVal() throws -> SCValXDR
    var uniqueKey: String { get }
}
```

The protocol every smart-account signer adopts. `toScVal()` returns the on-chain `SCValXDR` representation expected by the smart-account contract. `uniqueKey` is the stable string used for deduplication and lookup; the format varies by concrete signer type:
- `OZDelegatedSigner` → `"delegated:<address>"`.
- `OZExternalSigner` → `"external:<verifierAddress>:<keyDataHex>"`.

### OZDelegatedSigner

```swift
public struct OZDelegatedSigner: OZSmartAccountSigner, Equatable, Hashable {
    public let address: String

    public init(address: String) throws
}
```

A signer authorized through a Soroban address using the host's `require_auth` mechanism. `address` may be a `G…` Stellar account or a `C…` contract strkey. The initializer throws `ValidationException.InvalidAddress` for any other shape.

`toScVal()` returns `SCValXDR.vec([Symbol("Delegated"), Address(address)])`.

### OZExternalSigner

```swift
public struct OZExternalSigner: OZSmartAccountSigner, Equatable, Hashable {
    public let verifierAddress: String
    public let keyData: Data

    public init(verifierAddress: String, keyData: Data) throws

    public static func webAuthn(
        verifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) throws -> OZExternalSigner

    public static func ed25519(
        verifierAddress: String,
        publicKey: Data
    ) throws -> OZExternalSigner
}
```

A signer that delegates signature verification to a custom verifier contract. `verifierAddress` must be a valid `C…` strkey; `keyData` carries the public-key bytes plus any auxiliary authentication data and must not be empty.

`webAuthn(verifierAddress:publicKey:credentialId:)` validates the 65-byte uncompressed secp256r1 public key (starting with `0x04`), validates the credential id is non-empty, and constructs `keyData = publicKey || credentialId` matching the layout expected by WebAuthn verifier contracts.

`ed25519(verifierAddress:publicKey:)` validates the 32-byte Ed25519 public key and stores it as `keyData`.

`toScVal()` returns `SCValXDR.vec([Symbol("External"), Address(verifierAddress), Bytes(keyData)])`.

Equality and hashing use constant-time comparison on `keyData` to avoid leaking information about the byte content through timing side channels.

### SubmissionMethod

```swift
public enum SubmissionMethod: Sendable {
    case relayer
    case rpc
}
```

Overrides the default automatic submission-method selection for a single call. `relayer` fails if no relayer is configured on the kit; `rpc` is always available.

---

## Signature Types

### OZSmartAccountSignature (protocol)

```swift
public protocol OZSmartAccountSignature: Sendable {
    func toScVal() -> SCValXDR
    func toAuthPayloadBytes() throws -> Data
}
```

Two methods form the public contract:

- `toScVal()` — returns the `SCValXDR` representation of the signature. Useful for tests and direct ScVal manipulation. Non-throwing.
- `toAuthPayloadBytes()` — returns the exact bytes stored in `AuthPayload.signers: Map<Signer, Bytes>` for this signature. The content is verifier-dependent (see below) and is what the smart account contract passes to the verifier as `sig_data`.

Construction-time validation may throw `ValidationException.InvalidInput`. `toScVal()` is non-throwing for all three variants. `toAuthPayloadBytes()` is non-throwing for Ed25519 (returns the raw 64-byte signature); WebAuthn and Policy XDR-encode the `toScVal()` result and throw `TransactionException.SigningFailed` on encoding failure.

**Per-variant on-wire content:**

| Variant | `toScVal()` | `toAuthPayloadBytes()` |
|---|---|---|
| `OZWebAuthnSignature` | `SCValXDR.map` (3 alphabetical keys) | XDR-encoded map (~150+ bytes) |
| `OZEd25519Signature` | `SCValXDR.bytes(64 bytes)` | raw 64 bytes (no XDR envelope) |
| `OZPolicySignature` | `SCValXDR.map([])` | XDR-encoded empty map (12 bytes) |

The Ed25519 verifier contract receives `sig_data: BytesN<64>`. The host coerces `Bytes(64)` to `BytesN<64>` directly. XDR-encoding the ScVal first inflates it to ~70 bytes; the coercion rejects it with `Error(Auth, InvalidAction)`.

### OZWebAuthnSignature

```swift
public struct OZWebAuthnSignature: OZSmartAccountSignature, Hashable {
    public let authenticatorData: Data
    public let clientData: Data
    public let signature: Data

    public init(authenticatorData: Data, clientData: Data, signature: Data) throws
}
```

WebAuthn signature produced by a passkey authentication ceremony. `signature` must be exactly 64 bytes (compact ECDSA `r || s` form with low-S normalization). The encoded map uses keys `authenticator_data`, `client_data`, `signature` in alphabetical order; the map key is `client_data`, not `client_data_json`.

`toAuthPayloadBytes()` returns the XDR-encoded map so the WebAuthn verifier can deserialize it as `WebAuthnSigData`.

Equality uses constant-time comparison on each byte field.

### OZEd25519Signature

```swift
public struct OZEd25519Signature: OZSmartAccountSignature, Hashable {
    public let publicKey: Data   // local verification only; NOT transmitted
    public let signature: Data

    public init(publicKey: Data, signature: Data) throws
}
```

Ed25519 signature produced by a traditional Ed25519 keypair. `publicKey` must be `SmartAccountConstants.ed25519PublicKeySize` (32) bytes; `signature` must be exactly 64 bytes.

`toScVal()` returns `SCValXDR.bytes(signature)`.

`toAuthPayloadBytes()` returns the raw 64-byte `signature` with no XDR wrapping. The Ed25519 verifier contract expects `sig_data: BytesN<64>`; transmitting an XDR-encoded ScVal inflates the content to ~70 bytes and the host coercion traps with `Error(Auth, InvalidAction)`.

The `publicKey` field is used for local pre-submission verification in the multi-signer pipeline. It is not transmitted in the auth payload; the verifier reads the public key from the on-chain `External(verifier, key_data)` signer storage.

### OZPolicySignature

```swift
public struct OZPolicySignature: OZSmartAccountSignature, Hashable {
    public static let instance: OZPolicySignature
}
```

Marker signature representing policy-based authorization. Encoded as an empty map. Use `OZPolicySignature.instance` — the initializer is private to keep the type a singleton.

---

## Quirks

Cross-cutting behavioral notes that affect multiple classes or are easy to miss.

- **Post-`close()` trap**: accessing any manager or operations property after `kit.close()` has returned traps with an implicitly-unwrapped-optional nil. Call `close()` last, and never retain manager references across the kit's lifetime.
- **`connectWallet` tri-state return**: `connectWallet(options:)` returns `nil` (no session, `prompt` was `false`), `.connected` (single contract resolved), or `.ambiguous` (indexer reported multiple contracts for the credential — kit state is NOT set; the caller must prompt the user to pick and then re-call with `options.contractId`).
- **`OZRelayerClient` does not throw**: network and HTTP errors are captured in the returned `OZRelayerResponse`; only XDR encoding failures (pre-request) surface as `OZRelayerResponse(success: false, ...)` with no `errorCode`. Always check `response.success`.
- **Default deployer seed**: when `deployerKeypair` is `nil`, the kit derives a deterministic deployer from `SHA-256("openzeppelin-smart-account-kit")`. The literal string is a fixed protocol constant; changing it would produce a different deployer address and orphan every wallet deployed via the default.
- **`OZConstants` does not bundle testnet values**: `accountWasmHash` and `webauthnVerifierAddress` are never bundled in `OZConstants`; consumers must supply them from their deployment configuration.
- **`SelectedSigner.passkey(...)` `keyData` requirement**: in multi-signer ceremonies every passkey `SelectedSigner` entry must supply `keyData` non-nil. The auth pipeline validates this upfront in `validateSignerSet` and throws `ValidationException.InvalidInput` (field `"selectedSigners"`) when `keyData` is absent.
- **`autoFund: true` is testnet-only**: `fundWallet` calls the hardcoded Friendbot URL at `https://friendbot.stellar.org`. On mainnet, fund the deployer externally and omit `autoFund`.
- **`webauthnProvider` requirement scope**: a `webauthnProvider` is required for `createWallet`, `connectWallet` with `prompt: true`, `authenticatePasskey`, and any passkey-signing flow. A `connectWallet()` call that finds a live unexpired session does NOT need `webauthnProvider`.
- **C-address base32 alphabet**: C-strkeys use the RFC 4648 base32 alphabet (`A-Z` + `2-7`). The digits `0`, `1`, `8`, and `9` are not legal. Hand-constructed or modified C-address strings that include those digits are silently rejected by `isValidContractId()` and by `OZSmartAccountConfig.init`, surfacing as `ConfigurationException.InvalidConfig`.
