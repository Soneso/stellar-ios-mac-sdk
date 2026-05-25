# Smart Account Kit

The Smart Account Kit lets iOS and macOS applications create and operate passkey-authenticated smart accounts on Stellar using the OpenZeppelin Soroban smart account contracts. Users authenticate with biometrics (Face ID, Touch ID, or a hardware security key) instead of managing Ed25519 secret keys, and the kit handles wallet creation, contract deployment, transaction signing, signer management, policy enforcement, optional fee sponsoring, and credential persistence.

New to smart accounts? Start with the [Developer Onboarding](onboarding.md) guide for background on how smart accounts, passkeys, and the on-chain contracts work.

## Overview

A smart account is a Soroban contract that replaces traditional key-based authorization with programmable on-chain rules. Each smart account supports:

- **Passkey authentication** via WebAuthn (secp256r1) for biometric sign-in on Apple platforms.
- **Multiple signer types** on a single account: WebAuthn passkeys, Ed25519 keys, and delegated Stellar addresses (G- or C-strkeys).
- **Context rules** that bind sets of signers and policies to specific operation types (default, call-contract, create-contract).
- **Policies** that enforce constraints on-chain, including M-of-N thresholds, weighted thresholds, and per-period spending limits. Custom policy contracts are also supported.
- **Optional fee sponsoring** through a relayer so end users never pay XLM fees.
- **Optional credential indexing** for cross-device wallet discovery.
- **Session-based reconnection** without re-prompting for biometrics, configurable up to seven days by default.

## Architecture

The kit is split into two layers. The `core/` layer defines protocol-agnostic primitives that any Soroban `CustomAccountInterface` contract could use: signer types, signature wrappers, WebAuthn data structures, the `WebAuthnProvider` protocol, error hierarchy, and the cryptographic helpers in `SmartAccountUtils`. The `oz/` layer contains code specific to the OpenZeppelin smart account contracts: the kit, all managers, the relayer and indexer HTTP clients, the OZ authorization payload codec, the WebAuthn signature XDR shape, policy install parameters, and the platform storage adapters.

```
+-----------------------------------------------------------------------+
|                         Your Application                              |
+-----------------------------------------------------------------------+
        |
        v
+-----------------------------------------------------------------------+
|                       OZSmartAccountKit                               |
|  Entry point. Created via OZSmartAccountKit.create(config:).          |
|  Exposes managers as properties; all state-changing methods are       |
|  async throws.                                                        |
|                                                                       |
|  +-----------------------+  +----------------------------+            |
|  | walletOperations      |  | transactionOperations      |            |
|  | (OZWalletOperations)  |  | (OZTransactionOperations)  |            |
|  +-----------------------+  +----------------------------+            |
|  +-----------------------+  +----------------------------+            |
|  | signerManager         |  | contextRuleManager         |            |
|  | (OZSignerManager)     |  | (OZContextRuleManager)     |            |
|  +-----------------------+  +----------------------------+            |
|  +-----------------------+  +----------------------------+            |
|  | policyManager         |  | multiSignerManager         |            |
|  | (OZPolicyManager)     |  | (OZMultiSignerManager)     |            |
|  +-----------------------+  +----------------------------+            |
|  +-----------------------+  +----------------------------+            |
|  | credentialManager     |  | events                     |            |
|  | (OZCredentialManager) |  | (SmartAccountEventEmitter) |            |
|  +-----------------------+  +----------------------------+            |
+-----------------------------------------------------------------------+
        |                    |                      |
        v                    v                      v
+------------------+  +------------------+  +-----------------------+
| WebAuthnProvider |  | StorageAdapter   |  | ExternalWalletAdapter |
| (e.g. Apple-     |  | (Keychain,       |  | (optional)            |
|  WebAuthnProvider)|  |  UserDefaults,   |  +-----------------------+
+------------------+  |  InMemory)       |
                      +------------------+

The kit also owns its network transports:

+----------------+  +------------------+  +---------------------+
| SorobanServer  |  | OZRelayerClient  |  | OZIndexerClient     |
| (Soroban RPC)  |  | (fee sponsoring) |  | (credential lookup) |
+----------------+  +------------------+  +---------------------+
```

