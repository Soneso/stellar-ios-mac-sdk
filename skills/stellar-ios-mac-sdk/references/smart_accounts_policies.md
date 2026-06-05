# Context Rules, Policies, and Multi-Signer Operations

Signers, context rules, policies, and multi-signer ceremonies for an existing OpenZeppelin smart account — the dynamic authorization layer on top of the core API in [smart_accounts.md](./smart_accounts.md). Platform WebAuthn setup (entitlements, associated domains) lives in [smart_accounts_webauthn.md](./smart_accounts_webauthn.md).

Every example assumes the kit is already created and connected:

```swift
import stellarsdk

// `kit` is an OZSmartAccountKit created via OZSmartAccountKit.create(config:)
// and connected via kit.walletOperations.connectWallet(...). See smart_accounts.md.
let connected = try await kit.walletOperations.connectWallet()
guard case .connected? = connected else {   // connectWallet returns OZConnectWalletResult?
    // show login UI; nothing below works without a live connection
    return
}
```

All manager methods (state-changing and read-only) are `async throws`. Manager access is by property, never a function call.

## Table of Contents

- [Overview](#overview)
- [Signer Management](#signer-management)
- [Context Rules](#context-rules)
- [Policies](#policies)
- [Multi-Signer Operations](#multi-signer-operations)
- [Common Scenarios](#common-scenarios)
- [Events](#events)
- [Contract Error Codes](#contract-error-codes)

## Overview

On-chain authorization for a smart account is arranged in three layers:

```
Smart Account (C-address)
  |
  +-- Context Rule #0 (Default, created at deploy)
  |     +-- Signers:  [Passkey (initial credential)]
  |     +-- Policies: []
  |
  +-- Context Rule #1 (callContract("Cxxx...") e.g. a token)
  |     +-- Signers:  [Passkey A, Passkey B, Wallet G...]
  |     +-- Policies: [SpendingLimit("100 XLM / day")]
  |
  +-- Context Rule #2 (callContract("Cyyy...") e.g. a DAO)
        +-- Signers:  [Wallet G..., Wallet G...]
        +-- Policies: [WeightedThreshold(weights, 80)]
```

When a transaction runs, the contract picks the rules whose context type matches the invocation: specific-type rules (`callContract`, `createContract`) are evaluated first, and the `defaultRule` is the fallback. A rule passes when its signers have signed and every one of its policies returns success.

**Single-passkey vs multi-signer.** Every state-changing manager method takes an optional `selectedSigners: [OZSelectedSigner]` parameter (default `[]`):

- `selectedSigners: []` (default) — single-signer mode. The operation is authorized by the connected passkey alone (one biometric prompt). Requires a `webauthnProvider` in config.
- `selectedSigners: [...]` (non-empty) — multi-signer mode. The operation routes through the multi-signer ceremony coordinator, collecting a signature from every listed signer. Used when a rule needs a threshold `> 1`, or when collecting signatures from separate devices/users. The connected passkey is NOT added implicitly — include it explicitly if it should sign. See [Multi-Signer Operations](#multi-signer-operations).

Typical use cases:

- **Passkey rotation / backup** — add a second passkey, a backup Ed25519 key, or a delegated wallet as additional signers on the Default rule.
- **Spending limits** — scope a spending-limit policy to one token contract via a `callContract` rule.
- **Multi-party approval** — install a simple- or weighted-threshold policy on a rule that protects a governance contract.
- **Per-contract permissions** — allow a dApp helper passkey to authorize only calls to one specific contract.

Managers covered here, all accessed as properties on `kit`:

| Manager | Property | Type |
|---------|----------|------|
| Signer management | `kit.signerManager` | `OZSignerManager` |
| Context rules | `kit.contextRuleManagerConcrete` | `OZContextRuleManager` |
| Policies | `kit.policyManager` | `OZPolicyManager` |
| Multi-signer ceremonies | `kit.multiSignerManager` | `OZMultiSignerManager` |
| External (non-passkey) custody | `kit.externalSigners` | `OZExternalSignerManager` |

Two accessors carry a `Concrete` suffix because the unsuffixed alias returns an SDK-internal protocol type:

```swift
// WRONG: kit.contextRuleManager.listContextRules()
//   — `contextRuleManager` returns a protocol type that is internal to the SDK
//     module and not reachable from consumer code.
// CORRECT: kit.contextRuleManagerConcrete.listContextRules()
// Likewise for credentials:
// CORRECT: kit.credentialManagerConcrete.getCredential(credentialId: ...)
```

Rule limits: `OZConstants.maxSigners` (15) signers, `OZConstants.maxPolicies` (5) policies per rule. A rule must have at least one signer or one policy.

---

## Signer Management

`kit.signerManager` (`OZSignerManager`) adds and removes signers bound to a context rule. Three signer kinds are supported:

- WebAuthn passkeys (secp256r1, verified through a verifier contract).
- Delegated signers (Stellar `G…` accounts or `C…` contracts, authorized through the host's built-in `require_auth`).
- Ed25519 signers (32-byte Ed25519 keys, verified through a verifier contract).

Every state-changing method below takes `selectedSigners: [OZSelectedSigner] = []` and `forceMethod: OZSubmissionMethod? = nil`.

### addNewPasskeySigner — register and add in one step

Runs a WebAuthn registration ceremony, persists the new credential as `pending` in storage, emits `OZSmartAccountEvent.credentialCreated`, then submits the on-chain `add_signer` call by delegating to `addPasskey(...)`. Requires `webauthnProvider` in config.

```swift
public func addNewPasskeySigner(
    contextRuleId: UInt32,
    userName: String,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZAddPasskeySignerResult

public struct OZAddPasskeySignerResult: Sendable, Hashable {
    public let credentialId: String          // Base64URL, unpadded
    public let publicKey: Data               // 65-byte uncompressed secp256r1
    public let transactionResult: OZTransactionResult
}
```

```swift
let result = try await kit.signerManager.addNewPasskeySigner(
    contextRuleId: 0,                          // Default rule
    userName: "Alice backup device"
)
print("Credential: \(result.credentialId)")
print("Submitted:  \(result.transactionResult.success), hash=\(result.transactionResult.hash ?? "n/a")")
```

In single-signer mode the user sees two biometric prompts: one to register the new passkey, one for the connected passkey to authorize the on-chain call.

```swift
// WRONG: calling addNewPasskeySigner without a webauthnProvider in config
//   -> throws WebAuthnException.NotSupported
// CORRECT: configure webauthnProvider before calling this method
```

### addPasskey — add a pre-registered passkey

Use when the public key and raw credential id are already in hand (for example, imported from another device). Builds `OZExternalSigner.webAuthn(...)` (the verifier address comes from `config.webauthnVerifierAddress`) and submits the on-chain `add_signer` call only — no local credential is stored.

> **Transport authenticity — anyone who can inject bytes into the import channel becomes a signer.** Bring `publicKey` and `credentialId` over a transport authenticated to the user and confirm a credential fingerprint on both devices first. Use the first 16 bytes of `SHA-256(publicKey)` hex-encoded — NOT `publicKey[0..<16]`, since byte 0 is always the constant `0x04` SEC-1 prefix and adds no entropy.

```swift
public func addPasskey(
    contextRuleId: UInt32,
    publicKey: Data,            // 65 bytes, first byte 0x04
    credentialId: Data,         // raw bytes, NOT Base64URL
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
// PRECONDITION: publicKey and credentialId were verified with the user on
// both devices via an authenticated channel.
let result = try await kit.signerManager.addPasskey(
    contextRuleId: 0,
    publicKey: otherDevicePublicKey65,     // Data, 65 bytes
    credentialId: otherDeviceCredentialId  // Data, raw bytes
)
if !result.success { print("Failed: \(result.error ?? "")") }
```

```swift
// WRONG: publicKey.count == 33   — compressed format, rejected (must be 65)
// CORRECT: publicKey.count == 65 and publicKey.first == 0x04
// WRONG: credentialId = Data(base64URLEncoded credential string)
//   — pass the RAW credential bytes, not the Base64URL string re-encoded
// CORRECT: credentialId is the raw Data from the WebAuthn ceremony
```

### addDelegated — add a Stellar account or contract signer

```swift
public func addDelegated(
    contextRuleId: UInt32,
    address: String,            // G-address (account) or C-address (contract)
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
// Add a Stellar account as a signer
let accountRes = try await kit.signerManager.addDelegated(
    contextRuleId: 0,
    address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
)

// Add another contract (a custom account contract) as a signer
let contractRes = try await kit.signerManager.addDelegated(
    contextRuleId: 0,
    address: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
)
```

The signer authorizes through the host's built-in `require_auth`; no verifier contract is needed. An address that is neither a valid `G…` strkey nor a valid `C…` strkey throws `SmartAccountValidationException.InvalidAddress`.

### addEd25519 — add an Ed25519 external signer

Requires a deployed Ed25519 verifier contract. `publicKey` is the raw 32-byte Ed25519 key.

```swift
public func addEd25519(
    contextRuleId: UInt32,
    verifierAddress: String,    // C-address of the Ed25519 verifier
    publicKey: Data,            // 32 bytes
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
let result = try await kit.signerManager.addEd25519(
    contextRuleId: 0,
    verifierAddress: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
    publicKey: backupEd25519PublicKey   // 32 bytes
)
```

```swift
// WRONG: publicKey.count == 64   — that is a signature, not a key
// CORRECT: publicKey.count == 32  — raw Ed25519 public key
```

### removeSigner — by on-chain id

Signer ids are assigned by the contract on insertion and surface on `OZParsedContextRule.signerIds`, positionally aligned with `OZParsedContextRule.signers`.

```swift
public func removeSigner(
    contextRuleId: UInt32,
    signerId: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
let rules = try await kit.contextRuleManagerConcrete.listContextRules()
let rule  = rules.first { $0.id == 0 }!

// signers and signerIds are positionally aligned
if let idx = rule.signers.firstIndex(where: { signer in
    OZSmartAccountBuilders.signerMatchesAddress(
        signer: signer,
        address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    )
}) {
    _ = try await kit.signerManager.removeSigner(
        contextRuleId: 0,
        signerId: rule.signerIds[idx]
    )
}
```

```swift
// WRONG: signerId = 0 for the first signer   — ids are contract-assigned, NOT positional
// CORRECT: read signerId from rule.signerIds at the matching position
```

### removeSignerBySigner — by signer value

Distinct method name (Swift cannot cleanly overload `removeSigner` by argument type). Resolves the numeric id internally with one extra RPC round trip (fetches and parses the target rule, locates the signer by `OZSmartAccountBuilders.signersEqual`, bounds-checks the index), then delegates to `removeSigner(contextRuleId:signerId:...)`.

```swift
public func removeSignerBySigner(
    contextRuleId: UInt32,
    signer: any OZSmartAccountSigner,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
// Remove a known delegated signer without fetching ids manually
let signer = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
_ = try await kit.signerManager.removeSignerBySigner(
    contextRuleId: 0,
    signer: signer
)
```

Throws `SmartAccountValidationException.InvalidInput` when the signer is not on the rule, or `SmartAccountConfigurationException.InvalidConfig` when the manager was constructed without a context-rule parser (a non-default kit composition).

### Removing the last signer

The contract rejects removing the final signer when the rule has no policies — see error 3004 (`NoSignersAndPolicies`) in [Contract Error Codes](#contract-error-codes).

```swift
// WRONG: removing the last signer on a rule that has no policies
//   -> contract error 3004 NoSignersAndPolicies at simulation time
// CORRECT: add a policy first, or remove the entire rule (removeContextRule).
```

### Signer type recap

`OZSmartAccountSigner` is a protocol with two concrete conformers:

```swift
public protocol OZSmartAccountSigner: Sendable {
    func toScVal() throws -> SCValXDR
    var uniqueKey: String { get }   // "delegated:<addr>" or "external:<verifier>:<keyDataHex>"
}

public struct OZDelegatedSigner: OZSmartAccountSigner, Equatable, Hashable {
    public let address: String
    public init(address: String) throws    // throws InvalidAddress for non-G/C strkey
}

public struct OZExternalSigner: OZSmartAccountSigner, Equatable, Hashable {
    public let verifierAddress: String
    public let keyData: Data
    public init(verifierAddress: String, keyData: Data) throws
    public static func webAuthn(verifierAddress: String, publicKey: Data, credentialId: Data) throws -> OZExternalSigner
    public static func ed25519(verifierAddress: String, publicKey: Data) throws -> OZExternalSigner
}
```

`OZExternalSigner.webAuthn` packs `keyData = publicKey || credentialId`; `OZExternalSigner.ed25519` stores the 32-byte key directly. Inspect a parsed signer with the `OZSmartAccountBuilders` helpers:

```swift
OZSmartAccountBuilders.getCredentialIdFromSigner(signer: s)     // Data?  (raw credential id, WebAuthn only)
OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: s) // String? (Base64URL credential id)
OZSmartAccountBuilders.signersEqual(a, b)                       // Bool
OZSmartAccountBuilders.getSignerKey(signer: s)                  // String (== signer.uniqueKey)
```

An `OZExternalSigner`'s shape is distinguished by `keyData.count`: `> 65` (secp256r1 pubkey 65 || credentialId) is WebAuthn; `== 32` is Ed25519; anything else is a generic external verifier.

### Listing unique signers across all rules

The same signer can sit on multiple rules and must appear once. For a flat unique list, use the ready-made helper:

```swift
let rules = try await kit.contextRuleManagerConcrete.listContextRules()
let unique = OZSmartAccountBuilders.collectUniqueSigners(
    signers: rules.flatMap { $0.signers }
)   // deduped by getSignerKey, first-occurrence order
```

To also track which rules each unique signer belongs to, scan and key a dictionary by `OZSmartAccountBuilders.getSignerKey(signer:)`:

```swift
var rulesByKey: [String: [OZParsedContextRule]] = [:]
for rule in rules {
    for signer in rule.signers {
        let key = OZSmartAccountBuilders.getSignerKey(signer: signer)
        if rulesByKey[key]?.contains(where: { $0.id == rule.id }) != true {
            rulesByKey[key, default: []].append(rule)
        }
    }
}
```

```swift
// WRONG: comparing parsed signers with == to dedup
//   — `any OZSmartAccountSigner` is not Equatable across concrete types.
// CORRECT: dedup by OZSmartAccountBuilders.getSignerKey(signer:) /
//   compare two signers with OZSmartAccountBuilders.signersEqual(a, b).
```

---

## Context Rules

`kit.contextRuleManagerConcrete` (`OZContextRuleManager`) creates, lists, parses, updates, and removes context rules.

### The Default rule

Every smart account deploys with one rule at `id = 0`: `contextType = .defaultRule`, signers `[initial passkey]`, no policies. The Default rule is the fallback — any operation that does not match a more specific rule goes through it. Add signers/policies to it freely, but do not remove it unless you have replaced it with a rule of equal or greater coverage; otherwise the account becomes unusable.

### OZContextRuleType

```swift
public enum OZContextRuleType: Sendable, Hashable {
    case defaultRule
    case callContract(contractAddress: String)
    case createContract(wasmHash: Data)

    public func toScVal() throws -> SCValXDR
}
```

On-chain encoding produced by `toScVal()`:

```
defaultRule     ->  vec([Symbol("Default")])
callContract    ->  vec([Symbol("CallContract"), Address(contractAddress)])
createContract  ->  vec([Symbol("CreateContract"), Bytes(wasmHash)])
```

```swift
// WRONG: OZContextRuleType.callContract("CBCD...")
//   — the case has a labeled associated value
// CORRECT: OZContextRuleType.callContract(contractAddress: "CBCD...")

// WRONG: OZContextRuleType.createContract(wasmHash: "abcd...")   — that is a String, not Data
// CORRECT: OZContextRuleType.createContract(wasmHash: wasmHashData)   // raw 32-byte Data
//   or use OZBuilders.createCreateContractContextType(wasmHashHex:) to convert hex.
```

The `OZBuilders` static helpers wrap construction with validation:

```swift
let defaultCtx = OZBuilders.createDefaultContextType()                                  // .defaultRule
let callCtx    = try OZBuilders.createCallContractContextType(contractAddress: "CBCD...") // validates C-address
let createCtx1 = try OZBuilders.createCreateContractContextType(wasmHashHex: "abc123...") // 64 hex chars, 0x prefix optional
let createCtx2 = try OZBuilders.createCreateContractContextType(wasmHash: wasmHash32)      // Data, 32 bytes
```

### addContextRule

```swift
public func addContextRule(
    contextType: OZContextRuleType,
    name: String,                          // metadata; non-empty
    validUntil: UInt32? = nil,             // Option<u32> ledger sequence; nil = non-expiring
    signers: [any OZSmartAccountSigner],
    policies: [String: SCValXDR] = [:],    // C-address -> install params
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

The `policies` map key is the policy contract address (`C…`); the value is the install-param `SCValXDR`. The SDK sorts the top-level `policies` map by XDR-byte key order before submission to satisfy Soroban's `ScMap` ordering invariant. This map is the ONLY way to create a rule WITH a policy in one submission — the convenience methods on `kit.policyManager` cannot create a rule. See [Which install path to use](#which-install-path-to-use) for the install-param map shapes.

Example — a rule scoped to a specific token contract, with two delegated signers and an inline spending-limit policy install map:

```swift
let signerA = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
let signerB = try OZDelegatedSigner(address: "GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL")

// Build the SpendingLimit install-param SCVal (see the SpendingLimit shape under
// "Which install path to use").
let spendingLimitParams = SCValXDR.map([
    SCMapEntryXDR(key: .symbol("period_ledgers"),
                  val: .u32(UInt32(StellarProtocolConstants.ledgersPerDay))),  // 17280
    SCMapEntryXDR(key: .symbol("spending_limit"),
                  val: try SCValXDR.i128(stringValue: String(1000 * StellarProtocolConstants.stroopsPerXlm)))  // stroops
])

let result = try await kit.contextRuleManagerConcrete.addContextRule(
    contextType: .callContract(contractAddress: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"),
    name: "XlmDailyLimit",
    signers: [signerA, signerB],
    policies: ["CSPENDINGLIMITGCYSCXLMDAILYRATELIMITAAAAAAAAAAAAAAAAAAA": spendingLimitParams]
)
if result.success { print("Rule added, tx \(result.hash ?? "n/a")") }
```

```swift
// WRONG: addContextRule(signers: [], policies: [:])
//   -> SmartAccountValidationException: a rule must have >= 1 signer OR >= 1 policy
// CORRECT: supply at least one signer or one policy
// WRONG: name longer than 20 UTF-8 bytes  -> contract error 3015 NameTooLong
// CORRECT: name <= 20 UTF-8 bytes
// WRONG: validUntil set to an already-past ledger  -> contract error 3005 PastValidUntil
// CORRECT: validUntil is a future ledger, or nil
```

### OZParsedContextRule

```swift
public struct OZParsedContextRule: Sendable, Hashable {
    public let id: UInt32
    public let contextType: OZContextRuleType
    public let name: String
    public let signers: [any OZSmartAccountSigner]   // positionally aligned with signerIds
    public let signerIds: [UInt32]
    public let policies: [String]                     // C-addresses, aligned with policyIds
    public let policyIds: [UInt32]
    public let validUntil: UInt32?
}
```

### Listing and reading rules

```swift
public func listContextRules(maxScanId: UInt32? = nil) async throws -> [OZParsedContextRule]
public func getAllContextRules(maxScanId: UInt32? = nil) async throws -> [SCValXDR]
public func getContextRule(id: UInt32) async throws -> SCValXDR
public func getContextRulesCount() async throws -> UInt32
```

`maxScanId` defaults to `nil`, so both `listContextRules()` and `listContextRules(maxScanId: 200)` are valid call styles (likewise for `getAllContextRules`).

```swift
let rules = try await kit.contextRuleManagerConcrete.listContextRules()
for rule in rules {
    print("Rule #\(rule.id): \(rule.name) (\(rule.contextType))")
    print("  signers: \(rule.signers.count)  policies: \(rule.policies.count)")
    if let until = rule.validUntil { print("  expires at ledger \(until)") }
}
```

Ids are monotonically increasing and never reused, so removed rules leave numeric gaps that the scan-based enumeration skips. `listContextRules()` scans ids from 0 up to `config.maxContextRuleScanId` (default `50`). Raise that config value, or pass `maxScanId:`, if an account has accumulated more than 50 rules over its lifetime.

### updateName

Changes a rule's display name only; names do not affect matching or enforcement.

```swift
public func updateName(
    id: UInt32,
    name: String,                          // non-empty
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
_ = try await kit.contextRuleManagerConcrete.updateName(id: 1, name: "TokenTransfers")
```

### updateValidUntil

Sets or clears a rule's expiration ledger. Pass `nil` to remove expiration. On chain the field is `Option<u32>` encoded as `Void` for `None` and `U32` for `Some`.

```swift
public func updateValidUntil(
    id: UInt32,
    validUntil: UInt32?,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
// Expire a rule in roughly one week. Read the current ledger from a
// consumer-owned SorobanServer built on the same RPC URL passed to the kit
// config; getLatestLedger() returns a Result-style enum, not a thrown value.
let server = SorobanServer(endpoint: kit.config.rpcUrl)
guard case .success(let latest) = await server.getLatestLedger() else {
    throw SmartAccountTransactionException.simulationFailed(reason: "could not read latest ledger")
}
let inAWeek = latest.sequence + UInt32(7 * StellarProtocolConstants.ledgersPerDay)
_ = try await kit.contextRuleManagerConcrete.updateValidUntil(id: 1, validUntil: inAWeek)

// Remove expiration
_ = try await kit.contextRuleManagerConcrete.updateValidUntil(id: 1, validUntil: nil)
```

The contract skips a rule once its `validUntil` is past; evaluation falls back to matching non-expired rules (and Default). Expired rules persist on-chain until `removeContextRule`.

### removeContextRule

```swift
public func removeContextRule(
    id: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
_ = try await kit.contextRuleManagerConcrete.removeContextRule(id: 3)
```

Do not remove rule `0` (Default) unless equivalent coverage already exists — the account needs at least one rule that matches every operation it performs.

### Multi-field rule edits are not atomic — sequencing

There is no batch "update rule" call. A logical edit that touches several fields (rename + add signers + remove signers + add/remove/modify policies + expiry) is N SEPARATE submissions with partial-failure semantics: if submission 3 fails, submissions 1–2 already landed on chain.

**Critical: adding a signer changes the rule's authorization context — you cannot continue a mixed edit in the same pass.** Once an `add_signer` lands, the rule's signer set is different, and any FURTHER policy/expiry/name operation prepared against the pre-add snapshot is rejected by the contract (the auth context no longer matches). There is no typed SDK error for this.

Two ways to stay safe: either run the signer-adds, then STOP and re-fetch the rule fresh from chain (`listContextRules()` / `getContextRule(id:)`) before applying the remaining policy/expiry/name changes as a SEPARATE follow-up pass; or keep everything in one pass and order every policy/expiry/name operation FIRST with the signer-adds LAST, so nothing follows an `add_signer`. Any operation that consumes the rule SCVal (e.g. `set_threshold`, see [Changing only a threshold](#changing-only-a-threshold--set_threshold-fast-path)) must be prepared against the post-add rule state.

```swift
// WRONG: add a signer, then in the same pass install a policy against the stale rule
_ = try await kit.signerManager.addDelegated(contextRuleId: 1, address: g)
_ = try await kit.policyManager.addPolicy(contextRuleId: 1, policyAddress: p, installParams: params)  // rejected: auth context changed
// CORRECT (one pass): do the policy first, add the signer last
_ = try await kit.policyManager.addPolicy(contextRuleId: 1, policyAddress: p, installParams: params)
_ = try await kit.signerManager.addDelegated(contextRuleId: 1, address: g)
```

For signer ROTATION specifically, the ordering is add-new THEN remove-old (never the reverse, and never drop below the minimum signer set) — see [Signer rotation](#signer-rotation-add-new-then-remove-old).

---

## Policies

`kit.policyManager` (`OZPolicyManager`) installs and removes policies on a context rule. A policy is a separate, already-deployed Soroban contract; one deployment serves every smart account on the network. You supply the policy `C-address` and per-account install parameters. A rule may carry up to `OZConstants.maxPolicies` (5) policies, and every attached policy must be satisfied.

All state-changing methods take `selectedSigners: [OZSelectedSigner] = []` and `forceMethod: OZSubmissionMethod? = nil`.

### Which install path to use

**Production idiom: build the install-param `SCValXDR` once, feed it to BOTH paths.** Hand-build the install-param map once (see shapes below) and reuse the SAME value at create time via `addContextRule(policies: [addr: value])` and at edit time via `addPolicy(installParams: value)`. This is the path that covers every policy (built-in and custom) and keeps create/edit encoding identical. The convenience methods (`addSimpleThreshold` / `addWeightedThreshold` / `addSpendingLimit`) are a SHORTCUT for attaching a built-in policy to an already-existing rule — they cannot create a rule and are not needed once you build the param value yourself.

| Goal | Method | Notes |
|------|--------|-------|
| Create a rule WITH a policy in ONE submission | `addContextRule(policies: [policyAddress: installParamsScVal])` | You build the install-param `SCValXDR` yourself. The convenience methods CANNOT do this. |
| Install a policy on an ALREADY-EXISTING rule | `addPolicy(installParams:)` (generic) | Same hand-built `SCValXDR`. Works for any policy. The primary edit-time path. |
| Shortcut: built-in policy on an EXISTING rule | `addSimpleThreshold` / `addWeightedThreshold` / `addSpendingLimit` | Encode the install params for you. Post-hoc on an existing rule ONLY; cannot reuse one value across create+edit. |

```swift
// WRONG: trying to create a rule with a policy via a convenience method
//   — addSimpleThreshold/addWeightedThreshold/addSpendingLimit only attach to an
//     existing rule; they cannot create the rule. There is no addContextRule
//     variant that takes an OZPolicyInstallParams.
// CORRECT: build the install-param SCVal yourself and pass it in the
//   addContextRule(policies:) map (one submission), OR addContextRule first then
//   a convenience method (two submissions).
```

The `addContextRule(policies:)` value and `addPolicy(installParams:)` argument are both a raw install-param `SCValXDR`. `OZPolicyInstallParams.toScVal()` is `internal` (see [OZPolicyInstallParams](#ozpolicyinstallparams-encoder-is-internal)), so for `addContextRule` you build the `SCValXDR` directly. The install-param map shapes (inner keys ascending by symbol):

```
SimpleThreshold     ->  map{ Symbol("threshold"): U32 }
WeightedThreshold   ->  map{ Symbol("signer_weights"): map{ <signerScVal>: U32, ... },
                             Symbol("threshold"): U32 }          // inner map XDR-key sorted
SpendingLimit       ->  map{ Symbol("period_ledgers"): U32,
                             Symbol("spending_limit"): I128 }    // i128 in BASE UNITS
```

Build a SimpleThreshold install-param map and use it on either path:

```swift
// One SCVal, two uses.
let simpleThresholdParams = SCValXDR.map([
    SCMapEntryXDR(key: .symbol("threshold"), val: .u32(2))   // 2-of-N
])

// (a) create a rule WITH the policy in one submission:
let signer = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
_ = try await kit.contextRuleManagerConcrete.addContextRule(
    contextType: .callContract(contractAddress: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"),
    name: "Governance2of3",
    signers: [signer],
    policies: ["CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA": simpleThresholdParams]
)

// (b) or install on an existing rule via the generic method:
_ = try await kit.policyManager.addPolicy(
    contextRuleId: 0,
    policyAddress: "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    installParams: simpleThresholdParams
)
```

For a SpendingLimit built inline, the `spending_limit` I128 is in the token's base units (interpreted with 7 decimal places), not a decimal string (the `addSpendingLimit` convenience method is the only one that accepts a decimal string and multiplies for you). For the hand-built map, see the SpendingLimit example under [addContextRule](#addcontextrule).

### Finding policy contract addresses

A deployed policy contract is required before installation. Sources, in order of preference:

1. **Published OpenZeppelin addresses** — the release notes / README of the OpenZeppelin Stellar contracts repository list canonical testnet/mainnet `C-addresses` for the Simple Threshold, Weighted Threshold, and Spending Limit policies.
2. **Deploy your own** — build the relevant policy package and deploy it with the Stellar CLI to obtain a fresh `C-address`. Required for custom policies.

Cross-reference the address against the network you target: using a testnet address on mainnet (or vice versa) fails with contract-not-found during simulation.

```swift
// WRONG: hand-editing a real C-address to "look fake" by swapping in digits
//   "C...0..." / "C...1..." / "C...8..." / "C...9..."
//   — contract addresses use base32 alphabet A-Z + 2-7 only; 0/1/8/9 are NOT
//     in the alphabet, so the strkey fails to decode and the call throws
//     SmartAccountValidationException.InvalidAddress (or a silent contract-not-found).
// CORRECT: use a real deployed policy C-address, or synthesise placeholders
//   from the legal alphabet A-Z and 2-7 only.
```

### addSimpleThreshold — M-of-N

All signers on the rule carry equal weight; `threshold` is the minimum count required.

```swift
public func addSimpleThreshold(
    contextRuleId: UInt32,
    policyAddress: String,                 // C-address of the SimpleThreshold policy
    threshold: UInt32,                     // > 0
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
// 2-of-3 multisig on the Default rule
let result = try await kit.policyManager.addSimpleThreshold(
    contextRuleId: 0,
    policyAddress: "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    threshold: 2
)
```

```swift
// WRONG: 0 (rejected client-side, SmartAccountValidationException.InvalidInput); > rule.signers.count (on-chain 3201 InvalidThreshold)
// CORRECT: 1 <= threshold <= rule.signers.count
```

### addWeightedThreshold — weighted voting

Each signer has a weight; the sum of approving weights must be `>= threshold`. Signer identity is compared by SCVal bytes, so each `OZSignerWeightEntry.signer` must match exactly what is stored on the rule.

```swift
public func addWeightedThreshold(
    contextRuleId: UInt32,
    policyAddress: String,
    signerWeights: [OZSignerWeightEntry],    // non-empty
    threshold: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult

public struct OZSignerWeightEntry: Sendable {
    public let signer: any OZSmartAccountSigner
    public let weight: UInt32               // > 0
    public init(signer: any OZSmartAccountSigner, weight: UInt32)
}
```

```swift
let admin = try OZDelegatedSigner(address: "GAADMINAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
let lead  = try OZDelegatedSigner(address: "GALEADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
let dev   = try OZDelegatedSigner(address: "GADEVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

let result = try await kit.policyManager.addWeightedThreshold(
    contextRuleId: 1,
    policyAddress: "CWEIGHTEDTHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    signerWeights: [
        OZSignerWeightEntry(signer: admin, weight: 50),
        OZSignerWeightEntry(signer: lead,  weight: 30),
        OZSignerWeightEntry(signer: dev,   weight: 20)
    ],
    threshold: 80    // admin+lead passes; admin+dev passes; lead+dev does NOT
)
```

```swift
// WRONG: an OZSignerWeightEntry.signer that is not also on the rule's signers list
//   — even if weights sum to threshold, that signer cannot sign and the policy
//     cannot pass. Add the signer to the rule first (addDelegated / addPasskey),
//     or include it in the rule's signers at creation time.
// CORRECT: every weighted signer is also on the rule
// WRONG: weight = 0   — a zero-weight signer is rejected by the contract
// CORRECT: weight > 0
// WRONG: threshold > sum of weights   — rule is unsatisfiable
// CORRECT: threshold <= sum of all weights (usually strictly less)
```

### addSpendingLimit — rolling rate limit

Caps the cumulative amount transferred under the rule's context within a rolling window measured in ledgers. The policy intercepts any invocation of a function named `transfer` (the third argument is read as the `i128` amount), so it applies to any SEP-41 token contract.

```swift
public func addSpendingLimit(
    contextRuleId: UInt32,
    policyAddress: String,
    spendingLimit: String,                 // decimal XLM-style string, e.g. "1000" or "10.5"
    periodLedgers: UInt32,                  // window in ledgers (~5 s each)
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

Ledger-count constants (no week constant — compute it):

```swift
StellarProtocolConstants.ledgersPerHour   // 720
StellarProtocolConstants.ledgersPerDay    // 17_280
let weekLedgers = UInt32(7 * StellarProtocolConstants.ledgersPerDay)
```

Example — limit the account to 1000 XLM per day when calling the native XLM SAC:

```swift
let nativeSac = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

// 1. Create a callContract rule that scopes the policy to the native XLM SAC.
let signer = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
_ = try await kit.contextRuleManagerConcrete.addContextRule(
    contextType: .callContract(contractAddress: nativeSac),
    name: "XlmDailyLimit",
    signers: [signer]
)

// 2. Install the spending-limit policy on that rule.
let rules  = try await kit.contextRuleManagerConcrete.listContextRules()
let ruleId = rules.last { $0.contextType == .callContract(contractAddress: nativeSac) }!.id
_ = try await kit.policyManager.addSpendingLimit(
    contextRuleId: ruleId,
    policyAddress: "CSPENDINGLIMITPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    spendingLimit: "1000",
    periodLedgers: UInt32(StellarProtocolConstants.ledgersPerDay)
)
```

```swift
// WRONG: spendingLimit = "10000000000"   — interpreted as 10 billion tokens (decimal string!)
// CORRECT: spendingLimit = "1000"        — SDK converts to base units internally
// WRONG: spendingLimit = 1000.0          — the parameter is a String, not a Double
// CORRECT: spendingLimit = "1000"
// WRONG: periodLedgers = 86400           — ~5 days at 5 s/ledger
// CORRECT: periodLedgers = UInt32(StellarProtocolConstants.ledgersPerDay)  // 17280
// WRONG: installing SpendingLimit on a Default rule
//   -> rejects non-callContract contexts: error 3227 OnlyCallContractAllowed
// CORRECT: install on a callContract(target-token-SAC) rule
```

`addSpendingLimit` converts the decimal amount to an integer base-units string (interpreted with 7 decimal places) and encodes it via `SCValXDR.i128(stringValue:)`. To build the install params by hand instead, construct the `SCValXDR` map shown above — `period_ledgers` as a `U32` and `spending_limit` as an `I128` via `SCValXDR.i128(stringValue:)` (a base-units-denominated decimal-integer string) — and pass it to the generic `addPolicy(installParams:)`.

### addPolicy — generic

For any custom policy contract, or for install parameters not covered by the three wrappers.

```swift
public func addPolicy(
    contextRuleId: UInt32,
    policyAddress: String,
    installParams: SCValXDR,               // policy-specific SCVal map
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
// Custom "allowlist" policy that accepts a list of permitted contracts.
let installParams = SCValXDR.map([
    SCMapEntryXDR(
        key: .symbol("allowed_contracts"),
        val: .vec([
            .address(try SCAddressXDR(contractId: "CALLOWEDONECONTRACTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")),
            .address(try SCAddressXDR(contractId: "CALLOWEDTWOCONTRACTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))
        ])
    ),
    SCMapEntryXDR(key: .symbol("max_per_tx"), val: .u32(10))
])

_ = try await kit.policyManager.addPolicy(
    contextRuleId: 0,
    policyAddress: "CCUSTOMALLOWLISTPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    installParams: installParams
)
```

Inner map keys must be ordered by their XDR-byte encoding (lexicographic by symbol). The SDK sorts the top-level `policies` map for you; the inner install-params map you build is your responsibility. Use `OZPolicyManager.sortMapByKeyXdr(_:)` if you assemble entries dynamically:

```swift
public static func sortMapByKeyXdr(_ entries: [SCMapEntryXDR]) -> [SCMapEntryXDR]
```

### OZPolicyInstallParams (encoder is internal)

`OZPolicyInstallParams` is a public enum, but its `toScVal()` encoder is `internal` — consumers cannot call it. The three convenience methods (`addSimpleThreshold`, `addWeightedThreshold`, `addSpendingLimit`) build and encode the matching `OZPolicyInstallParams` value for you.

```swift
public enum OZPolicyInstallParams: Sendable {
    case simpleThreshold(threshold: UInt32)
    case weightedThreshold(signerWeights: [OZSignerWeightEntry], threshold: UInt32)
    case spendingLimit(spendingLimit: String, periodLedgers: UInt32)
}
```

```swift
// WRONG: kit.policyManager.addPolicy(installParams: OZPolicyInstallParams.simpleThreshold(threshold: 2))
//   — addPolicy takes an SCValXDR, not an OZPolicyInstallParams; toScVal() is internal.
// CORRECT: kit.policyManager.addSimpleThreshold(contextRuleId: 0, policyAddress: "...", threshold: 2)
//   or build the SCValXDR yourself and call addPolicy(installParams:).
```

### removePolicy — by id

Policy ids are assigned by the contract on install and align positionally with `OZParsedContextRule.policies`.

```swift
public func removePolicy(
    contextRuleId: UInt32,
    policyId: UInt32,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
let rule = try await kit.contextRuleManagerConcrete.listContextRules().first { $0.id == 0 }!
if let policyId = rule.policyIds.first {
    _ = try await kit.policyManager.removePolicy(contextRuleId: 0, policyId: policyId)
}
```

### removePolicyByAddress — by address

Distinct method name keeps the call site self-documenting versus the id-based `removePolicy(...)`. Resolves the numeric id internally with one extra RPC round trip (fetches and parses the rule, locates the policy within `policies`), then delegates to `removePolicy(...)`.

```swift
public func removePolicyByAddress(
    contextRuleId: UInt32,
    policyAddress: String,
    selectedSigners: [OZSelectedSigner] = [],
    forceMethod: OZSubmissionMethod? = nil
) async throws -> OZTransactionResult
```

```swift
_ = try await kit.policyManager.removePolicyByAddress(
    contextRuleId: 0,
    policyAddress: "CSPENDINGLIMITPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
)
```

Throws `SmartAccountValidationException` when the policy is not on the rule.

### Changing only a threshold — set_threshold fast path

Changing ONLY the threshold of an already-installed Simple or Weighted threshold policy does NOT require remove + re-add. Call the policy contract's `set_threshold` directly through the smart account.

**Inverse rule — every OTHER policy param change is remove + re-add.** There is NO in-place "update policy params" call. To change a SpendingLimit's limit/period, a WeightedThreshold's weights, or any custom policy's params, you MUST `removePolicy(...)` (or `removePolicyByAddress(...)`) then re-install with the new install-param `SCValXDR` — two submissions, with the policy absent between them. Only the bare `threshold` field of Simple/Weighted has the `set_threshold` fast path. The on-chain function is `set_threshold(threshold: u32, context_rule: ContextRule, smart_account: Address)`; the arg vector is `[.u32(newThreshold), <freshRuleScVal>, <smartAccountAddressScVal>]` in that order.

**Critical: re-fetch the rule immediately before the call.** The contract validates `newThreshold <= context_rule.signers.len()` against the `ContextRule` you pass in. A stale snapshot (signers changed since you read it) is rejected with `InvalidThreshold` (3201 simple / 3211 weighted). Always read it via `getContextRule(id:)` right before submitting.

```swift
let policyAddress = "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
let newThreshold: UInt32 = 3

// Re-fetch the raw rule SCVal immediately before the call — getContextRule(id:)
// returns a raw SCValXDR (the on-chain ContextRule encoded), exactly what
// set_threshold expects.
let freshRule = try await kit.contextRuleManagerConcrete.getContextRule(id: 1)
let smartAccount = SCValXDR.address(try SCAddressXDR(contractId: kit.contractId!))

// Single-signer (connected passkey authorizes):
_ = try await kit.transactionOperations.executeAndSubmit(
    target: policyAddress,
    targetFn: "set_threshold",
    targetArgs: [.u32(newThreshold), freshRule, smartAccount]
)

// Multi-signer (rule requires threshold > 1):
_ = try await kit.multiSignerManager.multiSignerExecuteAndSubmit(
    target: policyAddress,
    targetFn: "set_threshold",
    targetArgs: [.u32(newThreshold), freshRule, smartAccount],
    selectedSigners: selectedSigners
)
```

```swift
// WRONG: removePolicyByAddress + addSimpleThreshold just to change the number
//   — two submissions, drops the policy state between them.
// CORRECT: one set_threshold call via executeAndSubmit / multiSignerExecuteAndSubmit.
// WRONG: passing a rule SCVal cached from an earlier listContextRules()
//   — if signers changed, set_threshold rejects with InvalidThreshold.
// CORRECT: getContextRule(id:) immediately before the call.
```

---

## Multi-Signer Operations

`kit.multiSignerManager` (`OZMultiSignerManager`) coordinates a transaction across more than one signer — multiple passkeys, one or more external wallets, Ed25519 external signers, or a mix. Use it when a rule requires a threshold `> 1`, or to collect signatures from separate devices/users.

### When to use which entry point

- **Any state-changing manager method with a non-empty `selectedSigners`** — signer/policy/context-rule edits routed through the multi-signer pipeline.
- **`multiSignerTransfer`** — SEP-41 `transfer` on a token contract, authorized by multiple signers.
- **`multiSignerContractCall`** — arbitrary contract call authorized directly under a `callContract(target)` rule.
- **`multiSignerExecuteAndSubmit`** — arbitrary contract call routed through the smart account's own `execute(target, target_fn, target_args)` entry point; the target contract sees the smart account as the invoker.

### OZSelectedSigner

Explicitly list every signer that will sign. There is no implicit "connected passkey" — include it if it should sign.

```swift
public enum OZSelectedSigner: Sendable, Hashable {
    case passkey(
        credentialId: String,             // Base64URL credential id
        credentialIdBytes: Data? = nil,   // raw bytes -> WebAuthnAllowCredential hint
        keyData: Data? = nil,             // 65-byte pubkey || credentialId
        transports: [String]? = nil       // e.g. ["internal", "hybrid"]
    )
    case wallet(accountId: String)        // G-address
    case ed25519(verifierAddress: String, publicKey: Data)   // 32-byte Ed25519 key
}
```

The `ed25519` arm is handled end-to-end: the pipeline validates the signing source via `kit.externalSigners.canSignEd25519For(verifierAddress:publicKey:)` and signs via `kit.externalSigners.signEd25519AuthDigest(...)`. It carries no signing material — register the key separately (see [External wallet and custody requirements](#external-wallet-and-custody-requirements)).

Collection semantics: signatures are collected sequentially in the order supplied. Each `passkey` triggers exactly one OS WebAuthn prompt; each `wallet` triggers one external-wallet signing request; each `ed25519` signs through `kit.externalSigners`. Sequential collection enables fail-fast on user cancellation.

> **keyData non-nil rule.** Routing is by emptiness only: `selectedSigners: []` runs the single-signer path (connected passkey, one prompt); ANY non-empty list routes through the multi-signer pipeline — including a one-element list holding only the connected passkey, which does NOT collapse back to the fast path. In a multi-signer ceremony every `passkey` selector MUST carry non-`nil` `keyData`: the pipeline reconstructs external signers once per call (not per entry), so a `nil`-keyData passkey entry fails at runtime even when the credential is otherwise valid.

```swift
// Always supply keyData from the on-chain signer record for a multi-signer passkey.
let good = OZSelectedSigner.passkey(
    credentialId: savedCredId,                            // Base64URL
    credentialIdBytes: try Data(base64URLEncoded: savedCredId),  // optional routing hint (throwing init)
    keyData: passkeyKeyData,                              // from (signer as? OZExternalSigner)?.keyData
    transports: savedCredential.transports                // nil is fine
)
```

### Building OZSelectedSigner lists from on-chain rules

Read `OZParsedContextRule.signers` and map each on-chain signer to the matching `OZSelectedSigner` case. Discriminate by concrete type and, for `OZExternalSigner`, by `keyData.count` against the live constants (never hard-code 65/32): `> secp256r1PublicKeySize` (65) is a passkey (keyData is `pubkey || credentialId`); `== ed25519PublicKeySize` (32) is an Ed25519 key. A passkey's `keyData` MUST be passed non-nil; recover its credential id with `OZSmartAccountBuilders.getCredentialIdStringFromSigner` / `getCredentialIdFromSigner` and its `transports` via `kit.credentialManagerConcrete.getCredential(credentialId:)?.transports`.

```swift
let rule = try await kit.contextRuleManagerConcrete
    .listContextRules()
    .first { $0.id == contextRuleId }!

var selected: [OZSelectedSigner] = []
for signer in rule.signers {
    if let ext = signer as? OZExternalSigner {
        if ext.keyData.count == SmartAccountConstants.ed25519PublicKeySize {
            // Ed25519 external signer (keyData is the raw 32-byte key).
            if await kit.externalSigners.canSignEd25519For(
                verifierAddress: ext.verifierAddress,
                publicKey: ext.keyData
            ) {
                selected.append(.ed25519(verifierAddress: ext.verifierAddress, publicKey: ext.keyData))
            }
        } else if ext.keyData.count > SmartAccountConstants.secp256r1PublicKeySize {
            // WebAuthn passkey (keyData = 65-byte pubkey || credentialId).
            guard
                let credIdBytes = OZSmartAccountBuilders.getCredentialIdFromSigner(signer: signer),
                let credIdStr   = OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer)
            else { continue }
            let stored = try await kit.credentialManagerConcrete.getCredential(credentialId: credIdStr)
            selected.append(.passkey(
                credentialId: credIdStr,
                credentialIdBytes: credIdBytes,
                keyData: ext.keyData,               // non-nil, as required
                transports: stored?.transports
            ))
        }
        // any other keyData length: generic external verifier, no local signer; skip.
    } else if let delegated = signer as? OZDelegatedSigner {
        if await kit.externalSigners.canSignFor(address: delegated.address) {
            selected.append(.wallet(accountId: delegated.address))
        }
    }
}
```

### multiSignerTransfer

```swift
public func multiSignerTransfer(
    tokenContract: String,
    recipient: String,
    amount: String,                       // decimal string, NOT base units
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

Example — a 2-of-2 transfer with the connected passkey plus an external wallet:

```swift
let passkey = OZSelectedSigner.passkey(
    credentialId: kit.credentialId!,
    credentialIdBytes: try Data(base64URLEncoded: kit.credentialId!), // raw bytes of the connected credential
    keyData: passkeyKeyData       // non-nil; reach via `signer as? OZExternalSigner`.keyData (see cast above)
)
let wallet = OZSelectedSigner.wallet(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")

let result = try await kit.multiSignerManager.multiSignerTransfer(
    tokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
    recipient: "GBRECIPIENTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    amount: "100",
    selectedSigners: [passkey, wallet]
)
if result.success { print("Multi-sig transfer ok: \(result.hash ?? "n/a")") }
```

### multiSignerContractCall

Direct call to an external contract, authorized under a `callContract(target)` rule.

```swift
public func multiSignerContractCall(
    target: String,                       // C-address
    targetFn: String,
    targetArgs: [SCValXDR] = [],
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

```swift
// approve(from, spender, amount, expiration_ledger) on a SEP-41 token.
// amount is in the token's base units: 100 XLM == 100 * stroopsPerXlm for a 7-decimal token.
let amountBaseUnits = String(100 * StellarProtocolConstants.stroopsPerXlm)
// expiration_ledger (4th arg) is an ABSOLUTE ledger and must be in the future: read the
// current ledger via a consumer-owned SorobanServer on the kit's RPC, then add the lifetime.
let server = SorobanServer(endpoint: kit.config.rpcUrl)
guard case .success(let latest) = await server.getLatestLedger() else {
    throw SmartAccountTransactionException.simulationFailed(reason: "could not read latest ledger")
}
let expirationLedger = latest.sequence + UInt32(StellarProtocolConstants.ledgersPerHour)
let args: [SCValXDR] = [
    .address(try SCAddressXDR(contractId: kit.contractId!)),
    .address(try SCAddressXDR(contractId: "CDEXCONTRACTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")),
    try SCValXDR.i128(stringValue: amountBaseUnits),
    .u32(expirationLedger)
]
_ = try await kit.multiSignerManager.multiSignerContractCall(
    target: "CTOKENCONTRACTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    targetFn: "approve",
    targetArgs: args,
    selectedSigners: [passkey, wallet]
)
```

### multiSignerExecuteAndSubmit

Routes the call through the smart account's `execute(target, target_fn, target_args)` entry point. The target sees `kit.contractId` as the `require_auth` caller, not the underlying signers. Use it for governance votes, multi-sig swaps, or any operation gated by a multi-signer rule on the smart-account side.

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

```swift
// Governance vote authorized by two wallet signers
let result = try await kit.multiSignerManager.multiSignerExecuteAndSubmit(
    target: "CDAOCONTRACTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    targetFn: "vote",
    targetArgs: [.u32(proposalId), .bool(true)],
    selectedSigners: [
        .wallet(accountId: "GAVOTERONEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
        .wallet(accountId: "GAVOTERTWOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
    ]
)
```

### submitWithMultipleSigners (low-level)

Shared pipeline behind the three entry points: validates the signer set, simulates to discover auth entries, signs each entry with every supplied signer, re-simulates, and submits. Use it directly only for a host function the higher-level methods do not cover.

```swift
public func submitWithMultipleSigners(
    hostFunction: HostFunctionXDR,
    selectedSigners: [OZSelectedSigner],
    forceMethod: OZSubmissionMethod? = nil,
    resolveContextRuleIds: OZResolveContextRuleIds? = nil
) async throws -> OZTransactionResult
```

### OZResolveContextRuleIds (advanced)

```swift
public typealias OZResolveContextRuleIds = @Sendable (
    _ entry: SorobanAuthorizationEntryXDR,
    _ index: Int
) async throws -> [UInt32]
```

The pipeline picks which rule ids each auth entry should invoke automatically, using `OZContextRuleManager.resolveContextRuleIdsForEntry(...)`. Supply this callback when auto-resolution is ambiguous or to force a specific choice.

```swift
// Force every auth entry to use rule 2
let forceRule2: OZResolveContextRuleIds = { _, _ in [2] }
_ = try await kit.multiSignerManager.multiSignerTransfer(
    tokenContract: tokenSac,
    recipient: recipient,
    amount: "10",
    selectedSigners: signers,
    resolveContextRuleIds: forceRule2
)
```

When auto-resolution cannot find a unique rule it throws `SmartAccountValidationException.InvalidInput`, typically with one of: no rule matches the context type (add a matching rule or a Default), the selected signers match multiple rules (disambiguate with `resolveContextRuleIds`), or no single rule contains every selected signer (restrict the selection to one rule's signers or pass `resolveContextRuleIds`).

### External wallet and custody requirements

`OZSelectedSigner.wallet` and `OZSelectedSigner.ed25519` signers resolve through the kit-owned `kit.externalSigners` (`OZExternalSignerManager`, a non-optional actor). Two custody models per signer kind:

| Signer | In-memory (runtime) | Adapter (kit construction) |
|--------|---------------------|----------------------------|
| Wallet (`G…`) | `await kit.externalSigners.addFromSecret(secretKey: "S...")` | `config.externalWallet: OZExternalWalletAdapter` |
| Ed25519 | `try await kit.externalSigners.addEd25519FromRawKey(secretKeyBytes:verifierAddress:)` (synchronous on the actor, call with `await`; returns the 32-byte public key) | `config.externalEd25519Adapter: OZExternalEd25519SignerAdapter` |

```swift
// Register an in-memory wallet keypair (resolution tries in-memory first, then adapter).
let g = try await kit.externalSigners.addFromSecret(secretKey: "S...")   // async, returns G-address

// Register an Ed25519 signing key in memory; use the returned key in the selector.
let ed25519Verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
let edPublicKey = try await kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSeed32,            // exactly 32 bytes
    verifierAddress: ed25519Verifier
)
let edSigner = OZSelectedSigner.ed25519(verifierAddress: ed25519Verifier, publicKey: edPublicKey)
```

A wallet adapter (`config.externalWallet`) receives the Base64-encoded `HashIDPreimage::SorobanAuthorization` XDR, SHA-256-hashes it, Ed25519-signs it, and returns the 64-byte signature; the SDK assembles the signed auth entry.

If a passkey signer cancels its biometric prompt, the call fails fast (`WebAuthnException.Cancelled`); remaining signers are not prompted.

---

## Common Scenarios

Three end-to-end flows. Each assumes `kit` exists and `kit.walletOperations.connectWallet(...)` returned `.connected`.

### Passkey recovery via backup signer (lost device)

**Preconditions.** A backup `OZDelegatedSigner(G-address)` was added earlier to the Default rule, and the user still controls the corresponding Stellar account (in-memory secret or `config.externalWallet`). The original passkey is gone. The contract id is known from out-of-band storage. The old credential id is retrievable so the old passkey can be removed.

**Flow.** Register a fresh passkey on the new device, direct-connect to the known contract, add the new passkey on-chain authorized by the backup signer, then remove the old passkey.

```swift
// Recoverable out-of-band:
let knownContractId: String = /* verified contract id */ ""
let oldCredentialIdBase64Url: String = /* old passkey credential id */ ""

// 1. Register a fresh passkey on the new device. Draw 32 random bytes each for
//    the challenge and the user id from the system CSPRNG.
func randomBytes(_ count: Int) -> Data {
    var bytes = [UInt8](repeating: 0, count: count)
    _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    return Data(bytes)
}
let challenge = randomBytes(32)
let userId    = randomBytes(32)
guard let provider = kit.config.webauthnProvider else {
    throw WebAuthnException.notSupported(details: "webauthnProvider required for recovery")
}
let reg = try await provider.register(challenge: challenge, userId: userId, userName: "Recovery Device")
let newCredBytes = reg.credentialId

// 2. Direct-connect using the known (credentialId, contractId) pair. Verify
//    knownContractId against independent channels (deterministic derivation +
//    indexer) BEFORE this step — a fake contractId adds the fresh passkey to an
//    attacker's contract.
let connected = try await kit.walletOperations.connectWallet(
    options: OZConnectWalletOptions(
        credentialId: reg.credentialId.base64URLEncodedString(),
        contractId: knownContractId
    )
)
guard case .connected? = connected else {   // connectWallet returns OZConnectWalletResult?
    throw SmartAccountWalletException.notFound(identifier: knownContractId)
}

// 3. The backup signer (delegated G-address held by the user's external wallet).
let backup = OZSelectedSigner.wallet(accountId: "GBACKUPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

// 4. Add the new passkey on-chain, authorized by the backup signer. The
//    non-empty selectedSigners is load-bearing: with [] the kit would try to
//    sign with the (non-existent) new passkey and fail simulation.
let addResult = try await kit.signerManager.addPasskey(
    contextRuleId: 0,
    publicKey: reg.publicKey,
    credentialId: newCredBytes,
    selectedSigners: [backup]
)
guard addResult.success else {
    throw SmartAccountTransactionException.submissionFailed(reason: addResult.error ?? "add_signer failed")
}

// 5. Remove the old passkey, also authorized by the backup signer.
let rule = try await kit.contextRuleManagerConcrete.listContextRules().first { $0.id == 0 }!
if let oldIdx = rule.signers.firstIndex(where: { signer in
    OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer) == oldCredentialIdBase64Url
}) {
    _ = try await kit.signerManager.removeSigner(
        contextRuleId: 0,
        signerId: rule.signerIds[oldIdx],
        selectedSigners: [backup]
    )
}
```

```swift
// WRONG: calling provider.authenticate on the new device to sign add_signer
//   — there is no stored credential for the lost passkey to answer the prompt.
// CORRECT: pass selectedSigners: [backup] so the multi-signer pipeline routes
//   auth to the backup signer through kit.externalSigners.
```

A raw-Ed25519 backup added via `addEd25519` uses the external-signer pipeline and is expressed as `OZSelectedSigner.ed25519(...)`, not `.wallet(...)`. To use the wallet path shown above, register the backup as a delegated `G-address`.

### Signer rotation (add new, then remove old)

**Preconditions.** Connected with the current passkey; moving to a new authenticator. The Default rule has one passkey signer and no policies. Always add first, never remove first.

```swift
// 1. Register and add the new passkey. The connected passkey authorizes (selectedSigners []).
let added = try await kit.signerManager.addNewPasskeySigner(
    contextRuleId: 0,
    userName: "User name on new device"
)
guard added.transactionResult.success else {
    throw SmartAccountTransactionException.submissionFailed(reason: added.transactionResult.error ?? "add_signer failed")
}
let newCredentialId = added.credentialId

// 2. Remember the old credential id BEFORE reconnecting.
guard let oldCredentialId = kit.credentialId else {
    throw SmartAccountWalletException.notConnected(details: "old session already lost")
}

// 3. Reconnect using the new passkey. addNewPasskeySigner already persisted the
//    new credential with the contract id, so connectWallet resolves it from
//    storage with no WebAuthn prompt.
_ = try await kit.walletOperations.connectWallet(
    options: OZConnectWalletOptions(credentialId: newCredentialId)
)

// 4. Remove the old passkey (the new passkey authorizes, selectedSigners []).
let rule = try await kit.contextRuleManagerConcrete.listContextRules().first { $0.id == 0 }!
guard let oldIdx = rule.signers.firstIndex(where: { signer in
    OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer) == oldCredentialId
}) else {
    throw SmartAccountValidationException.invalidInput(field: "signer", reason: "Old passkey not found on Default rule")
}
_ = try await kit.signerManager.removeSigner(contextRuleId: 0, signerId: rule.signerIds[oldIdx])
```

```swift
// WRONG: removeSigner(old) before addPasskey(new)  — the rule briefly has 0
//   signers and 0 policies; the contract rejects with 3004 NoSignersAndPolicies,
//   and a failure between two txs could brick the account.
// CORRECT: add the new passkey first, reconnect, then remove the old one.
```

### Debugging failed `__check_auth` via contract error codes

When a kit method throws `SmartAccountTransactionException.SimulationFailed`, the message wraps the RPC simulation error, which carries the host error code as `Error(Contract, #<code>)`. There is no typed contract-error exception — parse the code from the message and map it to an action. Do not switch on `e.code`: that is the SDK error kind (`transactionSimulationFailed`), not the on-chain contract code.

```swift
private let contractErrorRegex = try! NSRegularExpression(
    pattern: #"Error\s*\(\s*Contract\s*,\s*#(\d+)\s*\)"#
)

func parseContractErrorCode(_ error: Error) -> Int? {
    let message = (error as? SmartAccountException)?.message ?? "\(error)"
    let range = NSRange(message.startIndex..., in: message)
    if let m = contractErrorRegex.firstMatch(in: message, range: range),
       let r = Range(m.range(at: 1), in: message) {
        return Int(message[r])
    }
    return nil
}

do {
    _ = try await kit.transactionOperations.transfer(
        tokenContract: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
        recipient: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
        amount: "10"
    )
} catch let e as SmartAccountTransactionException.SimulationFailed {
    let code = parseContractErrorCode(e)
    let hint: String
    switch code {
    case 3004: hint = "NoSignersAndPolicies — rule would have 0 signers and 0 policies; add one first"
    case 3016: hint = "UnauthorizedSigner — signer not on the resolved rule; adjust selectedSigners or pass resolveContextRuleIds"
    case 3221: hint = "SpendingLimitExceeded for the current window; wait for reset or raise the limit"
    case nil:  hint = "No contract code in message: \(e.message)"
    default:   hint = "Contract error \(code!) — see Contract Error Codes below"
    }
    print("transfer rejected: \(hint)")
    if code == OZContractErrorCodes.unauthorizedSigner {   // 3016
        // re-resolve rule ids or adjust the selected-signer set
    }
}
```

`OZContractErrorCodes` provides named constants for five of the contract error codes — `mathOverflow` (3012), `keyDataTooLarge` (3013), `contextRuleIdsLengthMismatch` (3014), `nameTooLong` (3015), `unauthorizedSigner` (3016). The SDK does not parse or map contract error codes; extract the code from the exception message yourself (as shown above) and compare it against these constants or the reference tables below.

---

## Events

Signer, policy, and context-rule changes do not emit dedicated kit events; they surface as `OZSmartAccountEvent.transactionSubmitted(hash:success:)`. The kit-level event catalogue and subscription mechanics are documented in [smart_accounts.md — Events](./smart_accounts.md#events).

For on-chain contract events (`signer_added`, `policy_added`, etc.), query a consumer-owned `SorobanServer` (built on the same RPC URL passed to the kit config) with the account's contract id as the filter:

```swift
let server = SorobanServer(endpoint: kit.config.rpcUrl)
let filter = EventFilter(type: "contract", contractIds: [kit.contractId!])
let response = await server.getEvents(startLedger: fromLedger, eventFilters: [filter])
switch response {
case .success(let response):
    for event in response.events {
        // event.topic is a [String] (one base64-XDR SCVal per topic segment).
        // event.value is a single base64-XDR SCVal string; event.valueXdr is the
        // already-decoded SCValXDR.
    }
case .failure(let error):
    print("getEvents failed: \(error)")
}
```

---

## Contract Error Codes

When the smart-account contract rejects a call, the on-chain error code is surfaced inside `SmartAccountTransactionException.SimulationFailed` (simulation) or `SmartAccountTransactionException.SubmissionFailed` (submit/poll). Look for `Error(Contract, #<code>)` in the message.

> These on-chain codes overlap numerically with `SmartAccountErrorCode` but are a different channel — check the exception type first (see [Debugging failed `__check_auth`](#debugging-failed-__check_auth-via-contract-error-codes)).

### Smart account errors (3000 range)

| Code | Symbol | Meaning | Fix |
|------|--------|---------|-----|
| 3000 | ContextRuleNotFound | `contextRuleId` does not exist | Pass a valid id from `listContextRules()`. Ids are never reused. |
| 3002 | UnvalidatedContext | No rule matches this operation's context type | Add a `callContract` / `createContract` rule, or a Default rule. |
| 3003 | ExternalVerificationFailed | Verifier contract rejected the signature | Signature or key data is wrong, or the verifier was upgraded. |
| 3004 | NoSignersAndPolicies | Tried to create or reduce a rule to 0 signers and 0 policies | Supply at least one signer or one policy. |
| 3005 | PastValidUntil | `validUntil` is `<=` current ledger | Compute `validUntil` from a future ledger sequence. |
| 3006 | SignerNotFound | `signerId` not present on the rule | Use `OZParsedContextRule.signerIds`. |
| 3007 | DuplicateSigner | Signer already on the rule | Each signer (by `uniqueKey`) appears at most once per rule. |
| 3008 | PolicyNotFound | `policyId` not present on the rule | Use `OZParsedContextRule.policyIds`. |
| 3009 | DuplicatePolicy | Policy contract already installed on the rule | Remove the existing install first, or target a different rule. |
| 3010 | TooManySigners | More than 15 signers on a rule | Limit to `OZConstants.maxSigners` (15). |
| 3011 | TooManyPolicies | More than 5 policies on a rule | Limit to `OZConstants.maxPolicies` (5). |
| 3012 | MathOverflow | Internal id counter hit `u32::MAX` | Extremely rare; create a new account. |
| 3013 | KeyDataTooLarge | External signer `keyData` too large | secp256r1 pubkey (65) + credentialId must fit the contract limit. |
| 3014 | ContextRuleIdsLengthMismatch | Auth-assembly mismatch | Normally resolved by the auto-resolver; report with a reproduction. |
| 3015 | NameTooLong | Rule `name` > 20 UTF-8 bytes | Shorten the name. |
| 3016 | UnauthorizedSigner | A signer in the auth payload is not on the selected rule | Adjust `selectedSigners`, or pass `resolveContextRuleIds` to pick a rule that includes those signers. |

### SimpleThreshold policy errors (3200 range)

| Code | Symbol | Meaning |
|------|--------|---------|
| 3200 | SmartAccountNotInstalled | Policy uninstalled or never installed on this account |
| 3201 | InvalidThreshold | `threshold == 0` or `threshold > signer_count` |
| 3202 | NotAllowed | Signer count below threshold at enforcement time |
| 3203 | AlreadyInstalled | Policy already installed on this rule (remove first) |

### WeightedThreshold policy errors (3210 range)

| Code | Symbol | Meaning |
|------|--------|---------|
| 3210 | SmartAccountNotInstalled | Policy uninstalled or never installed |
| 3211 | InvalidThreshold | Threshold is 0 or greater than the sum of weights |
| 3212 | MathOverflow | Weight sum would overflow `u32` |
| 3213 | NotAllowed | Sum of signing signers' weights below threshold |
| 3214 | AlreadyInstalled | Policy already installed on this rule |

### SpendingLimit policy errors (3220 range)

| Code | Symbol | Meaning |
|------|--------|---------|
| 3220 | SmartAccountNotInstalled | Policy uninstalled or never installed |
| 3221 | SpendingLimitExceeded | Transfer would exceed the limit for the current window |
| 3222 | InvalidLimitOrPeriod | `spendingLimit <= 0` or `periodLedgers == 0` |
| 3223 | NotAllowed | Generic policy rejection at enforcement time |
| 3224 | HistoryCapacityExceeded | Transfer history exceeds the per-account/rule cap |
| 3225 | AlreadyInstalled | Policy already installed on this rule |
| 3226 | LessThanZero | `transfer` amount argument is negative |
| 3227 | OnlyCallContractAllowed | Policy installed on a Default or `createContract` rule; only `callContract` rules are supported |

### Handling pattern

```swift
do {
    let res = try await kit.policyManager.addSimpleThreshold(
        contextRuleId: 0,
        policyAddress: "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        threshold: 2
    )
    if !res.success { print("submit failed: \(res.error ?? "")") }
} catch let e as SmartAccountTransactionException.SimulationFailed {
    print("simulation failed (contract code in message): \(e.message)")
} catch let e as SmartAccountValidationException.InvalidInput {
    print("client-side validation: \(e.message)")
} catch let e as SmartAccountWalletException.NotConnected {
    print("call connectWallet() first: \(e.message)")
}
```

See also: the SDK error hierarchy in [smart_accounts.md — Error Handling](./smart_accounts.md#error-handling).
