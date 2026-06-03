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
| `storage` | `StorageAdapter` | `InMemoryStorageAdapter()` | Credential and session persistence. Use `KeychainStorageAdapter` in production. Per-platform adapters and trade-offs are documented in the [iOS](webauthn-ios.md#storage-adapters) and [macOS](webauthn-macos.md#storage-adapters) setup pages. |
| `externalWallet` | `ExternalWalletAdapter?` | `nil` | Wallet adapter (e.g., Freighter, Lobstr) backing the adapter custody model for `SelectedSigner.wallet` signers. The kit injects it into `kit.externalSigners`. |
| `externalEd25519Adapter` | `OZExternalEd25519SignerAdapter?` | `nil` | Ed25519 adapter (hardware wallet, HSM, remote signing service) backing the adapter custody model for `SelectedSigner.ed25519` signers. The kit injects it into `kit.externalSigners`. |
| `maxContextRuleScanId` | `UInt32` | `50` | Upper bound on the context-rule IDs scanned when listing rules without an explicit scan limit. |

### Builder Pattern

For configuration with many optional fields, use the builder:

```swift
let config = try OZSmartAccountConfig.builder(
    rpcUrl: "https://soroban-testnet.stellar.org",
    networkPassphrase: Network.testnet.passphrase,
    accountWasmHash: "<64-char hex WASM hash>",
    webauthnVerifierAddress: "<C-address of the WebAuthn verifier>"
)
    .sessionExpiryMs(86_400_000)  // 1 day
    .relayerUrl("https://relayer.example.com")
    .indexerUrl("https://indexer.example.com")
    .signatureExpirationLedgers(1_440)  // ~2 hours
    .storage(KeychainStorageAdapter())
    .externalWallet(myExternalWallet)
    .build()
```

## Testnet contract addresses

The SDK needs two values that depend on the network: a WASM hash (`accountWasmHash`) for the uploaded smart account binary, and a verifier contract address (`webauthnVerifierAddress`). Both can change when contracts are upgraded, testnet is reset, or their TTL expires. They are not bundled with the SDK and must be supplied through `OZSmartAccountConfig`.

Current testnet values are in `DemoConfig.swift` in the [demo app](https://github.com/Soneso/ios-oz-smartaccount-demo):

```
Sources/Config/DemoConfig.swift
```

### Uploading your own WASM

If the testnet hash has expired or you need a custom contract, clone the [OpenZeppelin stellar-contracts](https://github.com/OpenZeppelin/stellar-contracts) repository and build/upload:

```bash
# Build the smart account WASM
stellar contract build --package multisig-account-example

# Upload to testnet and capture the returned hash
stellar contract upload \
  --network testnet \
  --source <deployer-secret> \
  --wasm target/wasm32v1-none/release/multisig_account_example.wasm
```

The command prints a hex string. Use it as `accountWasmHash` in your `OZSmartAccountConfig`.

## How wallet deployment works

When `createWallet` is called, the SDK deploys a Soroban smart account contract. The deployment involves two roles:

**Deployer keypair**: The deployer is the source account of the deployment transaction. It serves two purposes:

1. **Address derivation**: The contract address is computed from `hash(deployer_public_key, salt, network_passphrase)` where `salt` is `SHA-256(credential_id)`. This makes the address deterministic — the same credential and deployer always produce the same contract address.
2. **Transaction signing**: The deployer signs the deployment transaction as the source account.

After deployment, the deployer has no privileges over the contract. Only the configured signers (passkeys, delegated accounts, Ed25519 keys) can authorize operations on the smart account.

**Fee payment**: The deployer account pays the deployment transaction fee. When a relayer is configured, the relayer wraps the deployment in a fee-bump transaction and sponsors the fee instead, so the deployer only needs to exist on the network with the minimum XLM reserve. If you use the default deployer (derived from a well-known seed — see below), you need either a relayer for fee sponsoring or to fund the deployer account before deployment. You can also provide your own funded keypair via `deployerKeypair` in the config.

## Deterministic address derivation

Contract address derivation is deterministic: given the same deployer keypair, credential ID, and network passphrase, the SDK always produces the same contract address. This is a correctness property, not a special feature — it follows from how Soroban computes contract addresses.

### Default deployer

The SDK provides a default deployer derived from `SHA-256("openzeppelin-smart-account-kit")`. This default is suitable for testing and simple deployments. Other OpenZeppelin Smart Account SDK implementations use the same derivation, so all SDKs produce identical results from the same inputs.

```swift
let deployer = try await OZSmartAccountConfig.createDefaultDeployer()
```

The default deployer's secret seed is publicly derivable. It is intended to be used with a relayer that sponsors transaction fees, or funded externally.

### Custom deployers

Production wallet applications will typically use a custom deployer for attribution and traceability. The deployer signs the deployment transaction, so its public key is visible on-chain — a custom deployer gives the wallet provider identity and allows distinguishing deployments by different providers.

Set `deployerKeypair` in the config to use your own deployer:

```swift
let config = try OZSmartAccountConfig(
    // ...required fields...
    deployerKeypair: myFundedKeypair
)
```

When using a custom deployer, address derivation still works the same way: the same deployer + credential ID always produces the same contract address. An indexer is recommended for wallet discovery with custom deployers, since clients that do not know the deployer keypair cannot derive the address independently.

### Deterministic Contract Addresses

Given the same credential ID and deployer, `SmartAccountUtils.deriveContractAddress(...)` computes the same C-address. This enables:

- Wallet discovery without an indexer (derive the address, check if it exists on-chain)
- Consistent address display across applications
- Correctness verification (same inputs produce the same outputs regardless of SDK implementation)

### Signer format compatibility

`OZDelegatedSigner` and `OZExternalSigner` encode to the standard Soroban `SCVal` shapes expected by the OpenZeppelin smart account contract. `OZExternalSigner.webAuthn(...)` packs the 65-byte secp256r1 public key together with the credential ID into the `keyData` blob that the WebAuthn verifier consumes. Signers registered through any compatible client are recognised on-chain.

## Contract limits

The OpenZeppelin smart account contract enforces these limits:

| Limit | Value |
|-------|-------|
| Maximum signers per context rule | 15 |
| Maximum policies per context rule | 5 |

These limits are defined in `OZConstants` and validated client-side before submitting transactions.

## Sub-pages

| Guide | Description |
|-------|-------------|
| [Onboarding Guide](onboarding.md) | Smart account concepts, passkeys, on-chain contract interface, end-to-end lifecycle |
| [WebAuthn Setup: iOS](webauthn-ios.md) | iOS AuthenticationServices integration, apple-app-site-association setup |
| [WebAuthn Setup: macOS](webauthn-macos.md) | macOS AuthenticationServices integration, associated domains setup |
| [API Reference](api-reference.md) | Full API reference for all public classes and methods |