Concrete-typed accessors for `contextRuleManager` and `credentialManager` are also exposed as `contextRuleManagerConcrete` and `credentialManagerConcrete`, which is what you reach for when calling the manager directly without going through the kit's protocol-typed property.

`OZSmartAccountKit` is the single entry point. It holds the immutable configuration, the connection state (`isConnected`, `credentialId`, `contractId`), the shared `SorobanServer`, and the optional relayer and indexer clients.

Each sub-manager receives a reference to the kit and uses its Soroban server, relayer, and storage internally. `OZExternalSignerManager` is intentionally not built by the kit; consumers construct it directly when they need external-wallet signing.

The kit and its managers are safe to share across `async` contexts. Storage adapters are `public actor` types, so their methods are implicitly async from outside the actor.

## Quick Start

The kit ships in the `stellar-ios-mac-sdk` Swift package. Add it as a Swift Package Manager dependency:

```swift
// In Package.swift
.package(url: "https://github.com/Soneso/stellar-ios-mac-sdk.git", from: "3.1.0")
```

or add the package directly in Xcode through File -> Add Package Dependencies and use the same URL. The platform target must be iOS 16+ or macOS 13+ to use the bundled `AppleWebAuthnProvider`.

### Configure and create the kit

The four required fields come from the OpenZeppelin smart account deployment on the target network: the Soroban RPC endpoint, the network passphrase, the SHA-256 hash of the uploaded smart account WASM (64-character hex), and the C-strkey of the deployed WebAuthn signature verifier contract.

```swift
import stellarsdk

let provider = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "Example Wallet"
)

let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "<64-char hex WASM hash>",
    webauthnVerifierAddress: "<C-strkey of WebAuthn verifier>",
    rpId: "wallet.example.com",
    rpName: "Example Wallet",
    relayerUrl: "https://relayer.example.com",   // optional
    indexerUrl: nil,                              // optional; default per-network URL is used
    webauthnProvider: provider,
    storage: KeychainStorageAdapter()             // recommended for production
)

let kit = OZSmartAccountKit.create(config: config)
```

`OZSmartAccountConfig.init` and `OZSmartAccountConfig.builder(...).build()` both throw `ConfigurationException` for invalid input (non-hex WASM hash, non-C-strkey verifier, malformed RPC URL, etc.). `OZSmartAccountKit.create(config:)` is the only consumer-facing factory and performs no network I/O.

### Create a new wallet

`createWallet` triggers a WebAuthn registration ceremony (biometric prompt), derives the deterministic contract address from the new credential, persists the credential as `pending`, and builds the deploy transaction. With `autoSubmit: true`, the transaction is submitted through the relayer when configured, otherwise directly through Soroban RPC; with `autoFund: true` and a `nativeTokenContract` supplied, the wallet is then funded from Friendbot on testnet.

```swift
let result = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: true,
    autoFund: true,
    nativeTokenContract: "<C-strkey of native XLM SAC>"
)

// result.credentialId        -- Base64URL-encoded credential ID (no padding)
// result.contractId          -- C-strkey of the deployed smart account
// result.publicKey           -- 65-byte uncompressed secp256r1 public key
// result.signedTransactionXdr -- always populated; usable for external submission
// result.transactionHash     -- set when autoSubmit was true
```

Note: `autoFund` calls Friendbot, which is testnet-only. On mainnet, fund the deployer keypair externally.

### Transfer XLM (or any SEP-41 token)

`transfer` invokes the token contract's `transfer` function with the smart account as source, prompts the user to sign the authorization entry with their passkey, and submits the transaction. The returned `TransactionResult` carries `hash`, `success`, optional `error`, and the parsed return value.

