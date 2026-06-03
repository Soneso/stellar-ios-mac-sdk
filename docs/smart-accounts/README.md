# Smart Account Kit

The Smart Account Kit provides passkey-authenticated smart accounts on Stellar using OpenZeppelin's Soroban contracts. Users authenticate with biometrics (Face ID, Touch ID, or a hardware security key) instead of managing secret keys. The SDK handles wallet creation, contract deployment, transaction signing, signer management, and policy enforcement across iOS and macOS.

New to smart accounts? Start with the [onboarding guide](onboarding.md) for background on how smart accounts, passkeys, and the on-chain contracts work.

## Overview

A smart account is a Soroban contract that replaces traditional Stellar key management with programmable authorization. Each smart account supports:

- **Passkey authentication**: Users sign transactions with WebAuthn (secp256r1) instead of Ed25519 secret keys
- **Multiple signers**: Combine passkeys, delegated Stellar accounts, and Ed25519 keys on a single account. All three signer types support full multi-signer signing through the `OZMultiSignerManager` pipeline.
- **Context rules**: Define different authorization requirements for different operation types
- **Policies**: Enforce authorization constraints such as spending limits and multi-signature thresholds, or add custom policy contracts
- **Fee sponsoring**: Submit transactions through a relayer so users never pay gas fees
- **Credential discovery**: Optional indexer lookup that maps a passkey credential to one or more deployed smart-account contracts
- **Session management**: Silent reconnection without re-authentication for 7 days (configurable)

The kit wraps the OpenZeppelin smart account contracts deployed on Soroban. The on-chain contract stores signers and policies; the SDK handles WebAuthn ceremonies, transaction assembly, authorization entry signing, and submission.

## Architecture

The kit is split into two layers: a protocol-agnostic `core/` layer (signer types, signature wrappers, the `WebAuthnProvider` protocol, and crypto helpers usable by any Soroban `CustomAccountInterface` contract) and an OpenZeppelin-specific `oz/` layer (the kit, managers, relayer/indexer clients, and storage adapters).

```
+-----------------------------------------------------------------------+
|                         Your Application                              |
+-----------------------------------------------------------------------+
        |
        v
+-----------------------------------------------------------------------+
|                       OZSmartAccountKit                               |
|  Entry point. Created via OZSmartAccountKit.create(config:).          |
|  Provides sub-managers as properties:                                 |
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
| (platform impl)  |  | (platform impl)  |  | (optional)            |
+------------------+  +------------------+  +-----------------------+

        OZSmartAccountKit also uses:

+----------------+  +------------------+  +---------------------+
| SorobanServer  |  | OZRelayerClient  |  | OZIndexerClient     |
| (Soroban RPC)  |  | (fee sponsoring) |  | (credential lookup) |
+----------------+  +------------------+  +---------------------+
```

**OZSmartAccountKit** is the single entry point. It holds configuration, connection state (`isConnected`, `credentialId`, `contractId`), and exposes all operations through sub-managers. Each sub-manager receives a reference to the kit and uses its Soroban server, relayer, indexer, and storage internally.

**WebAuthnProvider** is a platform-specific protocol you implement, or use the provided implementation. It triggers the OS-level biometric prompt and returns raw WebAuthn attestation/assertion data.

**StorageAdapter** persists credentials and sessions. The SDK includes an in-memory adapter for testing and platform-storage adapters for production (see the Configuration Reference).

