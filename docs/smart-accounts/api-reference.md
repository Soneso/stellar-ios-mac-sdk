# Smart Accounts API Reference

OpenZeppelin Smart Account Kit for Stellar/Soroban. This reference documents all public APIs for creating, managing, and operating smart accounts with WebAuthn/passkey authentication.

**Location**: `stellarsdk` module (`smartaccount/` namespace)

**Platform Support**: iOS, macOS

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
- [Indexer Client](#indexer-client)
- [Relayer Client](#relayer-client)
- [Auth Helpers](#auth-helpers)
- [Builder Helpers](#builder-helpers)
- [Utilities](#utilities)
- [Signer Types](#signer-types)
- [Signature Types](#signature-types)
- [Quirks](#quirks)
- [Error Handling Example](#error-handling-example)

---

## Quick Start

See the [Quick Start in the README](README.md#quick-start) for an end-to-end example covering kit configuration, wallet creation, token transfer, and the reconnection patterns. The sections below document each public symbol in detail.

---

## OZSmartAccountKit (Main Entry Point)

```swift
public final class OZSmartAccountKit: @unchecked Sendable { ... }
```

Composition root that owns every operations module, every manager, the shared `SorobanServer`, and the optional indexer and relayer HTTP clients. Connected-state accessors (`isConnected`, `isHeadless`, `credentialId`, `contractId`) are thread-safe (protected by an internal `NSLock`); the configuration and resolved transports are immutable for the kit's lifetime.

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

#### events

```swift
public let events: OZSmartAccountEventEmitter
```

The event emitter shared by every manager bound to this kit. See the [Events](#events) section for the listener API.

#### isConnected

```swift
public var isConnected: Bool { get }
```

`true` when a contract address is set; the credential is optional and is absent for a headless connection. Reflects in-memory state only; after an app restart, call `walletOperations.connectWallet(_:)` to restore a saved session.

#### isHeadless

```swift
public var isHeadless: Bool { get }
```

`true` when the kit is connected to a contract with no passkey credential (contract address set, `credentialId == nil`) — the state established by `walletOperations.connectToContract(contractId:)`.

#### credentialId

```swift
public var credentialId: String? { get }
```

The Base64URL-encoded (unpadded) WebAuthn credential identifier of the currently connected wallet, or `nil` when no wallet is connected and for a headless connection.

#### contractId

```swift
public var contractId: String? { get }
```

The smart-account contract address (`C…` strkey, 56 characters) of the currently connected wallet, or `nil` when no wallet is connected.

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

#### contextRuleManager

```swift
public var contextRuleManager: OZContextRuleManager { get }
```

The [Context Rule Management](#context-rule-management) manager.

#### policyManager

```swift
public var policyManager: OZPolicyManager { get }
```

The [Policy Management](#policy-management) manager. Installs and removes the built-in policy types (Simple Threshold, Weighted Threshold, Spending Limit) and exposes a generic entry point for custom policy contracts.

#### credentialManager

```swift
public var credentialManager: OZCredentialManager { get }
```

The [Credential Management](#credential-management) manager.

#### multiSignerManager

```swift
public var multiSignerManager: OZMultiSignerManager { get }
```

The [Multi-Signer Operations](#multi-signer-operations) manager. Coordinates ceremonies that combine multiple passkeys, Ed25519 external signers, and external-wallet signers.

#### externalSigners

```swift
public var externalSigners: OZExternalSignerManager { get }
```

The kit-owned `OZExternalSignerManager`. Always non-`nil`; constructed at kit initialization from `config.externalWallet` and `config.externalEd25519Adapter`. Use this property to register in-memory keypairs at runtime (`addFromSecret(secretKey:)`, `addEd25519FromRawKey(secretKeyBytes:verifierAddress:)`) and to check signer availability (`hasWalletAdapter`, `canSignFor(address:)`, `canSignEd25519For(verifierAddress:publicKey:)`). The multi-signer pipeline resolves all external-signer calls through this property. See [External Signer Management](#external-signer-management) for the full manager API.

### Client Properties

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

### Lifecycle Methods

#### disconnect()

```swift
public func disconnect() async throws
```

Ends the active session. Clears the in-memory connection state under the kit's internal lock, releases the lock, calls `storage.clearSession()`, and emits `OZSmartAccountEvent.walletDisconnected(contractId:)`. Stored credentials are NOT deleted — they remain in storage and can be reconnected with `walletOperations.connectWallet(_:)`. Safe to call when no wallet is connected.

**Throws**: `SmartAccountStorageException` when the storage adapter fails to clear the session.

#### close()

```swift
public func close() async
```

Releases the kit's HTTP-client, event-emitter, and manager resources, and clears any in-memory external signers (registered keypairs and Ed25519 keys). The kit must not be used after `close()`; the manager and operations accessors trap once released.

#### getDeployer()

```swift
public func getDeployer() async throws -> KeyPair
```

Returns the deployer keypair. When the configuration supplies an explicit `deployerKeypair`, it is returned; otherwise the deterministic default deployer is derived from `SHA-256("openzeppelin-smart-account-kit")` and cached on first use. The cache is unsynchronized — concurrent first callers may compute the deterministic deployer more than once, but the result is idempotent.

**Throws**: `SmartAccountConfigurationException.InvalidConfig` when default-deployer derivation fails.

---

## OZSmartAccountConfig

```swift
public struct OZSmartAccountConfig: @unchecked Sendable, Equatable, Hashable { ... }
```

Immutable configuration value type passed to `OZSmartAccountKit.create(config:)`. Construct directly through the throwing initializer below or through `OZSmartAccountConfig.builder(...)` for a fluent API. Both entry points perform identical validation and produce identical instances.

**Required Fields**:

- `rpcUrl`: Soroban RPC endpoint URL. Must not be blank.
- `networkPassphrase`: Stellar network passphrase. Must not be blank.
- `accountWasmHash`: 64-character hex SHA-256 of the smart-account contract WASM. Must match `[0-9a-fA-F]{64}`.
- `webauthnVerifierAddress`: Contract address (`C…` strkey) of the WebAuthn verifier contract. Must be a valid `C…` strkey.

**Optional Fields**:

- `deployerKeypair`: Optional deployer keypair. When `nil`, the deterministic default deployer (derived from `SHA-256("openzeppelin-smart-account-kit")`) is used.
- `sessionExpiryMs`: Session expiry in milliseconds. Defaults to `OZConstants.defaultSessionExpiryMs` (604 800 000 — seven days).
- `signatureExpirationLedgers`: Signature expiration in ledgers. Defaults to `StellarProtocolConstants.ledgersPerHour` (720). Must be `>= 1`. No client-side upper bound — the network's `maxEntryTTL` (CAP-0046-11) governs the maximum and is enforced by the host at submission.
- `timeoutInSeconds`: Transaction validity window in seconds. Sets each transaction's TimeBounds `max_time = now + timeoutInSeconds`; `0` means no expiry (infinite). Defaults to `OZConstants.defaultTimeoutSeconds` (30). Must be `>= 0`.
- `relayerUrl`: Optional relayer endpoint URL for fee-sponsored submission. Not validated at construction.
- `indexerUrl`: Optional indexer endpoint URL. When `nil`, `effectiveIndexerUrl()` falls back to the built-in default for the configured network.
- `webauthnProvider`: WebAuthn provider used by `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, `addNewPasskeySigner`, and the per-entry signing pass. Required for every flow that prompts for biometric authentication.
- `storage`: Adapter for persisting credentials and sessions. Defaults to `OZInMemoryStorageAdapter()`. Production apps pass `OZKeychainStorageAdapter()` or `OZUserDefaultsStorageAdapter()`.
- `externalWallet`: Optional external-wallet adapter injected into `kit.externalSigners` at construction. Required when `OZSelectedSigner.wallet(accountId:)` participates in a multi-signer ceremony and the wallet key is managed by an external service rather than an in-memory keypair.
- `externalEd25519Adapter`: Optional Ed25519 adapter injected into `kit.externalSigners` at construction. Provides out-of-process Ed25519 signing (hardware wallets, remote signing services) as an alternative to in-memory keypairs registered via `kit.externalSigners.addEd25519FromRawKey(...)`.
- `maxContextRuleScanId`: Maximum context-rule identifier to scan during `getAllContextRules()` / `listContextRules()`. Defaults to `50`. Increase when the account has had many add / remove cycles.
- `defaultPolicies`: Policies installed on a new wallet's default context rule at deploy time, keyed by policy contract address (`C…` strkey) with the policy's install parameters as the value (see `OZPolicyInstallParams.toScVal()`). Applied through the contract constructor by `createWallet` and `deployPendingCredential`; a per-call `policies` argument overrides it. Defaults to no policies. Maximum `OZConstants.maxPolicies` (5). See the `createWallet` `policies` parameter for the built-in policies' install constraints at deploy time.

### Platform-specific provider integration

See [WebAuthn Provider](#webauthn-provider), [Storage Adapter](#storage-adapter), and [OZExternalWalletAdapter](#ozexternalwalletadapter-protocol) for the platform-specific implementations and the abstract contracts.

### Initialization

```swift
public init(
    rpcUrl: String,
    networkPassphrase: String,
    accountWasmHash: String,
    webauthnVerifierAddress: String,
    deployerKeypair: KeyPair? = nil,
    sessionExpiryMs: Int64 = OZConstants.defaultSessionExpiryMs,
    signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour,
    timeoutInSeconds: Int = OZConstants.defaultTimeoutSeconds,
    relayerUrl: String? = nil,
    indexerUrl: String? = nil,
    webauthnProvider: WebAuthnProvider? = nil,
    storage: OZStorageAdapter = OZInMemoryStorageAdapter(),
    externalWallet: OZExternalWalletAdapter? = nil,
    externalEd25519Adapter: OZExternalEd25519SignerAdapter? = nil,
    maxContextRuleScanId: UInt32 = 50,
    defaultPolicies: [String: SCValXDR] = [:]
) throws
```

Parameters match the fields documented above.

**Throws**: `SmartAccountConfigurationException.MissingConfig` (blank `rpcUrl`, `networkPassphrase`, or `accountWasmHash`); `SmartAccountConfigurationException.InvalidConfig` (invalid `accountWasmHash` format, invalid `webauthnVerifierAddress` strkey, `signatureExpirationLedgers` less than 1, `timeoutInSeconds` negative).

### Static Factories

#### createDefaultDeployer()

```swift
public static func createDefaultDeployer() async throws -> KeyPair
```

Derives the deterministic default deployer keypair from `SHA-256("openzeppelin-smart-account-kit")`. The seed string is fixed and produces the same keypair on every invocation, so the deterministic deployer address is stable and predictable. The keypair pays deployment fees only and never controls user wallets.

**Throws**: `SmartAccountConfigurationException.InvalidConfig` when seed generation fails.

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

**Throws**: `SmartAccountConfigurationException.InvalidConfig` when default-deployer derivation fails.

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

One setter per optional field, each `@discardableResult` and returning `Builder` for chaining. The label is the field name (note the lowercase `webauthn` / `externalEd25519` casing):

- `deployerKeypair(_:)` — `KeyPair?`
- `sessionExpiryMs(_:)` — `Int64`
- `signatureExpirationLedgers(_:)` — `Int`
- `timeoutInSeconds(_:)` — `Int`
- `relayerUrl(_:)` — `String?`
- `indexerUrl(_:)` — `String?`
- `webauthnProvider(_:)` — `WebAuthnProvider?`
- `storage(_:)` — `OZStorageAdapter`
- `externalWallet(_:)` — `OZExternalWalletAdapter?`
- `externalEd25519Adapter(_:)` — `OZExternalEd25519SignerAdapter?`
- `maxContextRuleScanId(_:)` — `UInt32`
- `defaultPolicies(_:)` — `[String: SCValXDR]`

#### build()

```swift
public func build() throws -> OZSmartAccountConfig
```

Constructs the configuration through the initializer; the same validation rules apply.

**Throws**: `SmartAccountConfigurationException` for any validation failure.

---

## Wallet Operations

### OZWalletOperations

```swift
public final class OZWalletOperations: @unchecked Sendable { ... }
```

Accessed via `kit.walletOperations`. Handles wallet creation (WebAuthn registration plus deterministic contract derivation plus deploy-transaction build and submission), wallet connection (session restore, storage-to-derivation-to-indexer cascade, ambiguous multi-contract handling), standalone passkey authentication, and retry of a previously incomplete or failed deployment. Every state-changing method respects task cancellation at each `await` point.

#### createWallet(...)

```swift
public func createWallet(
    userName: String = "Smart Account User",
    autoSubmit: Bool = false,
    autoFund: Bool = false,
    nativeTokenContract: String? = nil,
    forceMethod: OZSubmissionMethod? = nil,
    policies: [String: SCValXDR]? = nil
) async throws -> OZCreateWalletResult
```

Registers a fresh WebAuthn credential, derives the deterministic smart-account contract address, persists the credential as `pending` in storage, sets the kit's connected state, builds and signs the deploy transaction, and (when `autoSubmit == true`) submits it. The returned result's `signedTransactionXdr` is always populated regardless of `autoSubmit`, so an off-line submission flow can pick it up later.

When `autoFund == true`, the freshly deployed contract is funded through Friendbot after deployment confirmation; this branch requires `autoSubmit == true` and a non-`nil` `nativeTokenContract`.

**Parameters**:
- `userName`: Display name persisted with the credential.
- `autoSubmit`: Submit the deploy transaction. Defaults to `false`.
- `autoFund`: Fund the wallet via Friendbot after deployment (testnet only). Defaults to `false`.
- `nativeTokenContract`: Native token (XLM SAC) contract address used when `autoFund == true`.
- `forceMethod`: Optional submission-method override.
- `policies`: Policies to install on the new wallet's default context rule at deploy time (via the contract constructor), keyed by policy contract address (`C…` strkey) with the policy's install parameters as the value (see `OZPolicyInstallParams.toScVal()`). When `nil` (default), `OZSmartAccountConfig.defaultPolicies` is used; pass a map (including an empty one) to override that default. Validated before the passkey ceremony, so an invalid policy config fails without creating an orphaned credential. Maximum 5 policies. Note the built-in policies' own install rules apply against this default rule and its single initial signer: a spending-limit policy installs only on call-contract rules and cannot be installed here, and a threshold must not exceed the signer count. A threshold of 1 installs and keeps the rule at 1-of-N as more signers are added; beyond that, constructor policies are primarily useful for custom policies.

**Returns**: An `OZCreateWalletResult` describing the new wallet.

**Throws**: `WebAuthnException` (missing provider, ceremony failure), `SmartAccountValidationException` (input validation), `SmartAccountTransactionException` (build, sign, submit failure), `SmartAccountCredentialException`, `SmartAccountStorageException`.

#### connectWallet(...)

```swift
public func connectWallet(
    options: OZConnectWalletOptions = OZConnectWalletOptions()
) async throws -> OZConnectWalletResult?
```

Connects to an existing smart-account wallet. The tri-state return distinguishes "no session, no prompt" (`nil`) from a happy-path single-contract resolution (`.connected(...)`) and from an ambiguous multi-contract resolution (`.ambiguous(...)`). When `options.prompt == false` (default) and no valid session exists, returns `nil` so the caller can show a login UI. The kit's connected state is set on `.connected` and is NOT set on `.ambiguous` — the caller must let the user pick a candidate from `.ambiguous.candidates` and re-call with `options.contractId` set to the chosen address.

The cascade for resolving the contract address is: stored credential lookup → deterministic contract derivation from the credential id and the deployer's account id → indexer lookup. The indexer step runs only when the previous two short-circuit.

**Parameters**:
- `options`: Connect-wallet options. Defaults to a silent session-only restore.

**Returns**: An `OZConnectWalletResult` or `nil`.

**Throws**: `WebAuthnException` (prompt path), `SmartAccountWalletException` (no contract resolved), `SmartAccountValidationException` (options validation), `SmartAccountTransactionException` (RPC failure), `SmartAccountIndexerException` (indexer transport failure).

#### connectToContract(...)

```swift
public func connectToContract(contractId: String) async throws -> OZConnectToContractResult
```

Connects to an existing smart account by its contract address alone. Runs no WebAuthn ceremony, consults no credential, and persists no session (any previously saved session is cleared). Verifies the contract exists on-chain (a one-shot existence check, not a poll), then sets the connected state with `credentialId == nil` and emits `OZSmartAccountEvent.walletConnectedHeadless(contractId:)`. A headless connection holds no passkey credential, so the single-passkey operations (`submit`, `transfer`, `contractCall`, `executeAndSubmit`, signer/manager calls left at the default empty `selectedSigners`) reject it — those calls must use the multi-signer / external-signer path with an explicit non-empty `selectedSigners`. Intended for an autonomous agent or backend service that signs through the external-signer path.

**Parameters**:
- `contractId`: Smart-account contract address (`C…` strkey).

**Returns**: An `OZConnectToContractResult` carrying the verified contract address.

**Throws**: `SmartAccountValidationException.InvalidAddress` (invalid `contractId`), `SmartAccountWalletException.notFound` (no contract at the address), `SmartAccountTransactionException` (RPC existence check failure).

#### authenticatePasskey(...)

```swift
public func authenticatePasskey(
    challenge: Data? = nil,
    credentialIds: [String]? = nil
) async throws -> OZAuthenticatePasskeyResult
```

Runs a standalone WebAuthn authentication ceremony without setting the kit's connected state. Typically used to drive an indexer lookup that discovers the contracts the credential is registered on before issuing an explicit `connectWallet(...)` call. When `challenge` is `nil` a 32-byte challenge is drawn from the system CSPRNG; when `credentialIds` is `nil` the authenticator's default credential discovery is used.

**Parameters**:
- `challenge`: Optional explicit challenge bytes; defaults to a fresh 32-byte CSPRNG draw.
- `credentialIds`: Optional Base64URL-encoded credential identifiers to restrict the authenticator picker.

**Returns**: An `OZAuthenticatePasskeyResult` carrying the credential id, the normalised WebAuthn signature, and the stored public key (when locally available).

**Throws**: `WebAuthnException` (missing provider, ceremony failure), `SmartAccountValidationException`.

#### deployPendingCredential(...)

```swift
public func deployPendingCredential(
    credentialId: String,
    autoSubmit: Bool = true,
    autoFund: Bool = false,
    nativeTokenContract: String? = nil,
    forceMethod: OZSubmissionMethod? = nil,
    policies: [String: SCValXDR]? = nil
) async throws -> OZDeployPendingResult
```

Retries deployment for a credential whose previous deploy attempt was skipped or failed. The credential must already exist in storage (the method is intended for one whose `deploymentStatus` is `.pending` or `.failed`, but it does not itself reject other statuses). Behaves like `createWallet(...)` from the deploy-transaction step onward: builds and signs the deploy transaction, submits when `autoSubmit == true`, optionally funds the wallet when both `autoSubmit` and `nativeTokenContract` are supplied.

**Parameters**:
- `credentialId`: Base64URL-encoded credential identifier to retry.
- `autoSubmit`: Submit the deploy transaction. Defaults to `true`.
- `autoFund`: Fund the wallet via Friendbot after deployment. Defaults to `false`.
- `nativeTokenContract`: Native token contract address used when `autoFund == true`.
- `forceMethod`: Optional submission-method override.
- `policies`: Policies to install on the default context rule at deploy time, keyed by policy contract address (`C…` strkey). When `nil` (default), `OZSmartAccountConfig.defaultPolicies` is used; pass a map (including an empty one) to override it. Constructor args are not part of the contract-address preimage, so the derived address is unchanged. Maximum 5 policies.

**Returns**: An `OZDeployPendingResult`.

**Throws**: `SmartAccountCredentialException.NotFound`, `WebAuthnException`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `SmartAccountStorageException`.

### Result Types

#### OZCreateWalletResult

```swift
public struct OZCreateWalletResult: Sendable, Hashable {
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

#### OZConnectWalletResult

```swift
public enum OZConnectWalletResult: Sendable, Equatable, Hashable {
    case connected(credentialId: String, contractId: String, restoredFromSession: Bool)
    case ambiguous(credentialId: String, candidates: [String])

    public var credentialId: String { get }
}
```

The `connected` arm reports a successful single-contract resolution; `restoredFromSession` is `true` when the connection was restored from a stored session, `false` for fresh authentications. The `ambiguous` arm reports a multi-contract resolution from the indexer — the kit's connected state is NOT set on `.ambiguous`; the caller must let the user pick a candidate and re-call `connectWallet(options:)` with `contractId` set to the chosen value.

#### OZConnectToContractResult

```swift
public struct OZConnectToContractResult: Sendable, Equatable, Hashable {
    public let contractId: String
}
```

Outcome of a headless `connectToContract(contractId:)`. Carries the verified contract address; no credential is involved.

#### OZConnectWalletOptions

```swift
public struct OZConnectWalletOptions: Sendable, Equatable, Hashable {
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

#### OZDeployPendingResult

```swift
public struct OZDeployPendingResult: Sendable, Equatable, Hashable {
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

#### OZAuthenticatePasskeyResult

```swift
public struct OZAuthenticatePasskeyResult: Sendable, Hashable {
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

### OZTransactionOperations

```swift
public final class OZTransactionOperations: @unchecked Sendable { ... }
```

Accessed via `kit.transactionOperations`. Builds, signs, and submits transactions on behalf of the connected smart-account wallet. Drives the full simulate / sign / re-simulate / submit pipeline, including WebAuthn-based auth-entry signing, automatic relayer-versus-RPC selection, and result polling.

#### transfer(...)

```swift
public func transfer(
    tokenContract: String,
    recipient: String,
    amount: String,
    decimals: Int? = nil,
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Transfers SEP-41-compatible tokens from the connected smart account to a recipient. The decimal amount is converted to the token's base units before submission. When `decimals` is supplied it is used directly; when it is `nil` (default) the token's on-chain `decimals()` value is fetched automatically via `fetchTokenDecimals(tokenContract:)`. Supply `decimals` to avoid the extra RPC round trip when the scale is already known.

Delegates to `contractCall(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)` to drive the pipeline.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException` (invalid address, invalid amount, self-transfer), `SmartAccountTransactionException`, `WebAuthnException`.

#### fetchTokenDecimals(...)

```swift
public func fetchTokenDecimals(tokenContract: String) async throws -> Int
```

Reads the `decimals()` value from a SEP-41 token contract by simulating the call and returning the reported `u32` scale.

**Throws**: `SmartAccountValidationException` (invalid `tokenContract` address), `SmartAccountTransactionException` (simulation failure or a non-`u32` return value).

#### amountToBaseUnits(_:decimals:)

```swift
public static func amountToBaseUnits(_ amount: String, decimals: Int) throws -> String
```

Converts a positive decimal amount string to its base-units representation scaled by `decimals` decimal places. Rejects scientific notation, empty or non-numeric strings, values less than or equal to zero, and values carrying more fractional digits than `decimals` allows. Returns the base-units amount as a decimal integer string with no leading zeros.

**Parameters**: `amount` — positive decimal string (e.g. `"10"` or `"100.5"`); `decimals` — token decimal scale in `0...38`.

**Throws**: `SmartAccountValidationException.InvalidAmount` when `amount` is invalid, negative, carries excess fractional precision, or the result falls outside the `i128` representable range.

#### contractCall(...)

```swift
public func contractCall(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Calls a function on an external contract directly from the smart account. The smart account authorizes the call via Soroban's `require_auth` mechanism triggered by the target contract. Use this for any external-contract interaction (token approvals, token transfers, DeFi protocol calls) where the smart account is the authorized party.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountCredentialException`.

#### executeAndSubmit(...)

```swift
public func executeAndSubmit(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Calls `execute(target, target_fn, target_args)` on the smart-account contract itself. The contract dispatches the inner call on behalf of the smart account after evaluating its context rules and policies. Use this when the call must flow through the smart account's `execute` entry point rather than originate from the smart account directly.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountCredentialException`.

#### submit(...)

```swift
public func submit(
    hostFunction: HostFunctionXDR,
    auth: [SorobanAuthorizationEntryXDR],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Low-level escape hatch. Submits a manually constructed host function through the full simulate / sign / re-simulate / submit pipeline. `transfer`, `contractCall`, and `executeAndSubmit` all delegate here. Use it directly to submit a host function whose shape is not covered by the higher-level entry points. When `auth` is empty, simulation discovers the authorization entries; the transaction is re-simulated after signing so resource fees reflect the real signature size.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountCredentialException`.

#### fundWallet(...)

```swift
public func fundWallet(
    nativeTokenContract: String,
    forceMethod: OZSubmissionMethod? = nil
) async throws -> String
```

Funds the connected smart-account wallet using Friendbot. Testnet only; hard-codes the Friendbot URL `https://friendbot.stellar.org/` and has no mainnet equivalent. Generates a fresh temporary keypair, funds it via Friendbot, then transfers the surplus (balance minus the protocol minimum-balance reserve) to the smart-account contract over the native token contract.

**Returns**: Funded amount as a decimal XLM string (for example `"100"` or `"12.34567"`); trailing zeros in the fractional component are trimmed.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

### Result Types

#### OZTransactionResult

```swift
public struct OZTransactionResult: Sendable, Equatable, Hashable {
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

#### OZResolveContextRuleIds

```swift
public typealias OZResolveContextRuleIds = @Sendable (
    _ entry: SorobanAuthorizationEntryXDR,
    _ index: Int
) async throws -> [UInt32]
```

Callback used to override the automatic context-rule resolution that runs during the signing loop. Invoked once per matching auth entry. The first argument carries the authorization entry being signed; the second is the entry's index in the simulation-supplied list. The returned identifiers replace the resolution that otherwise runs against the connected signer set. Errors thrown from the callback propagate to the caller of `submit(...)`.

#### OZSubmissionMethod

```swift
public enum OZSubmissionMethod: Sendable {
    case relayer
    case rpc
}
```

Overrides the default automatic submission-method selection for a single call. `relayer` fails if no relayer is configured on the kit; `rpc` is always available.

---

## Credential Management

### OZCredentialManager

```swift
public final class OZCredentialManager: @unchecked Sendable { ... }
```

Accessed via `kit.credentialManager`. Persists, queries, updates, and deletes stored credentials, and reconciles local credential state against on-chain deployment status.

Stored credentials occupy two persistent states after creation: `pending` and `failed`. There is no `success` state — credentials are deleted from storage on successful deployment (or when a sync discovers the contract on-chain). Failed deployments can be retried by deleting the credential and re-creating one with the same identifier, or by calling `walletOperations.deployPendingCredential(...)`.

#### createPendingCredential(...)

```swift
public func createPendingCredential(
    credentialId: String,
    publicKey: Data,
    contractId: String,
    nickname: String? = nil,
    transports: [String]? = nil,
    deviceType: String? = nil,
    backedUp: Bool? = nil
) async throws -> OZStoredCredential
```

Creates a new pending credential and persists it to storage. The credential is created with `deploymentStatus == .pending`, `isPrimary == false`, and `createdAt` set to the current wall-clock time in milliseconds. The `contractId` is required and non-optional.

Validation: `publicKey` must be exactly `SmartAccountConstants.secp256r1PublicKeySize` (65) bytes; `credentialId` must not be empty and must be unique within storage.

**Returns**: The persisted `OZStoredCredential`.

**Throws**: `SmartAccountValidationException.InvalidInput`, `SmartAccountCredentialException.AlreadyExists`, `SmartAccountStorageException.WriteFailed`.

#### saveCredential(...)

```swift
public func saveCredential(
    credentialId: String,
    publicKey: Data,
    nickname: String? = nil,
    contractId: String? = nil
) async throws -> OZStoredCredential
```

Saves a credential with looser validation than `createPendingCredential(...)`. Does NOT check for duplicates, does NOT capture deployment-time WebAuthn metadata (`transports`, `deviceType`, `backedUp`), persists `isPrimary = false`, and stores `contractId == nil` as the empty string to match the on-chain "not yet derived" sentinel used by other call sites.

**Throws**: `SmartAccountValidationException.InvalidInput`, `SmartAccountStorageException.WriteFailed`.

#### sync(...)

```swift
@discardableResult
public func sync(credentialId: String) async throws -> Bool
```

Reconciles a single stored credential with on-chain state. Returns `true` when the credential's contract is now confirmed deployed on-chain (in which case the credential is removed from storage), `false` otherwise. RPC failures that prevent the on-chain check emit `OZSmartAccountEvent.credentialSyncFailed(credentialId:error:)` and leave the credential in storage for a subsequent retry.

#### syncAll()

```swift
public func syncAll() async throws -> OZSyncResult
```

Reconciles every stored credential with on-chain state and returns a summary of how many were confirmed deployed (and removed), how many remain pending, and how many failed deployment.

#### deleteCredential(...)

```swift
public func deleteCredential(credentialId: String) async throws
```

Removes the named credential from storage and emits `OZSmartAccountEvent.credentialDeleted(credentialId:)`. Before deleting, the manager runs `sync(credentialId:)`; if the contract is already deployed on-chain the credential is reconciled out and the call throws `SmartAccountCredentialException.Invalid` (a deployed wallet cannot be deleted). Throws `SmartAccountCredentialException.NotFound` if no such credential exists, or `SmartAccountStorageException` on a storage read/write failure.

#### getCredential(...)

```swift
public func getCredential(credentialId: String) async throws -> OZStoredCredential?
```

Returns the stored credential matching the supplied identifier, or `nil` when absent.

#### getCredentialsByContract(...)

```swift
public func getCredentialsByContract(contractId: String) async throws -> [OZStoredCredential]
```

Returns every stored credential whose `contractId` matches the supplied address.

#### getAllCredentials()

```swift
public func getAllCredentials() async throws -> [OZStoredCredential]
```

Returns every stored credential.

#### getForConnectedWallet()

```swift
public func getForConnectedWallet() async throws -> [OZStoredCredential]
```

Returns every stored credential whose `contractId` matches the kit's currently connected contract.

#### getPendingCredentials()

```swift
public func getPendingCredentials() async throws -> [OZStoredCredential]
```

Returns every stored credential whose `deploymentStatus` is `.pending` or `.failed`.

#### updateNickname(...)

```swift
public func updateNickname(credentialId: String, nickname: String?) async throws
```

Updates the nickname of the named credential. Throws `SmartAccountCredentialException.NotFound` if no such credential exists.

#### clearAll()

```swift
public func clearAll() async throws
```

Removes every stored credential. Does not clear the active session.

### Result Types

#### OZSyncResult

```swift
public struct OZSyncResult: Sendable, Equatable, Hashable {
    public let deployed: Int
    public let pending: Int
    public let failed: Int
}
```

Number of credentials confirmed deployed on-chain (and removed from storage during the sync), still pending deployment, and with `failed` deployment status.

#### OZStoredCredential

```swift
public struct OZStoredCredential: Sendable, Equatable, Hashable {
    public let credentialId: String
    public let publicKey: Data
    public let contractId: String?
    public let deploymentStatus: OZCredentialDeploymentStatus
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

#### OZCredentialDeploymentStatus

```swift
public enum OZCredentialDeploymentStatus: String, Sendable, CaseIterable {
    case pending = "PENDING"
    case failed = "FAILED"
}
```

There is no `success` arm; successful deployment removes the credential from storage rather than transitioning it to a third state.

#### OZStoredCredentialUpdate

```swift
public struct OZStoredCredentialUpdate: Sendable, Equatable, Hashable
```

Sparse update value used by the underlying `OZStorageAdapter.update(credentialId:updates:)` contract; consumer code typically reaches it only when implementing a custom `OZStorageAdapter`.

#### OZStoredSession

```swift
public struct OZStoredSession: Sendable, Equatable, Hashable
```

Persisted session record consumed by the `OZStorageAdapter` session methods.

---

## Signer Management

### OZSignerManager

```swift
public final class OZSignerManager: @unchecked Sendable { ... }
```

Accessed via `kit.signerManager`. Adds and removes signers bound to a context rule. Supported signer kinds:

- WebAuthn passkeys (secp256r1 verified through a verifier contract).
- Delegated signers (Stellar `G…` accounts or `C…` contract addresses authorising through the host's built-in `require_auth`).
- Ed25519 signers (32-byte Ed25519 keys verified by a verifier contract).

Every state-changing method accepts an optional `selectedSigners: [OZSelectedSigner]` parameter. When empty (default), the operation uses single-signer authorization through the connected passkey credential. When non-empty, the operation routes through the multi-signer ceremony coordinator that collects signatures from every listed signer and assembles the final authorization payload.

#### addNewPasskeySigner(...)

```swift
public func addNewPasskeySigner(
    contextRuleId: UInt32,
    userName: String,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZAddPasskeySignerResult
```

Runs the full end-to-end "register a fresh passkey and add it as a signer" flow: validates the kit's connection state and the WebAuthn provider, generates 32-byte random challenge and user-id buffers, prompts for biometric registration, persists the new credential as `pending` in storage, emits `OZSmartAccountEvent.credentialCreated(credential:)`, and finally adds the resulting public key as a signer on the smart-account contract by delegating to `addPasskey(...)`. In single-signer mode the user is prompted for biometric authentication twice: once for the new passkey registration and once for the existing signer to authorize the addition.

**Throws**: `SmartAccountWalletException.NotConnected`, `WebAuthnException.NotSupported`, `WebAuthnException`, `SmartAccountCredentialException`, `SmartAccountTransactionException`.

#### addPasskey(...)

```swift
public func addPasskey(
    contextRuleId: UInt32,
    publicKey: Data,
    credentialId: Data,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Adds a WebAuthn passkey signer to a context rule when the credential identifier and public key are already in hand. Builds an `OZExternalSigner.webAuthn(verifierAddress:publicKey:credentialId:)` (the verifier address is sourced from `config.webauthnVerifierAddress`) and submits an `add_signer` invocation against the smart-account contract. The on-chain transaction requires authorization from an existing signer on the supplied context rule.

`publicKey` must be the canonical uncompressed 65-byte secp256r1 form starting with `0x04`; `credentialId` must be non-empty. The signer's key data (`publicKey || credentialId`) is limited to `OZConstants.maxExternalKeySize` (256) bytes — the same limit applies to every signer-addition path that produces an external signer.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

#### addDelegated(...)

```swift
public func addDelegated(
    contextRuleId: UInt32,
    address: String,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Adds a delegated signer (Stellar `G…` account or `C…` contract) to a context rule. The signer authorises through the host's built-in `require_auth` mechanism; no verifier contract is required.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException.InvalidAddress`, `SmartAccountTransactionException`.

#### addEd25519(...)

```swift
public func addEd25519(
    contextRuleId: UInt32,
    verifierAddress: String,
    publicKey: Data,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Adds an Ed25519 signer to a context rule. Constructs an `OZExternalSigner.ed25519(verifierAddress:publicKey:)` and submits an `add_signer` invocation. `publicKey` must be the canonical 32-byte Ed25519 encoding.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

#### removeSigner(...)

```swift
public func removeSigner(
    contextRuleId: UInt32,
    signerId: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Removes a signer from a context rule by its on-chain numeric identifier. The id is assigned by the smart-account contract when the signer is added and surfaces on `OZParsedContextRule.signerIds` after a rule fetch. The contract returns error code 3004 if the last signer is removed from a rule with no configured policies.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException`.

#### removeSignerBySigner(...)

```swift
public func removeSignerBySigner(
    contextRuleId: UInt32,
    signer: any OZSmartAccountSigner,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Removes a signer by matching the signer value. Resolves the numeric signer id internally with one extra RPC round trip (fetches and parses the target context rule), then delegates to `removeSigner(contextRuleId:signerId:...)`. The `BySigner` suffix disambiguates this method from the id-based overload.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException` (signer not found, signer / signerId array misalignment), `SmartAccountConfigurationException` (when the manager was constructed without a context-rule parser), `SmartAccountTransactionException`.

### Result Types

#### OZAddPasskeySignerResult

```swift
public struct OZAddPasskeySignerResult: Sendable, Hashable {
    public let credentialId: String
    public let publicKey: Data
    public let transactionResult: OZTransactionResult
}
```

| Field | Type | Description |
|---|---|---|
| `credentialId` | `String` | Base64URL-encoded credential identifier. |
| `publicKey` | `Data` | Uncompressed secp256r1 public key bytes. |
| `transactionResult` | `OZTransactionResult` | On-chain signer-addition transaction outcome. |

Equality uses constant-time comparison on `publicKey`.

---

## Context Rule Management

### OZContextRuleManager

```swift
public final class OZContextRuleManager: @unchecked Sendable { ... }
```

Accessed via `kit.contextRuleManager`. Creates, lists, updates, and removes context rules on the connected smart-account contract. Contract limits enforced before submission:

- Maximum `OZConstants.maxNameSize` (20) UTF-8 bytes per rule name (byte count, not character count).
- Maximum `OZConstants.maxSigners` (15) signers per rule.
- Maximum `OZConstants.maxExternalKeySize` (256) bytes of key data per external signer.
- Maximum `OZConstants.maxPolicies` (5) policies per rule.

A context rule must have at least one signer or one policy.

#### addContextRule(...)

```swift
public func addContextRule(
    contextType: OZContextRuleType,
    name: String,
    validUntil: UInt32? = nil,
    signers: [any OZSmartAccountSigner],
    policies: [String: SCValXDR] = [:],
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Adds a new context rule. `contextType` selects the matching policy (default rule, call-contract, or create-contract). `name` is the human-readable rule name (non-empty, at most `OZConstants.maxNameSize` UTF-8 bytes). `validUntil` is the optional ledger number at which the rule expires (`nil` for non-expiring). `signers` lists the signers authorised by the rule; each external signer's key data is limited to `OZConstants.maxExternalKeySize` bytes. `policies` maps policy contract addresses (`C…` strkey) to their installation parameters encoded as `SCValXDR`; map keys are sorted into the Soroban host's `ScMap` key order before submission.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException.InvalidInput`, `SmartAccountValidationException.InvalidAddress`, `SmartAccountTransactionException`.

#### getContextRule(...)

```swift
public func getContextRule(id: UInt32) async throws -> SCValXDR
```

Returns the raw `SCValXDR` payload for a single context rule. Callers that need a typed view should parse the result with the kit's parser or use `listContextRules()`, which performs the parse step internally. Read-only — issues a simulated invocation against the connected contract.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException.SimulationFailed` (commonly when the rule does not exist on chain).

#### getContextRulesCount()

```swift
public func getContextRulesCount() async throws -> UInt32
```

Returns the number of context rules currently configured on the connected smart account. Read-only.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException`, `SmartAccountValidationException.InvalidInput` (when the on-chain result is not a `U32`).

#### getAllContextRules(...)

```swift
public func getAllContextRules(maxScanId: UInt32? = nil) async throws -> [SCValXDR]
```

Retrieves every active context rule as raw `SCValXDR` map payloads in ascending id order. The contract assigns monotonically increasing identifiers; removed rules leave numeric gaps. The method iterates identifiers from zero upward, skipping gaps reported as `SmartAccountTransactionException.SimulationFailed`, until either the active rule count has been collected or the effective scan upper bound is reached. Pass `maxScanId: nil` (the default) to use `config.maxContextRuleScanId`, or a per-call upper bound.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException`, `SmartAccountValidationException`.

#### listContextRules(...)

```swift
public func listContextRules(maxScanId: UInt32? = nil) async throws -> [OZParsedContextRule]
```

Returns the parsed view of every active context rule. Internally calls `getAllContextRules(...)` and parses each entry through the internal context-rule parser.

**Throws**: Same as `getAllContextRules(...)`.

#### updateName(...)

```swift
public func updateName(
    id: UInt32,
    name: String,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Updates the human-readable name of an existing rule. The `name` field is metadata only — it has no effect on rule matching or enforcement. Must be non-empty and at most `OZConstants.maxNameSize` (20) UTF-8 bytes.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException.InvalidInput`, `SmartAccountTransactionException`.

#### updateValidUntil(...)

```swift
public func updateValidUntil(
    id: UInt32,
    validUntil: UInt32?,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Updates the expiration ledger of an existing rule. Pass `nil` to clear the expiration (the rule becomes non-expiring). On chain the field is `Option<u32>` encoded as `Void` for `None` and `U32` for `Some`.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException`.

#### removeContextRule(...)

```swift
public func removeContextRule(
    id: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Removes a context rule. Removed rules leave a numeric gap in the identifier sequence that the scan-based enumeration helpers skip.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException`.

### Result Types

#### OZContextRuleType

```swift
public enum OZContextRuleType: Sendable, Hashable {
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

#### OZParsedContextRule

```swift
public struct OZParsedContextRule: Sendable, Hashable {
    public let id: UInt32
    public let contextType: OZContextRuleType
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

### OZPolicyManager

```swift
public final class OZPolicyManager: @unchecked Sendable { ... }
```

Accessed via `kit.policyManager`. Adds and removes policies on context rules. Policies are authorization rules that must be satisfied for a transaction to authorize on the smart account; a context rule may carry up to `OZConstants.maxPolicies` (5) policies, and every attached policy must be satisfied.

Three built-in policy contracts ship with the OpenZeppelin suite. The manager exposes convenience methods for each plus a generic `addPolicy(...)` entry point for custom policy contracts.

All state-changing methods accept the same `selectedSigners` / `forceMethod` pair as the other managers.

#### addSimpleThreshold(...)

```swift
public func addSimpleThreshold(
    contextRuleId: UInt32,
    policyAddress: String,
    threshold: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Installs a simple threshold policy requiring at least `threshold` of the context rule's signers to authorize, with equal weight per signer. `threshold` must be greater than zero. Encodes the parameters through `OZPolicyInstallParams.simpleThreshold(threshold:)` and delegates to `addPolicy(...)`.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

#### addWeightedThreshold(...)

```swift
public func addWeightedThreshold(
    contextRuleId: UInt32,
    policyAddress: String,
    signerWeights: [OZSignerWeightEntry],
    threshold: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Installs a weighted threshold policy. Authorization succeeds when the summed weights of authorizing signers meet or exceed `threshold`. `signerWeights` must be non-empty. Encoded through `OZPolicyInstallParams.weightedThreshold(signerWeights:threshold:)`.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

#### addSpendingLimit(...)

```swift
public func addSpendingLimit(
    contextRuleId: UInt32,
    policyAddress: String,
    spendingLimit: String,
    periodLedgers: UInt32,
    decimals: Int = 7,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Installs a spending limit policy that caps cumulative spend within a rolling `periodLedgers`-ledger window (Stellar produces a ledger approximately every five seconds; one hour is `StellarProtocolConstants.ledgersPerHour`, one day is approximately 17 280 ledgers). The amount is supplied as a positive decimal string and converted to the token's base units using `decimals` (default 7). This method has no token-contract parameter, so it does not fetch the scale automatically.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

#### removePolicy(...)

```swift
public func removePolicy(
    contextRuleId: UInt32,
    policyId: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Removes a policy from a context rule by its on-chain numeric id. The id surfaces on `OZParsedContextRule.policyIds`.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountTransactionException`.

#### removePolicyByAddress(...)

```swift
public func removePolicyByAddress(
    contextRuleId: UInt32,
    policyAddress: String,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Removes a policy by matching the policy contract address. Resolves the numeric id internally with one extra RPC round trip (fetches and parses the target rule, locates the policy address within `policies`), then delegates to `removePolicy(...)`. The Swift method name has the explicit `ByAddress` suffix for the same overload-resolution reason as `removeSignerBySigner(...)`.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`.

#### addPolicy(...)

```swift
public func addPolicy(
    contextRuleId: UInt32,
    policyAddress: String,
    installParams: SCValXDR,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Generic policy installation. Use this method directly when installing a custom policy contract not covered by the three convenience helpers. The structure of `installParams` depends on the target policy contract; for the three built-in policy types, build an `OZPolicyInstallParams` value and call its `toScVal()` to obtain the encoded `SCValXDR` (prefer the convenience helpers, which call the encoder internally).

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException` (when `policyAddress` is malformed), `SmartAccountTransactionException`.

### Static Helpers

#### sortMapByKeyXdr(_:)

```swift
public static func sortMapByKeyXdr(_ entries: [SCMapEntryXDR]) -> [SCMapEntryXDR]
```

Sorts a list of `SCMapEntryXDR` entries into the Soroban host's `ScMap` key order. The host stores and validates map keys in a semantic order — different SCVal types by discriminant; `Vec`/`Map` element-wise (recursively); `Bytes`/`String`/`Symbol` by content, byte for byte, with length only a tiebreaker on a shared prefix — and rejects a map materialized from an out-of-order `SCVal` argument. Use this helper whenever a dynamically-keyed map is built from caller-supplied data so the on-chain shape is deterministic regardless of insertion order. The input list is not mutated.

### Supporting Types

#### OZPolicyInstallParams

```swift
public enum OZPolicyInstallParams: Sendable {
    case simpleThreshold(threshold: UInt32)
    case weightedThreshold(signerWeights: [OZSignerWeightEntry], threshold: UInt32)
    case spendingLimit(spendingLimit: String, periodLedgers: UInt32)
}
```

Installation parameters for the three built-in policy types. Most callers should use the convenience methods on `OZPolicyManager` (`addSimpleThreshold(...)`, `addWeightedThreshold(...)`, `addSpendingLimit(...)`), which build and encode the params internally. Construct `OZPolicyInstallParams` directly and call `toScVal()` to obtain the encoded value for `addPolicy(installParams:)` when installing a custom policy contract.

#### toScVal()

```swift
public func toScVal() throws -> SCValXDR
```

Encodes the installation parameters into the `Map`-shaped `SCValXDR` value the smart-account contract's `add_policy` method expects, with map key ordering normalized to satisfy Soroban's strict map-key ordering.

**Throws**: `SmartAccountValidationException.InvalidInput` when the variant's parameters are invalid (zero threshold, empty signer weights, non-positive spending limit, zero period, or malformed spending-limit string).

#### OZSignerWeightEntry

```swift
public struct OZSignerWeightEntry: Sendable {
    public let signer: any OZSmartAccountSigner
    public let weight: UInt32

    public init(signer: any OZSmartAccountSigner, weight: UInt32)
}
```

A single signer-weight pair used by `OZPolicyInstallParams.weightedThreshold` and by `addWeightedThreshold(...)`. Weight must be greater than zero — a zero-weight signer is indistinguishable from no signer at all and is rejected by the smart-account contract.

---

## Multi-Signer Operations

### OZMultiSignerManager

```swift
public class OZMultiSignerManager: @unchecked Sendable { ... }
```

Accessed via `kit.multiSignerManager`. Collects signatures from a caller-supplied list of signers (passkeys, Ed25519 external signers, and external-wallet addresses) and submits the resulting transaction through the kit's transaction operations.

Signatures are collected sequentially in the order supplied via `selectedSigners`. Each `OZSelectedSigner.passkey(...)` triggers exactly one OS WebAuthn authentication prompt; each `OZSelectedSigner.wallet(...)` triggers exactly one external-wallet signing request; each `OZSelectedSigner.ed25519(...)` calls `OZExternalSignerManager.signEd25519AuthDigest(...)` using the signing source registered for that `(verifierAddress, publicKey)` pair. Sequential collection enables fail-fast behaviour on user cancellation. The connected passkey is NOT added implicitly — include it explicitly via `OZSelectedSigner.passkey(...)` when the connected passkey should sign.

#### multiSignerTransfer(...)

```swift
public func multiSignerTransfer(
    tokenContract: String,
    recipient: String,
    amount: String,
    decimals: Int? = nil,
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

SEP-41 token transfer signed by an explicit list of signers. Validates the connection, the recipient address, the self-transfer guard, the amount, and that `selectedSigners` is non-empty before delegating to `multiSignerContractCall(...)`. The amount is converted to base units using `decimals` when supplied, otherwise the token's on-chain `decimals()` value is fetched automatically via `fetchTokenDecimals(tokenContract:)`.

**Throws**: `SmartAccountWalletException.NotConnected`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountConfigurationException` (when wallet signers are supplied but no external-wallet adapter is configured).

#### multiSignerContractCall(...)

```swift
public func multiSignerContractCall(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Multi-signer counterpart to `OZTransactionOperations.contractCall(...)`. Builds a host function that invokes `target.targetFn(targetArgs)` directly so a context rule of type `callContract(target)` matches the authorization, allowing contract-specific multi-signer rules to apply.

**Throws**: `SmartAccountWalletException`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountConfigurationException`.

#### multiSignerExecuteAndSubmit(...)

```swift
public func multiSignerExecuteAndSubmit(
    target: String,
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Multi-signer counterpart to `OZTransactionOperations.executeAndSubmit(...)`. Routes the call through the smart-account contract's `execute(target, target_fn, target_args)` entry point with multi-signer authorization. Use this when a contract call must be authorized by multiple signers — for example a governance vote, a multi-sig swap, or any operation gated by a multi-signer context rule.

**Throws**: `SmartAccountWalletException`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountConfigurationException`.

#### submitWithMultipleSigners(...)

```swift
public func submitWithMultipleSigners(
    hostFunction: HostFunctionXDR,
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Shared low-level multi-signer signing pipeline. Validates the complete signer set, simulates the host function to discover authorization entries, signs every matching entry with every supplied signer, re-simulates so the resource fees reflect the real signature payload size, and submits the final envelope. Entries with legacy `ADDRESS` or protocol-27 `ADDRESS_V2` credentials are signed with the arm preserved; entries carrying `ADDRESS_WITH_DELEGATES` credentials are rejected with `SigningFailed` — delegated entries must be signed per delegate node via `SorobanAuthorizationEntryXDR.sign(forAddress:)` before submission. The three higher-level entry points delegate here; the signer, policy, and context-rule managers also reach this method internally when a non-empty `selectedSigners` list is supplied to one of their state-changing methods.

Validation order: connection check, per-wallet-signer reachability via `kit.externalSigners.canSignFor(address:)` (covers both in-memory keypairs and the configured wallet adapter), per-passkey-signer `keyData` precondition (every passkey entry must carry pre-fetched `keyData` so context-rule resolution and signature binding can run without an extra on-chain lookup), per-Ed25519-signer registration check via `kit.externalSigners.canSignEd25519For(verifierAddress:publicKey:)` and public-key length enforcement (must be 32 bytes), initial simulation surface error, re-simulation surface error.

**Throws**: `SmartAccountWalletException`, `SmartAccountValidationException`, `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountConfigurationException`.

### OZSelectedSigner

```swift
public enum OZSelectedSigner: Sendable, Hashable {
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
- `credentialIdBytes` — Optional raw credential identifier bytes. When supplied, the multi-signer pipeline includes a matching `WebAuthnAllowCredential` (with `transports`) on the WebAuthn authentication request so the OS can route to the correct passkey. When `nil`, the authenticator falls back to its default credential discovery.
- `keyData` — Optional pre-fetched secp256r1 public key followed by credential id bytes (`publicKey || credentialId`). Supplying this avoids an indexer lookup during signature collection. In multi-signer ceremonies every `passkey` entry must carry non-`nil` `keyData`; the auth pipeline reconstructs external signers once per call, not per entry, so a `nil` entry fails at runtime.
- `transports` — Optional WebAuthn transport hints (`"internal"`, `"hybrid"`, `"usb"`, `"ble"`, `"nfc"`) propagated into the `WebAuthnAllowCredential` when `credentialIdBytes` is non-`nil`.

`wallet`:
- `accountId` — Stellar `G…` strkey of the wallet that will produce the signature. The signing source is resolved via `kit.externalSigners`: an in-memory keypair registered via `kit.externalSigners.addFromSecret(secretKey:)` takes precedence; when no in-memory keypair is registered for the address, the configured `OZExternalWalletAdapter` is used.

`ed25519`:
- `verifierAddress` — C-strkey of the Ed25519 verifier contract registered as part of the on-chain `External(verifierAddress, publicKey)` signer entry. The smart-account contract calls this verifier during `__check_auth` to validate the Ed25519 signature.
- `publicKey` — 32-byte Ed25519 public key that identifies the signer slot on the smart account. Must match the public key registered in the on-chain signer entry.

The `ed25519` case carries no signing material. It is purely an identifier; the actual signing capability is provided by registering an in-memory keypair via `kit.externalSigners.addEd25519FromRawKey(secretKeyBytes:verifierAddress:)` at runtime, or by supplying an `OZExternalEd25519SignerAdapter` via `config.externalEd25519Adapter` at kit construction.

```swift
// One transfer authorized by three signer kinds. kit.externalSigners resolves each source.
let result = try await kit.multiSignerManager.multiSignerTransfer(
    tokenContract: tokenContract,
    recipient: recipient,
    amount: "10",
    selectedSigners: [
        .passkey(credentialId: savedCredId, keyData: savedKeyData),
        .wallet(accountId: walletAccountId),
        .ed25519(verifierAddress: ed25519VerifierAddress, publicKey: ed25519PublicKey)
    ]
)
```

See [Onboarding — Signing](onboarding.md#signing) for registering each signing source and the full multi-signer walkthrough.

---

## External Signer Management

### OZExternalSignerManager

```swift
public actor OZExternalSignerManager
```

Manager for non-passkey signers used by multi-signer smart-account operations. Coordinates Stellar account signers (raw Ed25519 secret keys in memory or external wallet connections through `OZExternalWalletAdapter`), and Ed25519 signers identified by a `(verifierAddress, publicKey)` tuple. The kit constructs and owns one instance, accessible via `kit.externalSigners`. Two custody models are available for each signer kind: supply an adapter at kit-construction time via the config, or register an in-memory key at runtime via the manager methods.

```swift
public init(
    networkPassphrase: String,
    walletAdapter: OZExternalWalletAdapter? = nil,
    ed25519Adapter: OZExternalEd25519SignerAdapter? = nil
)
```

`walletAdapter` enables wallet-based signers; connected wallets are surfaced from the live adapter for the duration of the running process. `ed25519Adapter` provides out-of-process Ed25519 signing at construction time; in-memory keypairs are registered at runtime via `addEd25519FromRawKey(secretKeyBytes:verifierAddress:)`. Keypair signers are never persisted — secret material is reachable only through the in-memory `KeyPair` instance.

All public methods are `async` (or `async throws`) due to actor isolation.

#### hasWalletAdapter

```swift
public var hasWalletAdapter: Bool { get }
```

`true` when a non-`nil` `walletAdapter` was supplied at construction time.

#### addFromSecret(secretKey:)

```swift
public func addFromSecret(secretKey: String) async throws -> String
```

Decodes the supplied Stellar `S…` secret-key strkey into an in-memory `KeyPair` and registers it as a signer. Returns the corresponding `G…` account address.

**Throws**: `SmartAccountSignerException.Invalid` when the secret key is malformed.

#### canSignFor(address:)

```swift
public func canSignFor(address: String) async -> Bool
```

`true` when the manager has either a keypair-based signer or a wallet-based signer registered for the given `G…` address.

#### get(address:)

```swift
public func get(address: String) async -> OZExternalSignerInfo?
```

Returns the registered signer metadata for the given address, or `nil` when none exists.

#### getAll()

```swift
public func getAll() async -> [OZExternalSignerInfo]
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
) async throws -> OZSignAuthEntryResult
```

Signs a base64-encoded Soroban authorization preimage on behalf of the named signer. Keypair signers run an in-process Ed25519 sign; wallet signers delegate to the configured `walletAdapter`. Returns an `OZSignAuthEntryResult` containing the signature and (when available) the address that produced it.

**Throws**: `SmartAccountSignerException.NotFound` when no signer matches the address; `SmartAccountTransactionException.SigningFailed` when signing fails.

#### remove(address:)

```swift
public func remove(address: String) async throws
```

Removes the signer registered for the supplied address. For wallet signers, calls the adapter's `disconnectByAddress(address:)`.

**Throws**: `SmartAccountSignerException.NotFound` when no signer matches.

#### removeAll()

```swift
public func removeAll() async throws
```

Removes every registered signer: clears all in-memory keypair signers (registered via `addFromSecret`), clears all Ed25519 keypairs (registered via `addEd25519FromRawKey`), and disconnects all external wallets.

#### addEd25519FromRawKey(secretKeyBytes:verifierAddress:)

```swift
public func addEd25519FromRawKey(secretKeyBytes: Data, verifierAddress: String) throws -> Data
```

Creates an Ed25519 keypair from the supplied raw 32-byte secret seed and registers it in memory under the `(verifierAddress, publicKey)` tuple. The keypair is never persisted to storage; it is cleared when `removeEd25519(verifierAddress:publicKey:)` is called or when the manager is deinitialized.

If a keypair is already registered for the same tuple, it is silently overwritten.

**Parameters**:
- `secretKeyBytes`: Raw 32-byte Ed25519 secret seed. Must be exactly 32 bytes.
- `verifierAddress`: C-strkey of the Ed25519 verifier contract under which this key is registered on-chain.

**Returns**: The derived 32-byte Ed25519 public key. Pass this as the `publicKey` argument of `OZSelectedSigner.ed25519(verifierAddress:publicKey:)` to route multi-signer signing through this keypair.

**Throws**: `SmartAccountValidationException.InvalidInput` when `secretKeyBytes` is not exactly 32 bytes; `SmartAccountSignerException.Invalid` when keypair construction fails from the supplied seed.

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
let signer = OZSelectedSigner.ed25519(
    verifierAddress: ed25519VerifierAddress,
    publicKey: ed25519PublicKey
)
```

See also: [`OZSelectedSigner.ed25519`](#ozselectedsigner) in the Multi-Signer Operations section.

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

The multi-signer pipeline calls this method automatically for each `OZSelectedSigner.ed25519(...)` entry in `selectedSigners`. Direct calls are available for advanced integrations that need to produce signatures outside the pipeline.

**Parameters**:
- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot.
- `authDigest`: 32-byte auth digest to sign, computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.

**Returns**: 64-byte raw Ed25519 signature over `authDigest`.

**Throws**: `SmartAccountValidationException.InvalidInput` (field `"selectedSigners"`) when no signing source is registered; `SmartAccountTransactionException.SigningFailed` when the adapter or in-memory keypair fails to produce a valid signature.

> **Quirk — adapter-first precedence**: when an `OZExternalEd25519SignerAdapter` is supplied via `config.externalEd25519Adapter` and its `canSignFor(verifierAddress:publicKey:)` returns `true`, the adapter always signs, even if an in-memory keypair is also registered for the same tuple. To force the in-memory path, construct the kit without `externalEd25519Adapter`.

> **Quirk — tuple-keyed storage**: the same 32-byte public key registered under two different verifier addresses is stored as two distinct entries. This matches the on-chain signer identity, where an `External(verifierAddress, publicKey)` entry is uniquely identified by both fields. Passing the wrong `verifierAddress` results in `SmartAccountValidationException.InvalidInput` even when the public key is correct.

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
- Returns a 64-byte raw Ed25519 signature over `authDigest`. The pipeline locally verifies the returned signature via `KeyPair.verify(signature:message:)` before incorporating it into the authorization payload; a wrong signature throws `SmartAccountTransactionException.SigningFailed`.
- Throws any error that prevents signing (hardware unavailable, user cancelled, etc.).

```swift
final class MyHardwareWalletAdapter: OZExternalEd25519SignerAdapter {
    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool { /* ... */ }
    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data { /* 64-byte sig */ }
}
// Supply via config.externalEd25519Adapter; kit.externalSigners then routes signing through it.
```

See [Onboarding — Signing](onboarding.md#signing) for the adapter custody model and a worked configuration example.

> **Quirk — adapter-first precedence**: the adapter always signs when `canSignFor` returns `true`, even when an in-memory keypair is registered for the same `(verifierAddress, publicKey)` pair. To force the in-memory path, construct the kit without `externalEd25519Adapter`.

See also: [`OZExternalSignerManager.signEd25519AuthDigest`](#external-signer-management).

#### OZExternalSignerType

```swift
public enum OZExternalSignerType: String, Sendable, Codable, CaseIterable {
    case keypair = "KEYPAIR"
    case wallet = "WALLET"
}
```

#### OZExternalSignerInfo

```swift
public struct OZExternalSignerInfo: Sendable, Codable, Equatable, Hashable {
    public let address: String
    public let type: OZExternalSignerType
    public let walletName: String?
    public let walletId: String?
}
```

`walletName` and `walletId` are populated only when `type == .wallet`.

#### OZConnectedWallet

```swift
public struct OZConnectedWallet: Sendable, Equatable, Hashable
```

Connected-wallet record surfaced by the `OZExternalWalletAdapter` (`connect()`, `getConnectedWallets()`).

#### OZSignAuthEntryOptions / OZSignAuthEntryResult

```swift
public struct OZSignAuthEntryOptions: Sendable, Equatable, Hashable
public struct OZSignAuthEntryResult: Sendable, Equatable, Hashable
```

Options bag and result value used by `OZExternalWalletAdapter.signAuthEntry(preimageXdr:options:)` and by `OZExternalSignerManager.signAuthEntry(...)`.

---

## Events

> **Scope — SDK lifecycle events only.** `kit.events` emits **kit-level** events (wallet connected/disconnected, credential created/deleted, session expired, transaction signed/submitted). It does **not** emit on-chain smart-account contract events such as `SignerAdded`, `SignerRemoved`, `PolicyInstalled`, `PolicyRemoved`, `ContextRuleAdded`, or `ContextRuleRemoved`. Those are emitted by the OpenZeppelin smart-account contract and must be queried via `SorobanServer.getEvents(...)` with the account's contract ID as a filter.
>
> To fetch on-chain contract events, query the core SDK once the wallet is connected:
>
> ```swift
> let filter = EventFilter(type: "contract", contractIds: [contractId])
> let response = await kit.sorobanServer.getEvents(startLedger: fromLedger, eventFilters: [filter])
> // On .success, each event's topic and value are base64-XDR-encoded SCVal entries.
> ```
>
> See the core SDK `SorobanServer.getEvents(...)` documentation for the full response shape; parse `topic` and `value` with the SDK's XDR utilities.

### OZSmartAccountEventEmitter

```swift
public final class OZSmartAccountEventEmitter: @unchecked Sendable { ... }
```

Accessed via `kit.events`. Manages event subscriptions and dispatches events to all registered listeners. Subscription management and event emission are thread-safe; listener callbacks are invoked outside the internal lock so a listener may freely call back into the emitter (for example to unsubscribe itself) without deadlocking.

The emitter's public API is synchronous on purpose — async listener registration would force an extra suspension that would lose ordering for self-unsubscribe operations performed from inside `emit`.

#### init()

```swift
public init()
```

Initializes an emitter with no listeners and no error handler. Production code obtains the kit-owned emitter through `kit.events`; direct construction is supported for advanced integrations and unit tests.

#### setErrorHandler(_:)

```swift
public func setErrorHandler(_ handler: OZSmartAccountEventErrorHandler?)
```

Sets the error handler invoked when a listener throws. The error handler receives both the event being dispatched and the error thrown by the failing listener. Pass `nil` to disable error reporting (listener errors are then silently caught so a single failing listener cannot abort emission to the remaining listeners).

#### addListener(_:)

```swift
@discardableResult
public func addListener(_ listener: @escaping OZSmartAccountEventListener) -> OZSmartAccountEventUnsubscribe
```

Subscribes a global listener that receives every emitted event regardless of type. Use this from call sites that dispatch with a `switch` over the event itself. Returns a closure that unsubscribes the listener when called; calling the returned closure more than once is a no-op.

#### on(_:listener:)

```swift
@discardableResult
public func on(
    _ eventType: OZSmartAccountEventType,
    listener: @escaping OZSmartAccountEventListener
) -> OZSmartAccountEventUnsubscribe
```

Subscribes to events of a specific type. The listener is invoked only when an event matching `eventType` is emitted.

#### once(_:listener:)

```swift
@discardableResult
public func once(
    _ eventType: OZSmartAccountEventType,
    listener: @escaping OZSmartAccountEventListener
) -> OZSmartAccountEventUnsubscribe
```

Subscribes to a single occurrence of an event type. The listener is automatically unsubscribed before its body runs, so even a throwing listener is still removed exactly once. The returned closure unsubscribes the listener before it ever fires; calling it after the event has already fired is a no-op.

#### removeAllListeners(eventType:)

```swift
public func removeAllListeners(eventType: String? = nil)
public func removeAllListeners()
```

When `eventType` is non-`nil`, only type-specific listeners registered via `on(_:listener:)` for that event type are removed; global listeners registered via `addListener(_:)` are left intact. Passing `nil` (or calling the no-argument overload) removes every type-specific listener and every global listener.

#### listenerCount(eventType:)

```swift
public func listenerCount(eventType: String) -> Int
```

Returns the number of listeners currently registered for the supplied event tag. The count is the sum of type-specific listeners registered for `eventType` plus every global listener registered via `addListener(_:)`.

### OZSmartAccountEvent

```swift
public enum OZSmartAccountEvent: Sendable, Equatable, Hashable {
    case walletConnected(contractId: String, credentialId: String)
    case walletConnectedHeadless(contractId: String)
    case walletDisconnected(contractId: String)
    case credentialCreated(credential: OZStoredCredential)
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
| `walletConnectedHeadless` | `contractId` | A headless connection is established via `connectToContract(contractId:)` — bound to a contract with no passkey credential. |
| `walletDisconnected` | `contractId` | `kit.disconnect()` is called. The session is cleared; stored credentials remain. |
| `credentialCreated` | `credential` | A WebAuthn credential is registered (during initial wallet setup or when adding a new signer). The wallet may not be deployed yet. |
| `credentialDeleted` | `credentialId` | A credential is removed from storage. |
| `sessionExpired` | `contractId, credentialId` | A connect attempt finds an expired session. The application should prompt to reconnect. |
| `transactionSigned` | `contractId, credentialId?` | All required signatures are collected for a transaction, before submission. `credentialId` is `nil` when only external signers contributed. |
| `transactionSubmitted` | `hash, success` | A signed transaction is sent to Soroban RPC or the relayer. `success` indicates whether the submission succeeded at the network boundary, not whether the transaction was included in a ledger. |
| `credentialSyncFailed` | `credentialId, error` | `OZCredentialManager.sync(credentialId:)` cannot reach the RPC endpoint. The credential is retained in storage so a subsequent sync can retry. |

`eventTypeTag` returns the un-namespaced arm name (`"WalletConnected"`, `"WalletDisconnected"`, etc.) and matches the strings consumed by `removeAllListeners(eventType:)` and `listenerCount(eventType:)`. Equality on the `credentialSyncFailed` arm compares `error.localizedDescription` because `Error` does not conform to `Equatable`.

### OZSmartAccountEventType

```swift
public enum OZSmartAccountEventType: String, Sendable, CaseIterable {
    case walletConnected = "WalletConnected"
    case walletConnectedHeadless = "WalletConnectedHeadless"
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
public typealias OZSmartAccountEventListener = @Sendable (OZSmartAccountEvent) throws -> Void
public typealias OZSmartAccountEventErrorHandler = @Sendable (OZSmartAccountEvent, Error) -> Void
public typealias OZSmartAccountEventUnsubscribe = @Sendable () -> Void
```

The listener may throw; the emitter catches the error and routes it to the configured error handler so a failing listener never aborts dispatch to the remaining registrants. The unsubscribe closure is the only mechanism for listener removal — there is no `removeListener(handle:)` method.

---

## Errors

Every error path in the kit funnels into a `SmartAccountException` subclass so callers can rely on a single typed channel for error handling and can map errors back to a stable numeric `SmartAccountErrorCode`.

### SmartAccountErrorCode

> **Two independent namespaces share the 3xxx range.** `SmartAccountErrorCode` is the **SDK** error enum, surfaced via `SmartAccountException.code` when the kit raises a credential / wallet / WebAuthn / etc. error locally. A separate set of error codes — also in the 3xxx range — is defined by the **on-chain** OpenZeppelin smart-account contract and surfaced in transaction simulation / result XDR (typically wrapped in `SmartAccountTransactionException.simulationFailed`). The two overlap but do not collide at runtime because they arrive through different channels:
>
> | Numeric code | SDK meaning (`SmartAccountErrorCode`) | On-chain meaning (OZ contract) |
> |---|---|---|
> | 3002 | `.credentialAlreadyExists` | `UnvalidatedContext` |
> | 3003 | `.credentialInvalid` | `ExternalVerificationFailed` |
>
> The table above shows only the two codes the SDK enum reuses. On chain, the smart-account contract's `SmartAccountError` spans `3000` and `3002`-`3016`; the WebAuthn verifier's `WebAuthnError` occupies `3110`-`3119`; and the built-in policy contracts occupy `3200`-`3227`. When inspecting an error code, first check the exception type to determine which namespace it belongs to. The full catalog of on-chain codes is available in [`OZContractErrorCodes`](#ozcontracterrorcodes), together with the consumer-side `decode(_:)` / `decodeFromMessage(_:)` helpers — the SDK surfaces the raw error message but does not parse or map contract error codes itself; see the [OpenZeppelin contracts source](https://github.com/OpenZeppelin/stellar-contracts/blob/main/packages/accounts/src/smart_account/mod.rs) for the on-chain `SmartAccountError`, `WebAuthnError`, and policy error enums.


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

Every domain grouping below is `public class ... : SmartAccountException` with `public final class` arm subclasses. Construct arm instances through the factory methods on each grouping rather than the initializers.

### SmartAccountConfigurationException

```swift
public class SmartAccountConfigurationException: SmartAccountException {
    public final class InvalidConfig: SmartAccountConfigurationException { ... }
    public final class MissingConfig: SmartAccountConfigurationException { ... }

    public static func invalidConfig(details: String, cause: Error? = nil) -> InvalidConfig
    public static func missingConfig(param: String, cause: Error? = nil) -> MissingConfig
}
```

Thrown by `OZSmartAccountConfig` validation, by URL validation in `OZIndexerClient` / `OZRelayerClient`, by `AppleWebAuthnProvider` initialization, and by managers when a required collaborator is missing.

### SmartAccountWalletException

```swift
public class SmartAccountWalletException: SmartAccountException {
    public final class NotConnected: SmartAccountWalletException { ... }
    public final class AlreadyExists: SmartAccountWalletException { ... }
    public final class NotFound: SmartAccountWalletException { ... }

    public static func notConnected(details: String? = nil, cause: Error? = nil) -> NotConnected
    public static func alreadyExists(identifier: String, cause: Error? = nil) -> AlreadyExists
    public static func notFound(identifier: String, cause: Error? = nil) -> NotFound
}
```

`NotConnected` is thrown by every state-changing manager method when the kit is not connected. `NotFound` is thrown by `connectWallet(...)` when no contract can be resolved for the credential.

### SmartAccountCredentialException

```swift
public class SmartAccountCredentialException: SmartAccountException {
    public final class NotFound: SmartAccountCredentialException { ... }
    public final class AlreadyExists: SmartAccountCredentialException { ... }
    public final class Invalid: SmartAccountCredentialException { ... }
    public final class DeploymentFailed: SmartAccountCredentialException { ... }

    public static func notFound(credentialId: String, cause: Error? = nil) -> NotFound
    public static func alreadyExists(credentialId: String, cause: Error? = nil) -> AlreadyExists
    public static func invalid(reason: String, cause: Error? = nil) -> Invalid
    public static func deploymentFailed(reason: String, cause: Error? = nil) -> DeploymentFailed
}
```

Thrown by `OZCredentialManager` and by the wallet-operations module during credential creation and lifecycle transitions.

### WebAuthnException

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

### SmartAccountTransactionException

```swift
public class SmartAccountTransactionException: SmartAccountException {
    public final class SimulationFailed: SmartAccountTransactionException { ... }
    public final class SigningFailed: SmartAccountTransactionException { ... }
    public final class SubmissionFailed: SmartAccountTransactionException { ... }
    public final class Timeout: SmartAccountTransactionException { ... }

    public static func simulationFailed(reason: String, cause: Error? = nil) -> SimulationFailed
    public static func signingFailed(reason: String, cause: Error? = nil) -> SigningFailed
    public static func submissionFailed(reason: String, cause: Error? = nil) -> SubmissionFailed
    public static func timeout(details: String? = nil, cause: Error? = nil) -> Timeout
}
```

`SimulationFailed` is the common arm thrown by every read-only context-rule method when the on-chain rule does not exist.

### SmartAccountSignerException

```swift
public class SmartAccountSignerException: SmartAccountException {
    public final class NotFound: SmartAccountSignerException { ... }
    public final class Invalid: SmartAccountSignerException { ... }

    public static func notFound(signerId: String, cause: Error? = nil) -> NotFound
    public static func invalid(reason: String, cause: Error? = nil) -> Invalid
}
```

### SmartAccountValidationException

```swift
public class SmartAccountValidationException: SmartAccountException {
    public final class InvalidAddress: SmartAccountValidationException { ... }
    public final class InvalidAmount: SmartAccountValidationException { ... }
    public final class InvalidInput: SmartAccountValidationException { ... }

    public static func invalidAddress(address: String, cause: Error? = nil) -> InvalidAddress
    public static func invalidAmount(amount: String, reason: String? = nil, cause: Error? = nil) -> InvalidAmount
    public static func invalidInput(field: String, reason: String, cause: Error? = nil) -> InvalidInput
}
```

### SmartAccountStorageException

```swift
public class SmartAccountStorageException: SmartAccountException {
    public final class ReadFailed: SmartAccountStorageException { ... }
    public final class WriteFailed: SmartAccountStorageException { ... }

    public static func readFailed(key: String, cause: Error? = nil) -> ReadFailed
    public static func writeFailed(key: String, cause: Error? = nil) -> WriteFailed
}
```

### SmartAccountSessionException

```swift
public class SmartAccountSessionException: SmartAccountException {
    public final class Expired: SmartAccountSessionException { ... }
    public final class Invalid: SmartAccountSessionException { ... }

    public static func expired(sessionId: String? = nil, cause: Error? = nil) -> Expired
    public static func invalid(reason: String, cause: Error? = nil) -> Invalid
}
```

### SmartAccountIndexerException

```swift
public class SmartAccountIndexerException: SmartAccountException {
    public final class RequestFailed: SmartAccountIndexerException { ... }
    public final class Timeout: SmartAccountIndexerException { ... }

    public static func requestFailed(reason: String, cause: Error? = nil) -> RequestFailed
    public static func timeout(url: String, cause: Error? = nil) -> Timeout
}
```

### OZContractErrorCodes

```swift
public enum OZContractErrorCodes {
    public static func decode(_ code: Int) -> OZContractError?
    public static func decodeFromMessage(_ message: String?) -> OZContractError?
}
```

Namespace exposing the on-chain error codes of the OpenZeppelin smart-account, WebAuthn verifier, and policy contracts. These integers appear as `Error(Contract, #NNNN)` inside `SmartAccountTransactionException.SimulationFailed` / `SubmissionFailed` messages when a contract refuses an operation; the SDK surfaces the raw error message but does not parse or map contract error codes itself — `decode(_:)` and `decodeFromMessage(_:)` are consumer-side helpers.

Named constants cover the smart-account contract's own error enum (`SmartAccountError`, codes `3000` and `3002`-`3016`; `3001` is unused):

| Code | Name |
|---|---|
| 3000 | `contextRuleNotFound` |
| 3002 | `unvalidatedContext` |
| 3003 | `externalVerificationFailed` |
| 3004 | `noSignersAndPolicies` |
| 3005 | `pastValidUntil` |
| 3006 | `signerNotFound` |
| 3007 | `duplicateSigner` |
| 3008 | `policyNotFound` |
| 3009 | `duplicatePolicy` |
| 3010 | `tooManySigners` |
| 3011 | `tooManyPolicies` |
| 3012 | `mathOverflow` |
| 3013 | `keyDataTooLarge` |
| 3014 | `contextRuleIdsLengthMismatch` |
| 3015 | `nameTooLong` |
| 3016 | `unauthorizedSigner` |

`decode(_:)` resolves any known code — the constants above plus the WebAuthn verifier's `WebAuthnError` (`3110`-`3119`) and the built-in policy contracts' `SimpleThresholdError` (`3200`-`3203`), `WeightedThresholdError` (`3210`-`3214`), and `SpendingLimitError` (`3220`-`3227`) — into an `OZContractError`, or returns `nil` for unknown codes.

`decodeFromMessage(_:)` scans an error message for `Error(Contract, #NNNN)` markers (whitespace-tolerant) and returns the first marker whose code is known, or `nil` when the message is `nil`, carries no marker, or carries only unknown codes.

#### OZContractError

```swift
public struct OZContractError: Equatable, Hashable, Sendable {
    public let code: Int
    public let contract: String
    public let name: String

    public init(code: Int, contract: String, name: String)
}
```

A decoded contract error: the numeric `code`, the contract error enum it belongs to (`contract`, for example `SmartAccountError`), and the variant `name` (for example `UnauthorizedSigner`), exactly as declared by the deployed contracts. Variant names repeat across the policy enums (for example `NotAllowed`), so `contract` disambiguates; `code` is globally unique.

---

## Constants

### SmartAccountConstants

```swift
public enum SmartAccountConstants {
    public static let ed25519PublicKeySize: Int = 32
    public static let ed25519SecretSeedSize: Int = 32
    public static let ed25519SignatureSize: Int = 64
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
    public static let friendbotReserveXlm: Int = 5
    public static let defaultTimeoutSeconds: Int = 30
    public static let maxSigners: Int = 15
    public static let maxPolicies: Int = 5
    public static let maxNameSize: Int = 20
    public static let maxExternalKeySize: Int = 256
    public static let clientNameHeader: String = "X-Client-Name"
    public static let clientVersionHeader: String = "X-Client-Version"
    public static let clientName: String = "ios-stellar-sdk"
    public static let maxIndexerResponseBytes: Int = 1 * 1024 * 1024
    public static let maxRelayerResponseBytes: Int = 256 * 1024
}
```

Timeouts and budgets used by the kit and the HTTP clients. `maxSigners`, `maxPolicies`, `maxNameSize` (context-rule name, UTF-8 bytes), and `maxExternalKeySize` (external signer key data, bytes) are the contract limits enforced at validation time inside `OZContextRuleManager.addContextRule(...)` / `updateName(...)` and the `OZSignerManager` signer-addition paths. `friendbotReserveXlm` is the protocol minimum-balance reserve retained on the funded temporary account during `OZTransactionOperations.fundWallet(...)`. The HTTP identification headers are pinned at the `URLSession` configuration layer by both `OZIndexerClient` and `OZRelayerClient`.

Stroop and ledger conversions live on the core SDK `StellarProtocolConstants` — for example `StellarProtocolConstants.stroopsPerXlm` (10,000,000), `.ledgersPerHour` (720), and `.ledgersPerDay` (17,280) — and are the defaults behind `signatureExpirationLedgers` and the spending-limit period conversions.

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
        allowCredentials: [WebAuthnAllowCredential]?
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

### WebAuthnAllowCredential

```swift
public struct WebAuthnAllowCredential: Equatable, Hashable, Sendable {
    public let id: Data
    public let transports: [String]?

    public static func fromId(_ id: Data) -> WebAuthnAllowCredential
    public static func fromIds(_ ids: [Data]) -> [WebAuthnAllowCredential]
}
```

Credential descriptor passed to `WebAuthnProvider.authenticate(challenge:allowCredentials:)` to restrict the authenticator picker. Transport hints (`"internal"`, `"hybrid"`, `"usb"`, `"ble"`, `"nfc"`) are advisory.

### AppleWebAuthnProvider

```swift
@available(iOS 16.0, macOS 13.0, *)
public final class AppleWebAuthnProvider: NSObject, WebAuthnProvider, @unchecked Sendable {
    public static let defaultTimeoutMs: Int64 = 60_000

    public let rpId: String
    public let rpName: String
    public let timeout: Int64
    public var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?

    public init(
        rpId: String,
        rpName: String,
        timeout: Int64 = AppleWebAuthnProvider.defaultTimeoutMs
    ) throws

    public static func create(
        rpId: String,
        rpName: String,
        timeout: Int64 = AppleWebAuthnProvider.defaultTimeoutMs
    ) throws -> AppleWebAuthnProvider
}
```

The bundled `WebAuthnProvider` implementation built on `ASAuthorizationPlatformPublicKeyCredentialProvider`. Available on iOS 16+ and macOS 13+.

`rpId` must match an `Associated Domains` entitlement entry (`webcredentials:<rpId>`) in the host application and the relying-party domain must serve a matching `.well-known/apple-app-site-association` document. See `webauthn-ios.md` / `webauthn-macos.md` for the host-side setup steps.

`presentationContextProvider` must be set before any `register` / `authenticate` call on macOS — without it the system fails the request with `ASAuthorizationError` code 1004. On iOS the system handles presentation automatically and the property may remain `nil`.

The provider enforces `userVerificationPreference = .required` on assertion so the on-chain WebAuthn verifier accepts the signature (the verifier contract checks the UV bit and rejects assertions with `UV=false`).

`init` and `create(...)` perform identical validation: both throw `SmartAccountConfigurationException.InvalidConfig` for blank `rpId`/`rpName` or non-positive `timeout`.

---

## Storage Adapter

### OZStorageAdapter (protocol)

```swift
public protocol OZStorageAdapter: AnyObject, Sendable {
    func save(credential: OZStoredCredential) async throws
    func get(credentialId: String) async throws -> OZStoredCredential?
    func getByContract(contractId: String) async throws -> [OZStoredCredential]
    func getAll() async throws -> [OZStoredCredential]
    func delete(credentialId: String) async throws
    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws
    func clear() async throws
    func saveSession(_ session: OZStoredSession) async throws
    func getSession() async throws -> OZStoredSession?
    func clearSession() async throws
}
```

Required behavior: thread-safe; `update` throws `SmartAccountCredentialException.NotFound` when the credential does not exist; `getSession()` must return `nil` (and best-effort delete) for expired sessions.

### OZInMemoryStorageAdapter

```swift
public final actor OZInMemoryStorageAdapter: OZStorageAdapter {
    public init()
}
```

Non-persistent in-memory adapter used as the default when no storage is supplied via `OZSmartAccountConfig`. The header docstring explicitly warns that this adapter is not persistent and not secure; suitable for tests and ephemeral demos only.

### OZKeychainStorageAdapter

```swift
@available(iOS 13.0, macOS 10.15, *)
public final actor OZKeychainStorageAdapter: OZStorageAdapter {
    public static let defaultServiceName: String = "com.soneso.stellar.smartaccount"

    public init(serviceName: String = OZKeychainStorageAdapter.defaultServiceName)
}
```

Apple Keychain Services adapter with `kSecAttrAccessibleAfterFirstUnlock`. Pass a custom `serviceName` to scope storage to a specific application or feature.

iOS Simulator and unsigned macOS test binaries need a `keychain-access-groups` entitlement to access Keychain. Stored credentials contain only public-key material and metadata, so the adapter does not apply biometric `SecAccessControl` flags.

### OZUserDefaultsStorageAdapter

```swift
public final actor OZUserDefaultsStorageAdapter: OZStorageAdapter {
    public static let defaultSuiteName: String = "com.soneso.stellar.smartaccount"

    public init(
        suiteName: String = OZUserDefaultsStorageAdapter.defaultSuiteName
    ) throws
}
```

Scoped `UserDefaults` adapter. Throws if the supplied suite name cannot be resolved to a `UserDefaults` instance. The header docstring notes that `UserDefaults` writes plaintext property-list values to the app container and is therefore not encrypted at rest; apps storing sensitive data should prefer the Keychain adapter.

### OZExternalWalletAdapter (protocol)

```swift
public protocol OZExternalWalletAdapter: AnyObject, Sendable {
    func connect() async throws -> OZConnectedWallet?
    func disconnect() async throws
    func disconnectByAddress(address: String) async throws
    func signAuthEntry(
        preimageXdr: String,
        options: OZSignAuthEntryOptions?
    ) async throws -> OZSignAuthEntryResult
    func getConnectedWallets() -> [OZConnectedWallet]
    func canSignFor(address: String) -> Bool
    func getWalletForAddress(address: String) -> OZConnectedWallet?
}
```

Default protocol extension provides no-op implementations for `disconnectByAddress(address:)` and `getWalletForAddress(address:)`.

The `signAuthEntry(preimageXdr:options:)` contract: the adapter receives the base64-encoded `HashIDPreimage` XDR, must base64-decode it, compute its SHA-256, sign with Ed25519, and return an `OZSignAuthEntryResult` carrying the base64-encoded 64-byte signature. The preimage envelope type follows the auth entry's credential arm (`SorobanAuthorization` for legacy `ADDRESS` entries; `SorobanAuthorizationWithAddress` for protocol-27 `ADDRESS_V2` entries); adapters that hash-and-sign the raw bytes need no arm-specific handling.

---

## Indexer Client

The SDK includes an indexer client for reverse lookups from signer credentials to smart account contracts. The indexer is auto-configured for testnet and mainnet when no explicit URL is provided. The kit owns the client and tears it down on `close()`.

### Using via OZSmartAccountKit (Recommended)

`kit.indexerClient` is `nil` when no indexer URL is configured (no explicit URL and no built-in default for the network). Prefer this accessor over constructing a client directly; the kit constructs, configures, and closes it for you.

```swift
let kit = try await OZSmartAccountKit.create(config: config)

// Discover contracts by credential ID
let contracts = try await kit.indexerClient?.lookupByCredentialId(credentialId: credentialId)

// Discover contracts by signer address
let byAddress = try await kit.indexerClient?.lookupByAddress(address: "GABC...")

// Get full contract details (rules, signers, policies)
let details = try await kit.indexerClient?.getContract(contractId: "CABC...")

// Health and stats
let healthy = await kit.indexerClient?.isHealthy()
let stats = try await kit.indexerClient?.getStats()
```

### Using OZIndexerClient Directly

```swift
// Create a client for a specific network (uses the default indexer URL)
let indexer = OZIndexerClient.forNetwork(networkPassphrase: Network.testnet.passphrase)

// Or with a custom URL
let indexer = try OZIndexerClient(
    indexerUrl: "https://testnet.mercurydata.app/rest/smart-account-indexer",
    timeoutMs: 10000
)
```

HTTP client for the smart-account indexer service. The class is `public` (not `open`), so consumer code customizes transport by injecting a custom `urlSession` rather than subclassing; the SDK's own in-module test doubles subclass it and override `close()` to call `super.close()` (or `performCloseInternal()`) so the owned `URLSession` is invalidated. When the client owns the `URLSession`, it builds an ephemeral session whose redirect handler denies all 3xx redirects to protect signed payloads and pinned identification headers (`X-Client-Name`, `X-Client-Version`).

### Constructor

```swift
public init(
    indexerUrl: String,
    timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
    urlSession: URLSession? = nil
) throws
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `indexerUrl` | `String` | Indexer service URL. Must start with `https://`, or `http://localhost` for development. |
| `timeoutMs` | `Int64` | Request timeout in milliseconds (default: `OZConstants.defaultIndexerTimeoutMs`, 10 seconds). |
| `urlSession` | `URLSession?` | Optional injected session for testing or custom transport configuration. When `nil`, the client owns a freshly created session and invalidates it on `close()`. |

**Throws**: `SmartAccountConfigurationException.invalidConfig` if `indexerUrl` is blank, not HTTPS/localhost, or has no host.

### Factory Methods

```swift
public static let defaultIndexerUrls: [String: String]
```

Built-in default indexer URLs keyed by network passphrase:
- Testnet — `https://testnet.mercurydata.app/rest/smart-account-indexer`
- Mainnet — `https://mainnet.mercurydata.app/rest/smart-account-indexer`

#### forNetwork

```swift
public static func forNetwork(
    networkPassphrase: String,
    timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
    urlSession: URLSession? = nil
) -> OZIndexerClient?
```

Creates an `OZIndexerClient` using the default indexer URL for a known network. Returns `nil` if no default URL is configured for the network.

#### getDefaultUrl

```swift
public static func getDefaultUrl(networkPassphrase: String) -> String?
```

Returns the default indexer URL for a given network passphrase, or `nil` if unknown.

### Methods

#### lookupByCredentialId

```swift
public func lookupByCredentialId(credentialId: String) async throws -> OZCredentialLookupResponse
```

Finds all smart account contracts where the given credential is registered as a signer. The credential ID must be Base64URL-encoded (RFC 4648, no padding); the SDK converts it to hex internally before calling the indexer API.

**Returns**: `OZCredentialLookupResponse`

**Throws**: `SmartAccountValidationException.invalidInput` if the credential ID is not valid base64url. `SmartAccountIndexerException.requestFailed` on network, non-2xx, or decoding errors. `SmartAccountIndexerException.timeout` on per-request timeout.

---

#### lookupByAddress

```swift
public func lookupByAddress(address: String) async throws -> OZAddressLookupResponse
```

Finds all smart account contracts where the given address is registered as a signer. Accepts both `G…` (Stellar accounts) and `C…` (contracts) addresses.

**Returns**: `OZAddressLookupResponse`

**Throws**: `SmartAccountValidationException.invalidAddress` if the address format is invalid. `SmartAccountIndexerException.requestFailed` / `SmartAccountIndexerException.timeout` on transport failure.

---

#### getContract

```swift
public func getContract(contractId: String) async throws -> OZContractDetailsResponse
```

Retrieves full details for a smart account contract including all context rules, signers, and policies.

**Returns**: `OZContractDetailsResponse`

**Throws**: `SmartAccountValidationException.invalidAddress` if the contract ID format is invalid. `SmartAccountIndexerException.requestFailed` / `SmartAccountIndexerException.timeout` on transport failure.

---

#### getStats

```swift
public func getStats() async throws -> OZIndexerStatsResponse
```

Returns indexer service statistics (total events, unique contracts, unique credentials, ledger range, event-type breakdown).

**Returns**: `OZIndexerStatsResponse`

**Throws**: `SmartAccountIndexerException.requestFailed` / `SmartAccountIndexerException.timeout` on transport failure.

---

#### isHealthy

```swift
public func isHealthy() async -> Bool
```

Returns `true` only when the server responds with HTTP 2xx, a `Content-Type` of `application/json`, a body within `OZConstants.maxIndexerResponseBytes`, and a decoded `OZIndexerHealthCheckResponse` whose `status` is `"ok"`. Does not throw — returns `false` for any error condition.

---

#### close

```swift
public func close()
```

Invalidates the owned `URLSession` (when not injected) and marks the client closed. The client must not be used after calling this. When using via `kit.indexerClient`, the kit's `close()` handles this automatically. Subclasses overriding `close()` must call `super.close()` or `performCloseInternal()`.

---

### Response Types

All response types are `Decodable`, `Equatable`, and `Sendable`.

#### OZCredentialLookupResponse

```swift
public struct OZCredentialLookupResponse {
    public let credentialId: String
    public let contracts: [OZIndexedContractSummary]
    public let count: Int
}
```

Contracts where a given credential is registered as a signer.

#### OZAddressLookupResponse

```swift
public struct OZAddressLookupResponse {
    public let signerAddress: String
    public let contracts: [OZIndexedContractSummary]
    public let count: Int
}
```

Contracts where a given address is registered as a signer.

#### OZContractDetailsResponse

```swift
public struct OZContractDetailsResponse {
    public let contractId: String
    public let summary: OZIndexedContractSummary
    public let contextRules: [OZIndexedContextRule]
}
```

Full details for a single smart account contract.

#### OZIndexedContractSummary

```swift
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
```

Aggregate counts and ledger metadata for an indexed contract.

#### OZIndexedContextRule

```swift
public struct OZIndexedContextRule {
    public let contextRuleId: Int
    public let signers: [OZIndexedSigner]
    public let policies: [OZIndexedPolicy]
}
```

A context rule with its signers and policies.

#### OZIndexedSigner

```swift
public struct OZIndexedSigner {
    public let signerType: String      // "External", "Delegated", or "Native"
    public let signerAddress: String?  // G-/C-address (Delegated signers)
    public let credentialId: String?   // Hex-encoded credential ID (External signers)
}
```

A signer within a context rule. External signers carry `credentialId`; Delegated signers carry `signerAddress`; Native signers carry neither.

#### OZIndexedPolicy

```swift
public struct OZIndexedPolicy {
    public let policyAddress: String
    public let installParams: [String: OZJSONValue]?  // Policy-specific parameters
}
```

A policy attached to a context rule. `installParams` preserves the arbitrary JSON structure attached by the policy contract.

#### OZIndexerStatsResponse

```swift
public struct OZIndexerStatsResponse {
    public let stats: OZIndexerStats
}

public struct OZIndexerStats {
    public let totalEvents: Int64
    public let uniqueContracts: Int64
    public let uniqueCredentials: Int64
    public let firstLedger: Int64
    public let lastLedger: Int64
    public let eventTypes: [OZEventTypeCount]
}

public struct OZEventTypeCount {
    public let eventType: String
    public let count: Int64
}
```

Aggregate indexer statistics with a per-event-type breakdown.

#### OZIndexerHealthCheckResponse

```swift
public struct OZIndexerHealthCheckResponse {
    public let status: String
}
```

Response from the indexer health endpoint. `isHealthy()` compares `status` against `"ok"`.

#### OZJSONValue

```swift
public enum OZJSONValue {
    case string(String)
    case integer(Int64)
    case double(Double)
    case bool(Bool)
    case array([OZJSONValue])
    case object([String: OZJSONValue])
    case null
}
```

Generic JSON value used to preserve arbitrary structures inside policy install parameters (and the relayer response `details` field). `Decodable`, `Equatable`, `Hashable`, and `Sendable`.

---

## Relayer Client

The SDK includes a relayer client for fee-sponsored transaction submission. When configured, the SDK automatically routes transactions through the relayer so users don't need XLM to pay fees. The kit owns the client and tears it down on `close()`.

### Using via OZSmartAccountKit (Recommended)

When the relayer is configured, all transaction submissions use it automatically. `kit.relayerClient` is `nil` when no relayer URL is configured.

```swift
let config = OZSmartAccountConfig(
    // ... other config
    relayerUrl: "https://my-relayer-proxy.example.com"
)
let kit = try await OZSmartAccountKit.create(config: config)

// Transactions automatically use the relayer
try await kit.transactionOperations.transfer(tokenContract: tokenContract, to: recipient, amount: "10")

// Access the relayer client directly
let response = await kit.relayerClient?.sendXdr(transactionEnvelope: envelope)
```

### Constructor

```swift
public init(
    relayerUrl: String,
    timeoutMs: Int64 = OZConstants.defaultRelayerTimeoutMs,
    urlSession: URLSession? = nil
) throws
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `relayerUrl` | `String` | Relayer endpoint URL. Must start with `https://`, or `http://localhost` for development. |
| `timeoutMs` | `Int64` | Default request timeout in milliseconds (default: `OZConstants.defaultRelayerTimeoutMs`, 6 minutes to accommodate testnet submission retries). |
| `urlSession` | `URLSession?` | Optional injected session for testing or custom transport configuration. When `nil`, the client owns a freshly created session and invalidates it on `close()`. |

**Throws**: `SmartAccountConfigurationException.invalidConfig` if `relayerUrl` is blank, not HTTPS/localhost, or has no host.

`OZRelayerClient` is `public` (not `open`); like `OZIndexerClient`, consumer code injects a custom transport rather than subclassing, and the SDK's in-module test doubles subclass it overriding `close()` (calling `super.close()` or `performCloseInternal()` to invalidate the owned `URLSession`). When the client owns the `URLSession`, it builds an ephemeral session whose redirect handler denies all 3xx redirects to protect signed `SorobanAuthorizationEntryXDR` / `TransactionEnvelopeXDR` payloads and pinned identification headers.

Whether a relayer is in use is determined by `kit.relayerClient` being non-`nil`, which the kit sets from the configured `relayerUrl`. A directly constructed `OZRelayerClient` is always configured, since `init` rejects invalid URLs.

### Methods

#### send

```swift
public func send(
    hostFunction: HostFunctionXDR,
    authEntries: [SorobanAuthorizationEntryXDR],
    perRequestTimeoutMs: Int64? = nil
) async -> OZRelayerResponse
```

Submits a host function with signed authorization entries for fee sponsoring. The relayer assembles the transaction and wraps it in a fee bump using its own channel account. Used when every signed auth entry uses `Address` credentials. XDR encoding to base64 is handled internally.

This method does not throw. All error conditions — network errors, timeouts, XDR encoding failures, non-2xx responses — are returned in the `OZRelayerResponse`. Always inspect `response.success`.

**Parameters**:
- `hostFunction`: Host function XDR to execute
- `authEntries`: Signed authorization entries
- `perRequestTimeoutMs`: Optional per-request timeout override in milliseconds

**Returns**: `OZRelayerResponse`

---

#### sendXdr

```swift
public func sendXdr(
    transactionEnvelope: TransactionEnvelopeXDR,
    perRequestTimeoutMs: Int64? = nil
) async -> OZRelayerResponse
```

Submits a pre-signed transaction envelope for fee-bumping. Used when the transaction requires source-account authentication (for example smart-account contract deployments); the relayer fee-bumps the signed envelope, preserving the inner signatures. XDR encoding to base64 is handled internally.

This method does not throw. All error conditions are returned in the `OZRelayerResponse`. Always inspect `response.success`.

**Parameters**:
- `transactionEnvelope`: Signed transaction envelope XDR
- `perRequestTimeoutMs`: Optional per-request timeout override in milliseconds

**Returns**: `OZRelayerResponse`

---

#### close

```swift
public func close()
```

Invalidates the owned `URLSession` (when not injected) and marks the client closed. The client must not be used afterwards. When using via `kit.relayerClient`, the kit's `close()` handles this automatically. Subclasses overriding `close()` must call `super.close()` or `performCloseInternal()`.

---

### Response and Error Types

#### OZRelayerResponse

```swift
public struct OZRelayerResponse {
    public let success: Bool
    public let transactionId: String?
    public let hash: String?
    public let status: String?
    public let error: String?
    public let errorCode: String?
    public let details: [String: OZJSONValue]?
}
```

| Property | Type | Description |
|----------|------|-------------|
| `success` | `Bool` | Whether the relayer accepted and successfully submitted the transaction. |
| `transactionId` | `String?` | Relayer-assigned identifier when submission succeeded. |
| `hash` | `String?` | Stellar transaction hash returned by the relayer when available. |
| `status` | `String?` | Transaction status string (e.g. `"PENDING"`, `"SUCCESS"`, `"ERROR"`). |
| `error` | `String?` | Human-readable error message when the request failed. |
| `errorCode` | `String?` | Machine-readable error code; one of the `OZRelayerErrorCodes` constants when populated. |
| `details` | `[String: OZJSONValue]?` | Additional details forwarded from the relayer body's `data` field; non-object payloads are wrapped under the key `"value"`. `nil` when omitted. |

`Decodable`, `Equatable`, `Hashable`, and `Sendable`. Decodes both the wrapped (`{"success": ..., "data": {...}}`) and flat envelopes returned by the relayer.

#### OZRelayerErrorCodes

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
```

A namespace of the relayer service's error-code identifiers. The string value of each constant equals its name, so it can be compared directly against the `errorCode` field of an `OZRelayerResponse`.

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
- `buildAuthPayloadHash(entry:expirationLedger:networkPassphrase:)` — computes the auth-payload hash that must be signed to authorize an entry with address credentials. The preimage envelope type follows the entry's credential arm: `HashIDPreimage::SorobanAuthorization` for the legacy `ADDRESS` arm; `HashIDPreimage::SorobanAuthorizationWithAddress` (protocol 27) for the `ADDRESS_V2` and `ADDRESS_WITH_DELEGATES` arms.
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
    public static func createDefaultContextType() -> OZContextRuleType
    public static func createCallContractContextType(contractAddress: String) throws -> OZContextRuleType
    public static func createCreateContractContextType(wasmHashHex: String) throws -> OZContextRuleType
    public static func createCreateContractContextType(wasmHash: Data) throws -> OZContextRuleType

    public static func collectUniqueSignersFromRules(
        rules: [OZParsedContextRule]
    ) -> [any OZSmartAccountSigner]
}
```

Type-safe constructors for `OZContextRuleType` plus a deduplication helper across parsed context rules.

- `createDefaultContextType()` — returns `OZContextRuleType.defaultRule`.
- `createCallContractContextType(contractAddress:)` — validates the supplied contract address (throws `SmartAccountValidationException.InvalidAddress` for malformed values) and returns `OZContextRuleType.callContract(contractAddress:)`.
- `createCreateContractContextType(wasmHashHex:)` — validates a 64-character hex WASM hash (an optional `0x` prefix is accepted and stripped) and returns `OZContextRuleType.createContract(wasmHash:)`. Throws `SmartAccountValidationException.InvalidInput` for malformed input.
- `createCreateContractContextType(wasmHash:)` — validates a 32-byte WASM hash and returns the matching enum case.
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
}
```

A `public enum` namespace of type-safe constructors and helpers for signers and signer inspection. Signer builders forward to the corresponding `OZDelegatedSigner` / `OZExternalSigner` initializers and factories. The inspection helpers detect WebAuthn signers by their `keyData` shape (greater than 65 bytes — a 65-byte uncompressed public key followed by the credential id).

To install policies on a context rule, use `OZPolicyInstallParams` with `OZPolicyManager.addSimpleThreshold(...)`, `addWeightedThreshold(...)`, `addSpendingLimit(...)`, or `addPolicy(installParams:)`. The weighted-threshold path takes `OZSignerWeightEntry` values.

---

## Utilities

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

A signer authorized through a Soroban address using the host's `require_auth` mechanism. `address` may be a `G…` Stellar account or a `C…` contract strkey. The initializer throws `SmartAccountValidationException.InvalidAddress` for any other shape.

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

Construction-time validation may throw `SmartAccountValidationException.InvalidInput`. `toScVal()` is non-throwing for all three variants. `toAuthPayloadBytes()` is non-throwing for Ed25519 (returns the raw 64-byte signature); WebAuthn and Policy XDR-encode the `toScVal()` result and throw `SmartAccountTransactionException.SigningFailed` on encoding failure.

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
- **`OZSelectedSigner.passkey(...)` `keyData` requirement**: in multi-signer ceremonies every passkey `OZSelectedSigner` entry must supply `keyData` non-nil. The auth pipeline validates this upfront in `validateSignerSet` and throws `SmartAccountValidationException.InvalidInput` (field `"selectedSigners"`) when `keyData` is absent.
- **`autoFund: true` is testnet-only**: `fundWallet` calls the hardcoded Friendbot URL at `https://friendbot.stellar.org`. On mainnet, fund the deployer externally and omit `autoFund`.
- **`webauthnProvider` requirement scope**: a `webauthnProvider` is required for `createWallet`, `connectWallet` with `prompt: true`, `authenticatePasskey`, and any passkey-signing flow. A `connectWallet()` call that finds a live unexpired session does NOT need `webauthnProvider`.
- **C-address base32 alphabet**: C-strkeys use the RFC 4648 base32 alphabet (`A-Z` + `2-7`). The digits `0`, `1`, `8`, and `9` are not legal. Hand-constructed or modified C-address strings that include those digits are silently rejected by `isValidContractId()` and by `OZSmartAccountConfig.init`, surfacing as `SmartAccountConfigurationException.InvalidConfig`.

---

## Error Handling Example

Catch the specific arms you care about first, then fall back to the base type. Arm subclasses are nested (`WebAuthnException.Cancelled`, `SmartAccountTransactionException.SimulationFailed`); the base `SmartAccountException` catches everything else.

```swift
do {
    let result = try await kit.transactionOperations.transfer(
        tokenContract: tokenContract,
        recipient: recipient,
        amount: "10"
    )
    print("hash: \(result.hash ?? "n/a")")
} catch let error as WebAuthnException.Cancelled {
    // User dismissed the passkey prompt.
    print("Cancelled by user")
} catch let error as WebAuthnException.NotSupported {
    // No WebAuthn provider configured, or the platform cannot run the ceremony.
    print("WebAuthn unavailable: \(error.message)")
} catch let error as SmartAccountTransactionException.SimulationFailed {
    // Simulation rejected the call (e.g. an on-chain contract error code in the message).
    print("Simulation failed: \(error.message)")
} catch let error as SmartAccountException {
    // Any other kit error, mapped to a stable numeric code.
    print("Smart account error \(error.code.code): \(error.message)")
}
```