```swift
let result = try await kit.transactionOperations.transfer(
    tokenContract: "<C-strkey of token contract>",
    recipient: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
    amount: "10"                                  // decimal; stroop conversion is automatic
)

if result.success {
    print("Transfer succeeded: \(result.hash ?? "")")
} else {
    print("Transfer failed: \(result.error ?? "unknown error")")
}
```

For arbitrary contract calls, use `contractCall(target:targetFn:targetArgs:...)`; to route a call through the smart account's `execute` entry point, use `executeAndSubmit(...)`. The `submit(hostFunction:auth:...)` method is the lowest-level escape hatch and exposes the full simulate-sign-resimulate-submit pipeline.

### Reconnect to an existing wallet

On app relaunch, call `connectWallet()` with default options. If a non-expired session exists in storage, the kit restores connection silently. If no session is present, the method returns `nil`, and the application shows a connect button that calls `connectWallet(options:)` with `prompt: true` to trigger a WebAuthn authentication.

```swift
// Step 1: silent session restore. No biometric prompt is shown.
if let connection = try await kit.walletOperations.connectWallet() {
    switch connection {
    case let .connected(credentialId, contractId, restoredFromSession):
        print("Connected to \(contractId), restored: \(restoredFromSession)")
    case let .ambiguous(credentialId, candidates):
        // Indexer reported multiple contracts for the same credential. Ask the
        // user to pick one and reconnect with the chosen contractId.
        // `showContractPicker` is your own picker UI (sheet, dialog, etc.) -- not provided by the SDK.
        let chosen = await showContractPicker(candidates)
        _ = try await kit.walletOperations.connectWallet(
            options: ConnectWalletOptions(credentialId: credentialId, contractId: chosen)
        )
    }
} else {
    // No saved session -- show a "Connect" button.
}

// Step 2: user taps Connect.
let connection = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(prompt: true)
)
```

Force fresh authentication for sensitive operations:

```swift
let connection = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(fresh: true)
)
```

Connect directly with known credentials (skips WebAuthn and session check; the cascade is bypassed so a successful result is always `.connected`):

```swift
let connection = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(
        credentialId: "<base64url credential id>",
        contractId: "<C-strkey>"
    )
)
```

### Retry a pending deployment

When `createWallet(autoSubmit: false)` is used, or when deployment failed after the credential was created, call `deployPendingCredential` to submit the deploy transaction later. The credential must exist in local storage; `CreateWalletResult.signedTransactionXdr` is also always populated, so it can be submitted out-of-band.

```swift
let pending = try await kit.walletOperations.deployPendingCredential(
    credentialId: createResult.credentialId,
    autoSubmit: true
)
print("Deployed \(pending.contractId), tx: \(String(describing: pending.transactionHash))")
```

### Add a signer

Add a delegated Stellar account as a signer on the default context rule (ID 0):

```swift
let txResult = try await kit.signerManager.addDelegated(
    contextRuleId: 0,
    address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
)
```

Add a fresh passkey signer in a single step (registration plus credential save plus on-chain addition):

```swift
let passkey = try await kit.signerManager.addNewPasskeySigner(
    contextRuleId: 0,
    userName: "Alice backup device"
)
// passkey.credentialId      -- Base64URL credential ID
// passkey.publicKey         -- 65-byte uncompressed secp256r1 public key
// passkey.transactionResult -- the on-chain TransactionResult
```

Add a pre-registered passkey with raw cryptographic material:

```swift
let lowLevel = try await kit.signerManager.addPasskey(
    contextRuleId: 0,
    publicKey: existingPublicKey,    // 65-byte uncompressed secp256r1
    credentialId: existingCredId     // raw bytes
)
```

Remove a signer by its on-chain signer ID:

```swift
let removed = try await kit.signerManager.removeSigner(
    contextRuleId: 0,
    signerId: 1
)
```

### Add a policy

Each context rule supports up to five policies. The built-in helpers cover the three OpenZeppelin policy contracts:

```swift
// 2-of-3 threshold
let threshold = try await kit.policyManager.addSimpleThreshold(
    contextRuleId: 0,
    policyAddress: "<C-strkey of simple-threshold policy>",
    threshold: 2
)

// 1,000 units per ~24 hours (17,280 ledgers at ~5 s each)
let limit = try await kit.policyManager.addSpendingLimit(
    contextRuleId: 0,
    policyAddress: "<C-strkey of spending-limit policy>",
    spendingLimit: "1000",
    periodLedgers: 17_280
)
```

Install a custom policy contract by passing the install parameters as an `SCValXDR`:

```swift
let installParams = SCValXDR.map([
    SCMapEntryXDR(
        key: SCValXDR.symbol("my_param"),
        val: SCValXDR.u32(42)
    )
])

let custom = try await kit.policyManager.addPolicy(
    contextRuleId: 0,
    policyAddress: "<C-strkey of custom policy>",
    installParams: installParams
)
```

### Multi-signer transfer

When a context rule requires more than one signature, use `kit.multiSignerManager`. The `selectedSigners` array names the signers that should authorize the call. Passkey entries trigger WebAuthn ceremonies; wallet entries delegate signing to the configured `ExternalWalletAdapter`.

For multi-signer ceremonies, every `SelectedSigner.passkey(...)` entry must carry the credential's stored `keyData` -- the auth pipeline reconstructs external signers once per call, not per entry.

```swift
let result = try await kit.multiSignerManager.multiSignerTransfer(
    tokenContract: "<C-strkey of token contract>",
    recipient: "GA7QYNF7...",
    amount: "10",
    selectedSigners: [
        .passkey(credentialId: passkeyA, credentialIdBytes: nil, keyData: existingKeyData, transports: nil),
        .wallet(accountId: "GBBBBB...")
    ]
)
```

For arbitrary contract calls with multiple signers, use `multiSignerContractCall(...)`. To route through the smart account's `execute` entry point, use `multiSignerExecuteAndSubmit(...)`.

### Error handling

All operations throw subclasses of `SmartAccountException`. Each subclass is a `public final class` produced by static factory methods; pattern-match on the concrete type rather than the base.

```swift
do {
    let wallet = try await kit.walletOperations.createWallet(userName: "Alice", autoSubmit: true)
} catch let error as WebAuthnException.Cancelled {
    print("User cancelled the biometric prompt")
} catch let error as WebAuthnException.NotSupported {
    print("WebAuthn not configured: \(error.message)")
} catch let error as TransactionException.SimulationFailed {
    print("Contract simulation failed: \(error.message)")
} catch let error as TransactionException.SubmissionFailed {
    print("Transaction submission failed: \(error.message)")
} catch let error as WalletException.NotFound {
    print("Wallet not found on-chain")
} catch let error as SmartAccountException {
    print("Error [\(error.code.rawValue)]: \(error.message)")
}
```

The full numeric code table is in `SmartAccountErrorCode` (1001-10002, grouped by domain).

### Observe events

`kit.events` is a `SmartAccountEventEmitter`. Listeners are added with `addListener(_:)`, `on(_:listener:)`, or `once(_:listener:)`, each returning a `SmartAccountEventUnsubscribe` closure for removal.

```swift
let unsubscribe = kit.events.addListener { event in
    switch event {
    case let .walletConnected(contractId, credentialId):
        print("Connected: \(contractId)")
    case let .transactionSubmitted(hash, success):
        print("Submitted \(hash) success=\(success)")
    default:
        break
    }
}

// Later:
unsubscribe()
```

Eight event arms are emitted: `.walletConnected`, `.walletDisconnected`, `.credentialCreated`, `.credentialDeleted`, `.sessionExpired`, `.transactionSigned`, `.transactionSubmitted`, and `.credentialSyncFailed`.

### Lifecycle

`kit.disconnect() async throws` clears the in-memory connection state, calls `storage.clearSession()`, and emits `walletDisconnected`. Credentials remain in storage and can be reused for the next `connectWallet` call.

`kit.close() async` is independent of `disconnect()`. It releases the owned RPC, indexer, and relayer transports, removes all event listeners, and nils the manager backing storage. It is idempotent. Accessing manager properties after `close()` traps; create a new kit if you need to reconnect after closing.