**External signing** flows through one kit-owned `OZExternalSignerManager`, exposed as `kit.externalSigners` — the single front door for all external (non-passkey) signers. Supply adapters for external wallet signers (e.g. Freighter or WalletConnect) and for raw Ed25519 signers (e.g. an HSM or remote signing service) via configuration, or register in-memory keypairs at runtime. See the [demo app](https://github.com/Soneso/ios-oz-smartaccount-demo) for examples.

The kit and its managers are safe to share across `async` contexts; storage adapters are `public actor` types, so their methods are implicitly async from outside the actor.

## Quick Start

This example configures the kit, creates a wallet, and sends a transfer.

```swift
import stellarsdk

// Step 1: Configure the kit
//
// Required fields come from the OpenZeppelin deployment:
// - rpcUrl: Soroban RPC endpoint
// - networkPassphrase: Stellar network identifier
// - accountWasmHash: SHA-256 hash of the smart account WASM (64-char hex)
// - webauthnVerifierAddress: deployed WebAuthn verifier contract (C-address)
//
// Optional fields configure platform adapters and services.

let provider = try AppleWebAuthnProvider(
    rpId: "wallet.example.com",
    rpName: "Example Wallet"
)

let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "<64-char hex WASM hash>",
    webauthnVerifierAddress: "<C-address of the WebAuthn verifier>",
    relayerUrl: "https://relayer.example.com",   // optional: enables fee sponsoring
    indexerUrl: nil,                             // optional: defaults to a per-network URL
    webauthnProvider: provider,
    storage: KeychainStorageAdapter()           // optional: defaults to InMemoryStorageAdapter
)

// Step 2: Create the kit

let kit = OZSmartAccountKit.create(config: config)

// Step 3: Create a new wallet
//
// Triggers a WebAuthn registration ceremony (biometric prompt), derives a
// deterministic contract address, deploys the smart account contract, and
// funds it via Friendbot (testnet).

let wallet = try await kit.walletOperations.createWallet(
    userName: "Alice",
    autoSubmit: true,
    autoFund: true,
    nativeTokenContract: "<C-address of native XLM SAC>"
)

// wallet.credentialId         -- Base64URL-encoded credential ID
// wallet.contractId           -- Stellar C-address of the deployed contract
// wallet.publicKey            -- 65-byte uncompressed secp256r1 public key
// wallet.signedTransactionXdr -- signed deploy envelope (always populated)
// wallet.transactionHash      -- deployment tx hash (set when autoSubmit = true)

// Step 4: Transfer tokens
//
// Triggers a WebAuthn authentication ceremony (biometric prompt) to sign the
// authorization entry. If a relayer is configured, the transaction is fee-sponsored.

let result = try await kit.transactionOperations.transfer(
    tokenContract: "<C-address of token contract>",
    recipient: "<recipient G-address>",
    amount: "10"  // decimal amount; stroop conversion is automatic
)

if result.success {
    print("Transfer succeeded. Hash: \(result.hash ?? "")")
} else {
    print("Transfer failed: \(result.error ?? "unknown error")")
}

// Step 5: Disconnect when done
//
// Clears in-memory state and stored session. Credentials remain in storage
// for reconnection.

try await kit.disconnect()
```

### Reconnecting to an Existing Wallet

On app relaunch, use a two-phase connect pattern. Phase 1 silently restores the session without prompting the user. If no session exists, show a connect button and let the user trigger Phase 2.

```swift
// Phase 1: Silent restore at app launch (no biometric prompt)
if let connection = try await kit.walletOperations.connectWallet() {
    switch connection {
    case let .connected(_, contractId, _):
        print("Reconnected to \(contractId)")
    case .ambiguous:
        break  // Unreachable for the silent restore path
    }
} else {
    // No usable session -- show a "Connect" button
}

// Phase 2: User taps "Connect" -- triggers WebAuthn if no session
if let connection = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(prompt: true)
) {
    switch connection {
    case let .connected(_, contractId, _):
        print("Connected to \(contractId)")
    case let .ambiguous(credentialId, candidates):
        // Indexer reported multiple contracts for the same credential. Ask the
        // user to pick one and reconnect with the chosen contractId.
        // `showContractPicker` is your own picker UI -- not provided by the SDK.
        let chosen = await showContractPicker(candidates)
        _ = try await kit.walletOperations.connectWallet(
            options: ConnectWalletOptions(credentialId: credentialId, contractId: chosen)
        )
    }
}
```

Force fresh authentication when needed (e.g., before sensitive operations):

```swift
let connection = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(fresh: true)
)
```

Connect directly with known credentials (skips WebAuthn and session check; the cascade is bypassed so the result is always `.connected` on success):

```swift
let connection = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(
        credentialId: "<base64url credential id>",
        contractId: "<C-address>"
    )
)
```

### Retrying Failed Deployments

When `createWallet(autoSubmit: false)` is used, or if a deployment fails after the credential is created, use `deployPendingCredential` to submit the deploy transaction later. The credential must exist in local storage. The `signedTransactionXdr` field on `CreateWalletResult` is always populated regardless of `autoSubmit`, so it can also be submitted externally.

```swift
let result = try await kit.walletOperations.deployPendingCredential(
    credentialId: createResult.credentialId,
    autoSubmit: true
)
print("Deployed: \(result.contractId), tx: \(String(describing: result.transactionHash))")
```

### Managing Signers

Add additional signers to a context rule so multiple parties can authorize transactions:

```swift
// Add a delegated Stellar account as a signer on the Default context rule (ID 0)
let addResult = try await kit.signerManager.addDelegated(
    contextRuleId: 0,
    address: "<delegated G-address>"
)

// Add a new passkey signer (handles WebAuthn registration, credential storage,
// and on-chain signer addition in one step)
let passkeyResult = try await kit.signerManager.addNewPasskeySigner(
    contextRuleId: 0,
    userName: "Alice backup device"
)
// passkeyResult.credentialId      -- Base64URL-encoded credential ID (no padding)
// passkeyResult.publicKey         -- 65-byte uncompressed secp256r1 public key
// passkeyResult.transactionResult -- on-chain submission result

// Low-level alternative: add a passkey signer with pre-extracted cryptographic materials
let lowLevelResult = try await kit.signerManager.addPasskey(
    contextRuleId: 0,
    publicKey: otherPublicKey,       // 65-byte uncompressed secp256r1 key
    credentialId: otherCredentialId  // raw credential ID bytes
)

// Remove a signer by its on-chain signer ID
let removeResult = try await kit.signerManager.removeSigner(
    contextRuleId: 0,
    signerId: 1
)
```

### Adding Policies

Policies enforce constraints on context rules. Each context rule supports up to 5 policies. Built-in helpers cover the three OpenZeppelin policy contracts: `addSimpleThreshold`, `addWeightedThreshold`, and `addSpendingLimit`.

```swift
// Require 2-of-3 signers to authorize
let thresholdResult = try await kit.policyManager.addSimpleThreshold(
    contextRuleId: 0,
    policyAddress: "<C-address of the simple-threshold policy>",
    threshold: 2
)

// Limit spending to 1000 XLM per day
let limitResult = try await kit.policyManager.addSpendingLimit(
    contextRuleId: 0,
    policyAddress: "<C-address of the spending-limit policy>",
    spendingLimit: "1000",
    periodLedgers: UInt32(StellarProtocolConstants.ledgersPerDay)
)
```

For custom policy contracts beyond the built-in types, use `addPolicy` with policy-specific install parameters:

```swift
let result = try await kit.policyManager.addPolicy(
    contextRuleId: 0,
    policyAddress: "<C-address of the custom policy>",
    installParams: SCValXDR.map([
        SCMapEntryXDR(
            key: SCValXDR.symbol("my_param"),
            val: SCValXDR.u32(42)
        )
    ])
)
```

### Multi-Signer Operations

When a context rule requires multiple signers, use `kit.multiSignerManager` to coordinate signatures. `multiSignerTransfer()` handles token transfers; `multiSignerContractCall()` handles arbitrary external contract calls (e.g., governance votes, multisig swaps), authorized through the matching call-contract context rule; and `multiSignerExecuteAndSubmit()` routes a call through the smart account's `execute` entry point.

All three signer kinds — passkey (`SelectedSigner.passkey`), delegated wallet (`SelectedSigner.wallet`), and Ed25519 external (`SelectedSigner.ed25519`) — may be mixed in the same `selectedSigners` list. Wallet and Ed25519 signers resolve through the kit-owned `kit.externalSigners` manager: register an in-memory key at runtime (`kit.externalSigners.addFromSecret(...)` / `kit.externalSigners.addEd25519FromRawKey(...)`) or supply an adapter at kit construction (`externalWallet` / `externalEd25519Adapter`).

See the [API Reference](api-reference.md#multi-signer-operations) for `SelectedSigner` types, custody models, and registration examples.

### Error Handling

All operations throw typed exceptions from the `SmartAccountException` hierarchy:

```swift
do {
    let wallet = try await kit.walletOperations.createWallet(userName: "Alice", autoSubmit: true)
} catch is WebAuthnException.Cancelled {
    print("User cancelled the biometric prompt")
} catch let error as WebAuthnException.NotSupported {
    print("WebAuthn not configured: \(error.message)")
} catch let error as TransactionException.SimulationFailed {
    print("Contract simulation failed: \(error.message)")
} catch let error as TransactionException.SubmissionFailed {
    print("Transaction submission failed: \(error.message)")
} catch is WalletException.NotFound {
    print("Wallet not found on-chain")
} catch let error as SmartAccountException {
    print("Error [\(error.code.rawValue)]: \(error.message)")
}
```

## Configuration Reference

`OZSmartAccountConfig` holds all parameters. Four fields are required; the rest have defaults. The constructor validates inputs and throws `ConfigurationException` on invalid values.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `rpcUrl` | `String` | Soroban RPC endpoint URL (for example `https://soroban-testnet.stellar.org`). |
| `networkPassphrase` | `String` | Stellar network passphrase. Use `Network.testnet.passphrase` for testnet or `Network.public.passphrase` for mainnet. |
| `accountWasmHash` | `String` | SHA-256 hash (64 hex characters) of the smart account contract WASM binary. Obtained after uploading the contract to the network. |
| `webauthnVerifierAddress` | `String` | Contract address (C-address, 56 characters) of the deployed WebAuthn signature verifier. Must start with `C`. |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `deployerKeypair` | `KeyPair?` | `nil` (uses default) | Keypair used for contract deployment. If `nil`, derived from `SHA-256("openzeppelin-smart-account-kit")`. See [How wallet deployment works](#how-wallet-deployment-works). |
| `sessionExpiryMs` | `Int64` | `604_800_000` (7 days) | Session duration in milliseconds. Sessions enable reconnection without re-authentication. |
| `signatureExpirationLedgers` | `Int` | `720` (~1 hour) | Auth entry expiration in ledgers (~5 seconds per ledger). Prevents replay attacks. Must be `>= 1`. |
| `timeoutInSeconds` | `Int` | `30` | Sets each transaction's TimeBounds (`max_time = now + timeoutInSeconds`; `0` = no expiry), bounding how long a signed transaction stays valid for submission. Must be `>= 0`. |
| `relayerUrl` | `String?` | `nil` | Relayer endpoint for fee-sponsored transactions. When set, users do not pay gas fees. |
| `indexerUrl` | `String?` | `nil` | Indexer endpoint for credential-to-contract discovery. When `nil`, falls back to the built-in per-network default (testnet/mainnet). |
| `webauthnProvider` | `WebAuthnProvider?` | `nil` | Platform-specific WebAuthn implementation. Required for `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, and any passkey-signing flow. |
| `storage` | `StorageAdapter` | `InMemoryStorageAdapter()` | Credential and session persistence. See [Storage trade-offs](#storage-trade-offs). |
| `externalWallet` | `ExternalWalletAdapter?` | `nil` | Wallet adapter (e.g., Freighter, Lobstr) backing the adapter custody model for `SelectedSigner.wallet` signers. The kit injects it into `kit.externalSigners`. |
| `externalEd25519Adapter` | `OZExternalEd25519SignerAdapter?` | `nil` | Ed25519 adapter (hardware wallet, HSM, remote signing service) backing the adapter custody model for `SelectedSigner.ed25519` signers. The kit injects it into `kit.externalSigners`. |
| `maxContextRuleScanId` | `UInt32` | `50` | Upper bound on the context-rule IDs scanned when listing rules without an explicit scan limit. |

### Initializer or Builder

Construct directly:

```swift
let config = try OZSmartAccountConfig(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "<64-char hex WASM hash>",
    webauthnVerifierAddress: "<C-address of the WebAuthn verifier>",
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
    accountWasmHash: "<64-char hex WASM hash>",
    webauthnVerifierAddress: "<C-address of the WebAuthn verifier>"
)
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

### Storage Trade-Offs

| Adapter | Persistence | Encryption | When to use |
|---------|-------------|------------|-------------|
| `InMemoryStorageAdapter` | None (lost on process exit) | None | Unit tests, ephemeral demos. The docstring explicitly warns it is not persistent and not secure. |
| `KeychainStorageAdapter` | iOS Keychain Services with `kSecAttrAccessibleAfterFirstUnlock` | Yes (system-managed) | Recommended default for production. iOS Simulator and unsigned macOS test binaries require the `keychain-access-groups` entitlement. |
| `UserDefaultsStorageAdapter` | Scoped `UserDefaults` suite | None (plaintext property list in the app container) | Lightweight, non-sensitive scenarios only. Apps storing anything with privacy implications should prefer Keychain. |

Stored credentials contain only public-key material (public key, credential ID, contract address, nickname, metadata). No private keys ever leave the device's secure element, so Keychain entries are stored without biometric `SecAccessControl` flags.

### WebAuthn Provider Construction

`AppleWebAuthnProvider` is the bundled implementation for iOS 16+ and macOS 13+. Construct it with the relying-party `rpId` and `rpName`, then pass it into the config via `webauthnProvider`:

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
| `webauthnVerifierAddress` | OpenZeppelin WebAuthn verifier deployment | C-address of the deployed verifier. |
| `nativeTokenContract` | Network-specific native asset contract (XLM SAC) | Passed per call to `createWallet(autoFund:nativeTokenContract:)` and `transfer(...)`. |
| Simple-threshold / weighted-threshold / spending-limit policy addresses | OpenZeppelin policy deployments | C-addresses, passed to the corresponding `OZPolicyManager` methods. |
| `indexerUrl` | Defaults to the per-network URL when `nil` | Testnet: `https://smart-account-indexer.sdf-ecosystem.workers.dev`. Mainnet: `https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev`. These default endpoints are operated externally and may change; set `indexerUrl` explicitly to pin your own. |
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

As noted in [How wallet deployment works](#how-wallet-deployment-works), the contract address is derived from the deployer public key, the credential-ID salt, and the network passphrase. `SmartAccountUtils.deriveContractAddress(credentialId:deployerPublicKey:networkPassphrase:)` exposes this derivation directly. It is a correctness property of how Soroban computes contract addresses, not a special feature.

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
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "<64-char hex WASM hash>",
    webauthnVerifierAddress: "<C-address of the WebAuthn verifier>",
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
- `deriveContractAddress(credentialId:deployerPublicKey:networkPassphrase:)` computes the deterministic C-address.

## Contract limits

The OpenZeppelin smart account contract enforces these limits:

| Limit | Value | Constant |
|-------|-------|----------|
| Maximum signers per context rule | 15 | `OZConstants.maxSigners` |
| Maximum policies per context rule | 5 | `OZConstants.maxPolicies` |
| Default signature expiration window | ~1 hour (720 ledgers) | Configurable via `signatureExpirationLedgers`; must be `>= 1`. No client-side upper bound — the host enforces the network `maxEntryTTL`. |

Signer and policy limits are validated client-side before submission inside `OZContextRuleManager.addContextRule`.

## Sub-pages

| Guide | Description |
|-------|-------------|
| [Developer Onboarding](onboarding.md) | Smart account concepts, passkeys, the on-chain contract interface, end-to-end lifecycle, prerequisites |
| [API Reference](api-reference.md) | Every public symbol with Swift signatures |
| [WebAuthn Setup: iOS](webauthn-ios.md) | iOS Associated Domains and apple-app-site-association hosting |
| [WebAuthn Setup: macOS](webauthn-macos.md) | macOS Associated Domains, apple-app-site-association, developer-mode setup |
