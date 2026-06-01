# Context Rules, Policies, and Multi-Signer Operations

Signers, context rules, policies, and multi-signer ceremonies for an existing OpenZeppelin smart account — the dynamic authorization layer on top of the core API in [smart_accounts.md](./smart_accounts.md). Platform WebAuthn setup (entitlements, associated domains) lives in [smart_accounts_webauthn.md](./smart_accounts_webauthn.md).

Every example assumes the kit is already created and connected:

```swift
import stellarsdk

// `kit` is an OZSmartAccountKit created via OZSmartAccountKit.create(config:)
// and connected via kit.walletOperations.connectWallet(...). See smart_accounts.md.
let connected = try await kit.walletOperations.connectWallet()
guard case .connected = connected else {
    // show login UI; nothing below works without a live connection
    return
}
```

All state-changing methods are `async throws`. Read-only listing/parsing methods are `async throws`. Manager access is by property, never a function call.

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

**Single-passkey vs multi-signer.** Every state-changing manager method takes an optional `selectedSigners: [SelectedSigner]` parameter (default `[]`):

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

```swift
// WRONG: kit.signerManager()   — it is a property, not a function
// CORRECT: kit.signerManager    — property access
```

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

Every state-changing method below takes `selectedSigners: [SelectedSigner] = []` and `forceMethod: SubmissionMethod? = nil`.

### addNewPasskeySigner — register and add in one step

Runs a WebAuthn registration ceremony, persists the new credential as `pending` in storage, emits `SmartAccountEvent.credentialCreated`, then submits the on-chain `add_signer` call by delegating to `addPasskey(...)`. Requires `webauthnProvider` in config.