## Configuration Reference

`OZSmartAccountConfig` is a `public struct: @unchecked Sendable, Equatable, Hashable`. Construct it directly through its initializer or fluently with `OZSmartAccountConfig.builder(...)`.

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `rpcUrl` | `String` | Soroban RPC endpoint URL. Validated as `https://` or `http://localhost`. |
| `networkPassphrase` | `String` | Stellar network passphrase. Use `Network.testnet.passphrase` for testnet, `Network.public.passphrase` for mainnet. |
| `accountWasmHash` | `String` | SHA-256 hash (64 hex chars) of the smart account contract WASM. Returned by the OpenZeppelin contract upload step. |
| `webauthnVerifierAddress` | `String` | C-strkey of the deployed WebAuthn signature verifier contract. Must start with `C`. |

### Optional fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `deployerKeypair` | `KeyPair?` | `nil` | Keypair used to sign the deployment transaction. When `nil`, the deterministic default deployer derived from `SHA-256("openzeppelin-smart-account-kit")` is used (see [How wallet deployment works](#how-wallet-deployment-works)). |
| `rpId` | `String?` | `nil` | WebAuthn Relying Party ID. Stored on the config; consumers must also pass it to the `AppleWebAuthnProvider` initializer. |
| `rpName` | `String` | `"Smart Account"` | WebAuthn Relying Party name shown to users. |
| `sessionExpiryMs` | `Int64` | `604_800_000` (7 days) | Session lifetime in milliseconds. Drives the silent-reconnect window. |
| `signatureExpirationLedgers` | `Int` | `720` (~1 hour) | Auth entry expiration in ledgers. Range `[1, 535_680]`. |
| `timeoutInSeconds` | `Int` | `30` | Default timeout for transaction submission and polling. Range `[1, 600]`. |
| `relayerUrl` | `String?` | `nil` | When set, the kit constructs an `OZRelayerClient` and routes submissions through it for fee sponsoring. |
| `indexerUrl` | `String?` | `nil` | When `nil`, `effectiveIndexerUrl()` falls back to the built-in per-network default for testnet or mainnet. |
| `webauthnProvider` | `WebAuthnProvider?` | `nil` | Required for `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, `addNewPasskeySigner`, and any operation that signs with a passkey. |
| `storage` | `StorageAdapter` | `InMemoryStorageAdapter()` | Credential and session persistence. See [Storage trade-offs](#storage-trade-offs). |
| `externalWallet` | `ExternalWalletAdapter?` | `nil` | Required only when `SelectedSigner.wallet(accountId:)` participates in a multi-signer ceremony. |
| `maxContextRuleScanId` | `UInt32` | `50` | Upper bound on the IDs scanned by `listContextRules()` / `getAllContextRules()` when no `maxScanId` argument is provided. |

### Initializer or builder

Construct directly:

```swift
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "...",
    webauthnVerifierAddress: "...",
    rpName: "My Wallet App",
    sessionExpiryMs: 86_400_000,
    relayerUrl: "https://relayer.example.com",
    webauthnProvider: provider,
    storage: KeychainStorageAdapter()
)
```

or fluently with the builder:

```swift
let config = try OZSmartAccountConfig.builder(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "...",
    webauthnVerifierAddress: "..."
)
    .rpName("My Wallet App")
    .sessionExpiryMs(86_400_000)
    .signatureExpirationLedgers(1_440)
    .relayerUrl("https://relayer.example.com")
    .indexerUrl("https://indexer.example.com")
    .webauthnProvider(provider)
    .storage(KeychainStorageAdapter())
    .externalWallet(myExternalWallet)
    .build()
```

Both paths throw `ConfigurationException` for invalid values.

### Storage trade-offs

| Adapter | Persistence | Encryption | When to use |
|---------|-------------|------------|-------------|
| `InMemoryStorageAdapter` | None (lost on process exit) | None | Unit tests, ephemeral demos. The docstring explicitly warns it is not persistent and not secure. |
| `KeychainStorageAdapter` | iOS Keychain Services with `kSecAttrAccessibleAfterFirstUnlock` | Yes (system-managed) | Recommended default for production. iOS Simulator and unsigned macOS test binaries require the `keychain-access-groups` entitlement. |
| `UserDefaultsStorageAdapter` | Scoped `UserDefaults` suite | None (plaintext property list in the app container) | Lightweight, non-sensitive scenarios only. Apps storing anything with privacy implications should prefer Keychain. |

Stored credentials contain only public-key material (public key, credential ID, contract address, nickname, metadata). No private keys ever leave the device's secure element, so Keychain entries are stored without biometric `SecAccessControl` flags.

### WebAuthn provider construction

`AppleWebAuthnProvider` is the bundled implementation for iOS 16+ and macOS 13+. Construct it with the same `rpId` and `rpName` you set on the config, then pass it into the config:

```swift
let provider = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "Example Wallet"
)
```

On macOS, set `provider.presentationContextProvider` before any `register` or `authenticate` call. The underlying `ASAuthorizationController` is dispatched to the main queue internally; the kit itself imposes no `@MainActor` requirement.

The host app must declare the `com.apple.developer.associated-domains` entitlement with `webcredentials:<rpId>` and serve a matching `.well-known/apple-app-site-association` file under that domain.

## Testnet contract addresses

The smart account WASM hash and the WebAuthn verifier contract address depend on the network and may change when contracts are upgraded, testnet is reset, or their TTL expires. They are not bundled with the SDK and must be supplied through `OZSmartAccountConfig`.

| Setting | Source | Notes |
|---------|--------|-------|
| `rpcUrl` | `https://soroban-testnet.stellar.org` (testnet) | Public Stellar testnet RPC. |
| `networkPassphrase` | `Network.testnet.passphrase` / `Network.public.passphrase` | Use `Network.testnet.passphrase` for testnet. |
| `accountWasmHash` | OpenZeppelin smart account WASM upload | 64 hex characters; obtain by uploading the contract to the network. |
| `webauthnVerifierAddress` | OpenZeppelin WebAuthn verifier deployment | C-strkey of the deployed verifier. |
| `nativeTokenContract` | Network-specific native asset contract (XLM SAC) | Passed per call to `createWallet(autoFund:nativeTokenContract:)` and `transfer(...)`. |
| Simple-threshold / weighted-threshold / spending-limit policy addresses | OpenZeppelin policy deployments | C-strkeys, passed to the corresponding `OZPolicyManager` methods. |
| `indexerUrl` | Defaults to the per-network URL when `nil` | Testnet: `https://smart-account-indexer.sdf-ecosystem.workers.dev`. Mainnet: `https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev`. |
| `relayerUrl` | No built-in default | Supply the URL of any compatible relayer; leave `nil` to make the connected wallet pay fees. |

### Uploading your own WASM

If the deployed testnet WASM has expired or you need a customised build, clone the OpenZeppelin Stellar contracts repository at `https://github.com/OpenZeppelin/stellar-contracts` and upload the binary:

```bash
# Build the smart account WASM
stellar contract build --package multisig-account-example

# Upload to testnet and capture the returned hash
stellar contract upload \
  --network testnet \
  --source <deployer-secret> \
  --wasm target/wasm32v1-none/release/multisig_account_example.wasm
```

The command prints a 64-character hex hash. Use it as `accountWasmHash` in `OZSmartAccountConfig`.

## How wallet deployment works

`createWallet` deploys a Soroban smart account contract. The deployment involves two roles played by the deployer keypair: **address derivation** and **transaction signing**. The contract address is computed from `hash(deployer_public_key, salt, network_passphrase)` where `salt` is `SHA-256(credential_id)`, so the same credential and deployer always produce the same contract address. The deployer signs the deployment transaction as its source account; after deployment it has no privileges over the contract.