```swift
public func addNewPasskeySigner(
    contextRuleId: UInt32,
    userName: String,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> AddPasskeySignerResult

public struct AddPasskeySignerResult: Sendable, Hashable {
    public let credentialId: String          // Base64URL, unpadded
    public let publicKey: Data               // 65-byte uncompressed secp256r1
    public let transactionResult: TransactionResult
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

> **Transport authenticity — anyone who can inject bytes into the import channel can become a signer.** The `publicKey` and `credentialId` must arrive over a channel authenticated to the user; over any unauthenticated transport an attacker can substitute their own public key and become an authorized signer. Use a safe transport (verified in-app pairing code, OS Handoff/AirDrop, NFC, signed QR from a server you control) and show a short credential fingerprint on both devices first. A workable fingerprint is the first 16 bytes of `SHA-256(publicKey)` hex-encoded — do NOT use `publicKey[0..<16]`, because byte 0 is always the constant `0x04` SEC-1 prefix and contributes no entropy.

```swift
public func addPasskey(
    contextRuleId: UInt32,
    publicKey: Data,            // 65 bytes, first byte 0x04
    credentialId: Data,         // raw bytes, NOT Base64URL
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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

The signer authorizes through the host's built-in `require_auth`; no verifier contract is needed. An address that is neither a valid `G…` strkey nor a valid `C…` strkey throws `ValidationException.InvalidAddress`.

### addEd25519 — add an Ed25519 external signer

Requires a deployed Ed25519 verifier contract. `publicKey` is the raw 32-byte Ed25519 key.

```swift
public func addEd25519(
    contextRuleId: UInt32,
    verifierAddress: String,    // C-address of the Ed25519 verifier
    publicKey: Data,            // 32 bytes
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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

Signer ids are assigned by the contract on insertion and surface on `ParsedContextRule.signerIds`, positionally aligned with `ParsedContextRule.signers`.

```swift
public func removeSigner(
    contextRuleId: UInt32,
    signerId: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
// Remove a known delegated signer without fetching ids manually
let signer = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
_ = try await kit.signerManager.removeSignerBySigner(
    contextRuleId: 0,
    signer: signer
)
```

Throws `ValidationException.InvalidInput` when the signer is not on the rule, or `ConfigurationException.InvalidConfig` when the manager was constructed without a context-rule parser (a non-default kit composition).

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
OZSmartAccountBuilders.describeSignerType(signer: s)            // "Stellar Account" / "Passkey (WebAuthn)" / "Ed25519" / "External Verifier"
OZSmartAccountBuilders.getCredentialIdFromSigner(signer: s)     // Data?  (raw credential id, WebAuthn only)
OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: s) // String? (Base64URL credential id)
OZSmartAccountBuilders.signersEqual(a, b)                       // Bool
OZSmartAccountBuilders.getSignerKey(signer: s)                  // String (== signer.uniqueKey)
```

`describeSignerType` distinguishes the three `OZExternalSigner` shapes by `keyData.count`: `> 65` (secp256r1 pubkey 65 || credentialId) is WebAuthn; `== 32` is Ed25519; anything else is a generic external verifier.

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
var rulesByKey: [String: [ParsedContextRule]] = [:]
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

### ContextRuleType

```swift
public enum ContextRuleType: Sendable, Hashable {
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
// WRONG: ContextRuleType.callContract("CBCD...")
//   — the case has a labeled associated value
// CORRECT: ContextRuleType.callContract(contractAddress: "CBCD...")

// WRONG: ContextRuleType.createContract(wasmHash: "abcd...")   — that is a String, not Data
// CORRECT: ContextRuleType.createContract(wasmHash: wasmHashData)   // raw 32-byte Data
//   or use OZBuilders.createCreateContractContext(wasmHashHex:) to convert hex.
```

The `OZBuilders` static helpers wrap construction with validation:

```swift
let defaultCtx = OZBuilders.createDefaultContext()                                  // .defaultRule
let callCtx    = try OZBuilders.createCallContractContext(contractAddress: "CBCD...") // validates C-address
let createCtx1 = try OZBuilders.createCreateContractContext(wasmHashHex: "abc123...") // 64 hex chars, 0x prefix optional
let createCtx2 = try OZBuilders.createCreateContractContext(wasmHash: wasmHash32)      // Data, 32 bytes
```

### addContextRule

```swift
public func addContextRule(
    contextType: ContextRuleType,
    name: String,                          // metadata; non-empty
    validUntil: UInt32? = nil,             // Option<u32> ledger sequence; nil = non-expiring
    signers: [any OZSmartAccountSigner],
    policies: [String: SCValXDR] = [:],    // C-address -> install params
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

The `policies` map key is the policy contract address (`C…`); the value is the install-param `SCValXDR`. The SDK sorts the top-level `policies` map by XDR-byte key order before submission to satisfy Soroban's `ScMap` ordering invariant. This map is the ONLY way to create a rule WITH a policy in one submission — the convenience methods on `kit.policyManager` cannot create a rule. See [Which install path to use](#which-install-path-to-use) for the install-param map shapes.

Example — a rule scoped to a specific token contract, with two delegated signers and an inline spending-limit policy install map:

```swift
let signerA = try OZDelegatedSigner(address: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
let signerB = try OZDelegatedSigner(address: "GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL")

// SpendingLimit install params (inner keys ascending by symbol):
//   period_ledgers : u32, spending_limit : i128 (stroops)
let oneThousandXlmStroops = String(1000 * StellarProtocolConstants.stroopsPerXlm) // "10000000000"
let spendingLimitParams = SCValXDR.map([
    SCMapEntryXDR(key: .symbol("period_ledgers"),
                  val: .u32(UInt32(StellarProtocolConstants.ledgersPerDay))),  // 17280
    SCMapEntryXDR(key: .symbol("spending_limit"),
                  val: try SCValXDR.i128(stringValue: oneThousandXlmStroops))
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
//   -> ValidationException: a rule must have >= 1 signer OR >= 1 policy
// CORRECT: supply at least one signer or one policy
// WRONG: name longer than 20 UTF-8 bytes  -> contract error 3015 NameTooLong
// CORRECT: name <= 20 UTF-8 bytes
// WRONG: validUntil set to an already-past ledger  -> contract error 3005 PastValidUntil
// CORRECT: validUntil is a future ledger, or nil
```

### ParsedContextRule

```swift
public struct ParsedContextRule: Sendable, Hashable {
    public let id: UInt32
    public let contextType: ContextRuleType
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
public func listContextRules() async throws -> [ParsedContextRule]
public func listContextRules(maxScanId: UInt32? = nil) async throws -> [ParsedContextRule]
public func getAllContextRules() async throws -> [SCValXDR]
public func getAllContextRules(maxScanId: UInt32? = nil) async throws -> [SCValXDR]
public func getContextRule(id: UInt32) async throws -> SCValXDR
public func getContextRulesCount() async throws -> UInt32
```

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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
// Expire a rule in roughly one week. Read the current ledger from the kit-owned
// server; getLatestLedger() returns a Result-style enum, not a thrown value.
guard case .success(let latest) = await kit.sorobanServer.getLatestLedger() else {
    throw TransactionException.simulationFailed(reason: "could not read latest ledger")
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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
_ = try await kit.contextRuleManagerConcrete.removeContextRule(id: 3)
```

Do not remove rule `0` (Default) unless equivalent coverage already exists — the account needs at least one rule that matches every operation it performs.

### Multi-field rule edits are not atomic — sequencing

There is no batch "update rule" call. A logical edit that touches several fields (rename + add signers + remove signers + add/remove/modify policies + expiry) is N SEPARATE submissions with partial-failure semantics: if submission 3 fails, submissions 1–2 already landed on chain.

**Critical: adding a signer changes the rule's authorization context — you cannot continue a mixed edit in the same pass.** Once an `add_signer` lands, the rule's signer set is different, and any FURTHER policy/expiry/name operation prepared against the pre-add snapshot is rejected by the contract (the auth context no longer matches). There is no typed SDK error for this. Two ways to stay safe:

- **Preferred — HALT and RELOAD.** If a logical edit mixes signer-adds with policy/expiry/name changes, run the signer-adds, then STOP, re-fetch the rule fresh from chain (`listContextRules()` / `getContextRule(id:)`), and apply the remaining policy/expiry/name changes as a SEPARATE follow-up pass against the reloaded rule. Sequencing alone is not enough — the later operations must be prepared against the post-add rule state.
- **Or — order so no add precedes them.** If you keep everything in one pass, do every policy/expiry/name operation FIRST and the signer-adds LAST, so nothing follows an `add_signer`:

```
1. updateName / updateValidUntil
2. add/remove/modify policies
3. remove signers
4. add signers   <-- ALWAYS LAST; anything after this needs a fresh reload first
```

```swift
// WRONG: add a signer, then in the same pass install a policy against the stale rule
_ = try await kit.signerManager.addDelegated(contextRuleId: 1, address: g)
_ = try await kit.policyManager.addPolicy(contextRuleId: 1, policyAddress: p, installParams: params)  // rejected: auth context changed
// CORRECT (one pass): do the policy first, add the signer last
_ = try await kit.policyManager.addPolicy(contextRuleId: 1, policyAddress: p, installParams: params)
_ = try await kit.signerManager.addDelegated(contextRuleId: 1, address: g)
// CORRECT (mixed edit): after the add_signer, reload before continuing
_ = try await kit.signerManager.addDelegated(contextRuleId: 1, address: g)
let fresh = try await kit.contextRuleManagerConcrete.listContextRules().first { $0.id == 1 }!  // reload
_ = try await kit.policyManager.addPolicy(contextRuleId: fresh.id, policyAddress: p, installParams: params)
```

For signer ROTATION specifically, the ordering is add-new THEN remove-old (never the reverse, and never drop below the minimum signer set) — see [Signer rotation](#signer-rotation-add-new-then-remove-old).

---

## Policies

`kit.policyManager` (`OZPolicyManager`) installs and removes policies on a context rule. A policy is a separate, already-deployed Soroban contract; one deployment serves every smart account on the network. You supply the policy `C-address` and per-account install parameters. A rule may carry up to `OZConstants.maxPolicies` (5) policies, and every attached policy must be satisfied.

All state-changing methods take `selectedSigners: [SelectedSigner] = []` and `forceMethod: SubmissionMethod? = nil`.

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
//     variant that takes a PolicyInstallParams.
// CORRECT: build the install-param SCVal yourself and pass it in the
//   addContextRule(policies:) map (one submission), OR addContextRule first then
//   a convenience method (two submissions).
```

The `addContextRule(policies:)` value and `addPolicy(installParams:)` argument are both a raw install-param `SCValXDR`. `PolicyInstallParams.toScVal()` is `internal` (see [PolicyInstallParams](#policyinstallparams-encoder-is-internal)), so for `addContextRule` you build the `SCValXDR` directly. The install-param map shapes (inner keys ascending by symbol, see source `OZPolicyManager.swift` `PolicyInstallParams.toScVal()` ~line 171):

```
SimpleThreshold     ->  map{ Symbol("threshold"): U32 }
WeightedThreshold   ->  map{ Symbol("signer_weights"): map{ <signerScVal>: U32, ... },
                             Symbol("threshold"): U32 }          // inner map XDR-key sorted
SpendingLimit       ->  map{ Symbol("period_ledgers"): U32,
                             Symbol("spending_limit"): I128 }    // i128 in STROOPS
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
    policies: ["CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA": simpleThresholdParams]
)

// (b) or install on an existing rule via the generic method:
_ = try await kit.policyManager.addPolicy(
    contextRuleId: 0,
    policyAddress: "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    installParams: simpleThresholdParams
)
```

For SpendingLimit built inline, the `spending_limit` I128 is in STROOPS, not decimal XLM (the `addSpendingLimit` convenience method is the only one that accepts a decimal XLM string and multiplies for you):

```swift
let oneThousandXlmStroops = String(1000 * StellarProtocolConstants.stroopsPerXlm) // "10000000000"
let spendingLimitParams = SCValXDR.map([
    SCMapEntryXDR(key: .symbol("period_ledgers"),
                  val: .u32(UInt32(StellarProtocolConstants.ledgersPerDay))),      // 17280
    SCMapEntryXDR(key: .symbol("spending_limit"),
                  val: try SCValXDR.i128(stringValue: oneThousandXlmStroops))      // STROOPS
])
```

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
//     ValidationException.InvalidAddress (or a silent contract-not-found).
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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
// 2-of-3 multisig on the Default rule
let result = try await kit.policyManager.addSimpleThreshold(
    contextRuleId: 0,
    policyAddress: "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    threshold: 2
)
```

```swift
// WRONG: threshold = 0   -> contract error 3201 InvalidThreshold
// CORRECT: 1 <= threshold <= rule.signers.count
```

### addWeightedThreshold — weighted voting

Each signer has a weight; the sum of approving weights must be `>= threshold`. Signer identity is compared by SCVal bytes, so each `SignerWeightEntry.signer` must match exactly what is stored on the rule.

```swift
public func addWeightedThreshold(
    contextRuleId: UInt32,
    policyAddress: String,
    signerWeights: [SignerWeightEntry],    // non-empty
    threshold: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult

public struct SignerWeightEntry: Sendable {
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
        SignerWeightEntry(signer: admin, weight: 50),
        SignerWeightEntry(signer: lead,  weight: 30),
        SignerWeightEntry(signer: dev,   weight: 20)
    ],
    threshold: 80    // admin+lead passes; admin+dev passes; lead+dev does NOT
)
```

```swift
// WRONG: a SignerWeightEntry.signer that is not also on the rule's signers list
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
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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
// WRONG: spendingLimit = "10000000000"   — interpreted as 10 billion XLM (decimal string!)
// CORRECT: spendingLimit = "1000"        — SDK converts to stroops internally
// WRONG: spendingLimit = 1000.0          — the parameter is a String, not a Double
// CORRECT: spendingLimit = "1000"
// WRONG: periodLedgers = 86400           — ~5 days at 5 s/ledger
// CORRECT: periodLedgers = UInt32(StellarProtocolConstants.ledgersPerDay)  // 17280
// WRONG: installing SpendingLimit on a Default rule
//   -> rejects non-callContract contexts: error 3227 OnlyCallContractAllowed
// CORRECT: install on a callContract(target-token-SAC) rule
```

For an amount whose stroops value exceeds `Int64.max`, build the params directly through `PolicyInstallParams.spendingLimit(spendingLimit:periodLedgers:)` with a stroops-denominated decimal-integer string — but note its `toScVal()` is internal, so route it through the generic `addPolicy(...)` instead (see below).

### addPolicy — generic

For any custom policy contract, or for install parameters not covered by the three wrappers.

```swift
public func addPolicy(
    contextRuleId: UInt32,
    policyAddress: String,
    installParams: SCValXDR,               // policy-specific SCVal map
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
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

### PolicyInstallParams (encoder is internal)

`PolicyInstallParams` is a public enum, but its `toScVal()` encoder is `internal` — consumers cannot call it. The three convenience methods (`addSimpleThreshold`, `addWeightedThreshold`, `addSpendingLimit`) build and encode the matching `PolicyInstallParams` value for you.

```swift
public enum PolicyInstallParams: Sendable {
    case simpleThreshold(threshold: UInt32)
    case weightedThreshold(signerWeights: [SignerWeightEntry], threshold: UInt32)
    case spendingLimit(spendingLimit: String, periodLedgers: UInt32)
}
```

```swift
// WRONG: kit.policyManager.addPolicy(installParams: PolicyInstallParams.simpleThreshold(threshold: 2))
//   — addPolicy takes an SCValXDR, not a PolicyInstallParams; toScVal() is internal.
// CORRECT: kit.policyManager.addSimpleThreshold(contextRuleId: 0, policyAddress: "...", threshold: 2)
//   or build the SCValXDR yourself and call addPolicy(installParams:).
```

`OZSmartAccountBuilders.createThresholdParams(threshold:)`, `createWeightedThresholdParams(...)`, and `createSpendingLimitParams(...)` produce typed inspection-only param structs (`OZSimpleThresholdParams` etc.); they are not wired into `addPolicy` and exist only to diff/compare params locally.

### removePolicy — by id

Policy ids are assigned by the contract on install and align positionally with `ParsedContextRule.policies`.

```swift
public func removePolicy(
    contextRuleId: UInt32,
    policyId: UInt32,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
let rule = try await kit.contextRuleManagerConcrete.listContextRules().first { $0.id == 0 }!
if let policyId = rule.policyIds.first {
    _ = try await kit.policyManager.removePolicy(contextRuleId: 0, policyId: policyId)
}
```

### removePolicyByAddress — by address

Distinct method name (same overload-resolution reason as `removeSignerBySigner`). Resolves the numeric id internally with one extra RPC round trip (fetches and parses the rule, locates the policy within `policies`), then delegates to `removePolicy(...)`.

```swift
public func removePolicyByAddress(
    contextRuleId: UInt32,
    policyAddress: String,
    selectedSigners: [SelectedSigner] = [],
    forceMethod: SubmissionMethod? = nil
) async throws -> TransactionResult
```

```swift
_ = try await kit.policyManager.removePolicyByAddress(
    contextRuleId: 0,
    policyAddress: "CSPENDINGLIMITPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
)
```

Throws `ValidationException` when the policy is not on the rule.

### Changing only a threshold — set_threshold fast path

Changing ONLY the threshold of an already-installed Simple or Weighted threshold policy does NOT require remove + re-add. Call the policy contract's `set_threshold` directly through the smart account.

**Inverse rule — every OTHER policy param change is remove + re-add.** There is NO in-place "update policy params" call. To change a SpendingLimit's limit/period, a WeightedThreshold's weights, or any custom policy's params, you MUST `removePolicy(...)` (or `removePolicyByAddress(...)`) then re-install with the new install-param `SCValXDR` — two submissions, with the policy absent between them. Only the bare `threshold` field of Simple/Weighted has the `set_threshold` fast path. The on-chain function is `set_threshold(threshold: u32, context_rule: ContextRule, smart_account: Address)`; the arg vector is `[.u32(newThreshold), <freshRuleScVal>, <smartAccountAddressScVal>]` in that order.

**Critical: re-fetch the rule immediately before the call.** The contract validates `newThreshold <= context_rule.signers.len()` against the `ContextRule` you pass in. A stale snapshot (signers changed since you read it) is rejected with `InvalidThreshold` (3201 simple / 3211 weighted). Always read it via `getContextRule(id:)` right before submitting.

```swift
let policyAddress = "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
let newThreshold: UInt32 = 3

// Re-fetch the raw rule SCVal immediately before the call — getContextRule(id:)
// returns the on-chain ContextRule struct, exactly what set_threshold expects.
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

### SelectedSigner

Explicitly list every signer that will sign. There is no implicit "connected passkey" — include it if it should sign. `SelectedSigner` is declared alongside `PolicyInstallParams`.

```swift
public enum SelectedSigner: Sendable, Hashable {
    case passkey(
        credentialId: String,             // Base64URL credential id
        credentialIdBytes: Data? = nil,   // raw bytes -> AllowCredential hint
        keyData: Data? = nil,             // 65-byte pubkey || credentialId
        transports: [String]? = nil       // e.g. ["internal", "hybrid"]
    )
    case wallet(accountId: String)        // G-address
    case ed25519(verifierAddress: String, publicKey: Data)   // 32-byte Ed25519 key
}
```

The `ed25519` arm is handled end-to-end: the pipeline validates the signing source via `kit.externalSigners.canSignEd25519For(verifierAddress:publicKey:)` and signs via `kit.externalSigners.signEd25519AuthDigest(...)`. It carries no signing material — register the key separately (see [External wallet and custody requirements](#external-wallet-and-custody-requirements)).

Collection semantics: signatures are collected sequentially in the order supplied. Each `passkey` triggers exactly one OS WebAuthn prompt; each `wallet` triggers one external-wallet signing request; each `ed25519` signs through `kit.externalSigners`. Sequential collection enables fail-fast on user cancellation.

> **keyData non-nil rule.** In a multi-signer ceremony, every `passkey` selector MUST carry non-`nil` `keyData`. The pipeline reconstructs external signers once per call (not per entry), so a `nil`-keyData passkey entry fails at runtime even when the credential is otherwise valid.

```swift
// WRONG: a passkey selector with no keyData in a multi-signer call
let bad = SelectedSigner.passkey(credentialId: savedCredId)   // keyData == nil
// -> fails at runtime: external signers are reconstructed outside the per-entry loop.

// CORRECT: always supply keyData from the on-chain signer record
let good = SelectedSigner.passkey(
    credentialId: savedCredId,                            // Base64URL
    credentialIdBytes: try Data(base64URLEncoded: savedCredId),  // optional routing hint (throwing init)
    keyData: onChainPasskeySigner.keyData,                // from ParsedContextRule signer
    transports: savedCredential.transports                // nil is fine
)
```

```swift
// WRONG: SelectedSigner.wallet(accountId: "CBCD...")   — wallet signers are G-addresses
// CORRECT: SelectedSigner.wallet(accountId: "GA7Q...")
```

> **Empty list = single-passkey fast path.** Routing is by emptiness only: `selectedSigners: []` runs the single-signer path (connected passkey, one prompt); any NON-empty list routes through the multi-signer pipeline. A list containing ONLY the connected passkey still routes to multi-signer and requires `keyData` per entry — it does not collapse back to the fast path.

```swift
// WRONG: selecting just the connected passkey as a one-element list
let bad: [SelectedSigner] = [.passkey(credentialId: kit.credentialId!)]   // routes to multi-signer; keyData nil -> fails
_ = try await kit.signerManager.addDelegated(contextRuleId: 0, address: g, selectedSigners: bad)
// CORRECT: for a connected-passkey-only operation, pass the empty default.
_ = try await kit.signerManager.addDelegated(contextRuleId: 0, address: g)   // selectedSigners: [] (default)
```

### Building SelectedSigner lists from on-chain rules

Read `ParsedContextRule.signers` and map each on-chain signer to the matching `SelectedSigner` case. Discriminate by concrete type and, for `OZExternalSigner`, by `keyData.count` against the live constants (never hard-code 65/32): `> secp256r1PublicKeySize` (65) is a passkey (keyData is `pubkey || credentialId`); `== ed25519PublicKeySize` (32) is an Ed25519 key. A passkey's `keyData` MUST be passed non-nil; recover its credential id with `OZSmartAccountBuilders.getCredentialIdStringFromSigner` / `getCredentialIdFromSigner` and its `transports` via `kit.credentialManagerConcrete.getCredential(credentialId:)?.transports`.

```swift
let rule = try await kit.contextRuleManagerConcrete
    .listContextRules()
    .first { $0.id == contextRuleId }!

var selected: [SelectedSigner] = []
for signer in rule.signers {
    if let ext = signer as? OZExternalSigner {
        if ext.keyData.count == SmartAccountConstants.ed25519PublicKeySize {
            // Ed25519 external signer (keyData is the raw 32-byte key).
            if kit.externalSigners.canSignEd25519For(
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
    amount: String,                       // decimal string, NOT stroops
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

Example — a 2-of-2 transfer with the connected passkey plus an external wallet:

```swift
let passkey = SelectedSigner.passkey(
    credentialId: kit.credentialId!,
    keyData: onChainPasskeySigner.keyData       // non-nil
)
let wallet = SelectedSigner.wallet(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")

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
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

```swift
// approve() on a SEP-41 token: from=smart account, spender=dex, amount=100, expiration=720
let hundredStroops = String(100 * StellarProtocolConstants.stroopsPerXlm)
let args: [SCValXDR] = [
    .address(try SCAddressXDR(contractId: kit.contractId!)),
    .address(try SCAddressXDR(contractId: "CDEXCONTRACTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")),
    try SCValXDR.i128(stringValue: hundredStroops),
    .u32(UInt32(StellarProtocolConstants.ledgersPerHour))
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
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
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

Shared signing pipeline behind the three entry points. Validates the signer set (connection check, per-wallet reachability via `kit.externalSigners.canSignFor`, per-passkey `keyData` precondition, per-Ed25519 registration check and 32-byte length), simulates to discover auth entries, signs every matching entry with every supplied signer, re-simulates so resource fees reflect the real signature size, and submits. Use it directly only for a host function whose shape the higher-level entry points do not cover.

```swift
public func submitWithMultipleSigners(
    hostFunction: HostFunctionXDR,
    selectedSigners: [SelectedSigner],
    forceMethod: SubmissionMethod? = nil,
    resolveContextRuleIds: ResolveContextRuleIds? = nil
) async throws -> TransactionResult
```

### ResolveContextRuleIds (advanced)

```swift
public typealias ResolveContextRuleIds = @Sendable (
    _ entry: SorobanAuthorizationEntryXDR,
    _ index: Int
) async throws -> [UInt32]
```

The pipeline picks which rule ids each auth entry should invoke automatically, using `OZContextRuleManager.resolveContextRuleIdsForEntry(...)`. Supply this callback when auto-resolution is ambiguous or to force a specific choice.

```swift
// Force every auth entry to use rule 2
let forceRule2: ResolveContextRuleIds = { _, _ in [2] }
_ = try await kit.multiSignerManager.multiSignerTransfer(
    tokenContract: tokenSac,
    recipient: recipient,
    amount: "10",
    selectedSigners: signers,
    resolveContextRuleIds: forceRule2
)
```

When auto-resolution cannot find a unique rule it throws `ValidationException.InvalidInput`, typically with one of: no rule matches the context type (add a matching rule or a Default), the selected signers match multiple rules (disambiguate with `resolveContextRuleIds`), or no single rule contains every selected signer (restrict the selection to one rule's signers or pass `resolveContextRuleIds`).

### External wallet and custody requirements

`SelectedSigner.wallet` and `SelectedSigner.ed25519` signers resolve through the kit-owned `kit.externalSigners` (`OZExternalSignerManager`, a non-optional actor). Two custody models per signer kind:

| Signer | In-memory (runtime) | Adapter (kit construction) |
|--------|---------------------|----------------------------|
| Wallet (`G…`) | `await kit.externalSigners.addFromSecret(secretKey: "S...")` | `config.externalWallet: ExternalWalletAdapter` |
| Ed25519 | `try kit.externalSigners.addEd25519FromRawKey(secretKeyBytes:verifierAddress:)` (sync, returns the 32-byte public key) | `config.externalEd25519Adapter: OZExternalEd25519SignerAdapter` |

```swift
// Register an in-memory wallet keypair (resolution tries in-memory first, then adapter).
let g = try await kit.externalSigners.addFromSecret(secretKey: "S...")   // async, returns G-address

// Register an Ed25519 signing key in memory; use the returned key in the selector.
let ed25519Verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
let edPublicKey = try kit.externalSigners.addEd25519FromRawKey(
    secretKeyBytes: rawSeed32,            // exactly 32 bytes
    verifierAddress: ed25519Verifier
)
let edSigner = SelectedSigner.ed25519(verifierAddress: ed25519Verifier, publicKey: edPublicKey)
```

A wallet adapter (`config.externalWallet`) receives the Base64-encoded `HashIDPreimage::SorobanAuthorization` XDR, SHA-256-hashes it, Ed25519-signs it, and returns the 64-byte signature; the SDK assembles the signed auth entry.

```swift
// WRONG (removed symbols — do not use):
//   kit.externalSignerManager            — replaced by kit.externalSigners
//   kit.externalSigners.setEd25519Adapter(...)            — no such method
//   kit.externalSigners.ed25519Adapter = ...              — not settable
//   config.externalWallet accessor as a mutable property  — set it at construction only
// CORRECT:
//   kit.externalSigners                  — the non-optional actor accessor
//   in-memory: addFromSecret(secretKey:) / addEd25519FromRawKey(secretKeyBytes:verifierAddress:)
//   adapters: config.externalWallet / config.externalEd25519Adapter (at kit construction)
```

> **Note.** `kit.externalSignerManager` does not exist on this SDK. Earlier scaffolding referenced an optional accessor; the converged surface is the non-optional `kit.externalSigners`.

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
    options: ConnectWalletOptions(
        credentialId: reg.credentialId.base64URLEncodedString(),
        contractId: knownContractId
    )
)
guard case .connected = connected else {
    throw WalletException.notFound(identifier: knownContractId)
}

// 3. The backup signer (delegated G-address held by the user's external wallet).
let backup = SelectedSigner.wallet(accountId: "GBACKUPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

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
    throw TransactionException.submissionFailed(reason: addResult.error ?? "add_signer failed")
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

A raw-Ed25519 backup added via `addEd25519` uses the external-signer pipeline and is expressed as `SelectedSigner.ed25519(...)`, not `.wallet(...)`. To use the wallet path shown above, register the backup as a delegated `G-address`.

### Signer rotation (add new, then remove old)

**Preconditions.** Connected with the current passkey; moving to a new authenticator. The Default rule has one passkey signer and no policies. Always add first, never remove first.

```swift
// 1. Register and add the new passkey. The connected passkey authorizes (selectedSigners []).
let added = try await kit.signerManager.addNewPasskeySigner(
    contextRuleId: 0,
    userName: "User name on new device"
)
guard added.transactionResult.success else {
    throw TransactionException.submissionFailed(reason: added.transactionResult.error ?? "add_signer failed")
}
let newCredentialId = added.credentialId

// 2. Remember the old credential id BEFORE reconnecting.
guard let oldCredentialId = kit.credentialId else {
    throw WalletException.notConnected(details: "old session already lost")
}

// 3. Reconnect using the new passkey. addNewPasskeySigner already persisted the
//    new credential with the contract id, so connectWallet resolves it from
//    storage with no WebAuthn prompt.
_ = try await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(credentialId: newCredentialId)
)

// 4. Remove the old passkey (the new passkey authorizes, selectedSigners []).
let rule = try await kit.contextRuleManagerConcrete.listContextRules().first { $0.id == 0 }!
guard let oldIdx = rule.signers.firstIndex(where: { signer in
    OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer) == oldCredentialId
}) else {
    throw ValidationException.invalidInput(field: "signer", reason: "Old passkey not found on Default rule")
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

When a kit method throws `TransactionException.SimulationFailed`, the message wraps the RPC simulation error, which carries the host error code as `Error(Contract, #<code>)`. There is no typed contract-error exception — parse the code from the message and map it to an action.

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
} catch let e as TransactionException.SimulationFailed {
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
    if code == ContractErrorCodes.unauthorizedSigner {   // 3016
        // re-resolve rule ids or adjust the selected-signer set
    }
}
```

```swift
// WRONG: catch a typed ContractException and switch on .code  — no such class exists
// CORRECT: catch TransactionException.SimulationFailed and parse the message
// WRONG: matching on e.code (== SmartAccountErrorCode.transactionSimulationFailed)
//   — that is the SDK error kind, not the on-chain contract code
// CORRECT: extract the contract code from e.message via the "Error(Contract, #NNNN)" regex
```

`ContractErrorCodes` exposes only the five codes the SDK interprets directly — `mathOverflow` (3012), `keyDataTooLarge` (3013), `contextRuleIdsLengthMismatch` (3014), `nameTooLong` (3015), `unauthorizedSigner` (3016). Every other code in the 3000 / 3200 / 3210 / 3220 ranges is parsed from the message and mapped via the tables below.

---

## Events

Signer, policy, and context-rule changes do not emit dedicated kit events; they surface as `SmartAccountEvent.transactionSubmitted(hash:success:)`. The kit-level event catalogue and subscription mechanics are documented in [smart_accounts.md — Events](./smart_accounts.md#events).

For on-chain contract events (`signer_added`, `policy_added`, etc.), query the kit-owned server with the account's contract id as the filter:

```swift
let filter = EventFilter(type: "contract", contractIds: [kit.contractId!])
let response = await kit.sorobanServer.getEvents(startLedger: fromLedger, eventFilters: [filter])
switch response {
case .success(let response):
    for event in response.events {
        // event.topic and event.value are base64-XDR-encoded SCVal entries
    }
case .failure(let error):
    print("getEvents failed: \(error)")
}
```

---

## Contract Error Codes

When the smart-account contract rejects a call, the on-chain error code is surfaced inside `TransactionException.SimulationFailed` (simulation) or `TransactionException.SubmissionFailed` (submit/poll). Look for `Error(Contract, #<code>)` in the message.

> These on-chain contract codes overlap numerically with the SDK's `SmartAccountErrorCode` enum but are a different channel: an on-chain code arrives inside a `TransactionException` message, whereas an SDK code is the `code` property of a `SmartAccountException`. Check the exception type first.

### Smart account errors (3000 range)

| Code | Symbol | Meaning | Fix |
|------|--------|---------|-----|
| 3000 | ContextRuleNotFound | `contextRuleId` does not exist | Pass a valid id from `listContextRules()`. Ids are never reused. |
| 3002 | UnvalidatedContext | No rule matches this operation's context type | Add a `callContract` / `createContract` rule, or a Default rule. |
| 3003 | ExternalVerificationFailed | Verifier contract rejected the signature | Signature or key data is wrong, or the verifier was upgraded. |
| 3004 | NoSignersAndPolicies | Tried to create or reduce a rule to 0 signers and 0 policies | Supply at least one signer or one policy. |
| 3005 | PastValidUntil | `validUntil` is `<=` current ledger | Compute `validUntil` from a future ledger sequence. |
| 3006 | SignerNotFound | `signerId` not present on the rule | Use `ParsedContextRule.signerIds`. |
| 3007 | DuplicateSigner | Signer already on the rule | Each signer (by `uniqueKey`) appears at most once per rule. |
| 3008 | PolicyNotFound | `policyId` not present on the rule | Use `ParsedContextRule.policyIds`. |
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
        policyAddress: "CSIMPLETHRESHOLDPOLICYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        threshold: 2
    )
    if !res.success { print("submit failed: \(res.error ?? "")") }
} catch let e as TransactionException.SimulationFailed {
    print("simulation failed (contract code in message): \(e.message)")
} catch let e as ValidationException.InvalidInput {
    print("client-side validation: \(e.message)")
} catch let e as WalletException.NotConnected {
    print("call connectWallet() first: \(e.message)")
}
```

See also: the SDK error hierarchy in [smart_accounts.md — Error Handling](./smart_accounts.md#error-handling).