The deployer account pays the deployment fee. When a relayer is configured, the relayer wraps the deployment in a fee-bump transaction and sponsors the fee instead, so the deployer only needs to exist on the network with the minimum XLM reserve. The smart account is initialised with a single default context rule (ID 0) whose only signer is the freshly registered passkey; further configuration (additional signers, policies, context rules) is driven through ordinary authorised calls into the contract.

## Deterministic address derivation

Contract address derivation is deterministic: given the same deployer keypair, credential ID, and network passphrase, `SmartAccountUtils.deriveContractAddress(credentialId:deployerPublicKey:networkPassphrase:)` always produces the same C-strkey. This follows from how Soroban computes contract addresses and is a correctness property of the chain, not a special feature.

### Default deployer

The SDK ships a default deployer derived from `SHA-256("openzeppelin-smart-account-kit")`, used as the Ed25519 seed for `KeyPair`. The seed string is fixed by the smart-account contract specification and never changes, so the default deployer address is identical for every consumer of the SDK.

```swift
let deployer = try await OZSmartAccountConfig.createDefaultDeployer()
```

Because the deployer has no privileges over the deployed contract, its publicly derivable secret is not a security concern. It only signs the deploy transaction and pays the deployment fee. Pair it with a relayer for fee sponsoring, or fund it externally.

### Custom deployers

Production wallet applications typically supply their own deployer through `OZSmartAccountConfig.deployerKeypair` for attribution and traceability. The deployer's public key appears on-chain, so a custom deployer lets a wallet provider distinguish its deployments from others. Address derivation still works the same way: the same custom deployer plus credential ID always produce the same contract address.

```swift
let config = try OZSmartAccountConfig(
    rpcUrl: "...",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "...",
    webauthnVerifierAddress: "...",
    deployerKeypair: myFundedKeypair
)
```

When a custom deployer is used, clients that do not know the deployer keypair cannot derive the contract address. An indexer (`indexerUrl`) is recommended in that case for wallet discovery.

### Signer format compatibility

`OZDelegatedSigner` and `OZExternalSigner` encode to the standard Soroban `SCVal` shapes expected by the OpenZeppelin smart account contract. `OZExternalSigner.webAuthn(...)` packs the 65-byte secp256r1 public key together with the credential ID into the `keyData` blob that the WebAuthn verifier consumes. Signers registered through any compatible client are recognised on-chain.

The cryptographic helpers in `SmartAccountUtils` enforce the on-chain format:

- `extractPublicKeyFromRegistration(publicKey:authenticatorData:attestationObject:)` returns a 65-byte uncompressed SEC1 public key with the `0x04` prefix from a WebAuthn attestation.
- `normalizeSignature(_:)` converts a DER-encoded ECDSA signature to a 64-byte compact representation with `s` normalised to its low-S form. Both are required by the on-chain verifier.
- `getContractSalt(credentialId:)` returns `SHA-256(credentialId)`.
- `deriveContractAddress(credentialId:deployerPublicKey:networkPassphrase:)` computes the deterministic C-strkey.

## Contract limits

The OpenZeppelin smart account contract enforces these limits:

| Limit | Value | Constant |
|-------|-------|----------|
| Maximum signers per context rule | 15 | `OZConstants.maxSigners` |
| Maximum policies per context rule | 5 | `OZConstants.maxPolicies` |
| Default signature expiration window | ~1 hour (720 ledgers) | Configurable via `signatureExpirationLedgers`; range `[1, 535_680]` |

Signer and policy limits are validated client-side before submission inside `OZContextRuleManager.addContextRule`.

## Sub-pages

| Guide | Description |
|-------|-------------|
| [Developer Onboarding](onboarding.md) | Smart account concepts, passkeys, the on-chain contract interface, end-to-end lifecycle, prerequisites |
| [API Reference](api-reference.md) | Every public symbol with Swift signatures |
| [WebAuthn Setup: iOS](webauthn-ios.md) | iOS Associated Domains and apple-app-site-association hosting |
| [WebAuthn Setup: macOS](webauthn-macos.md) | macOS Associated Domains, apple-app-site-association, developer-mode setup |
