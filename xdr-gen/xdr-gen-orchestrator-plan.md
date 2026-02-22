# XDR Code Generation Orchestrator Plan -- iOS/macOS Stellar SDK

## Overview

Replace 107 manually maintained XDR Swift files in `stellarsdk/stellarsdk/responses/xdr/` with auto-generated files produced by a custom Ruby generator built on Stellar's `xdrgen` gem, matching the pipeline used by the Python, Java, and KMP SDKs.

## Constraints

1. **No breaking changes.** The public API surface must remain identical. All existing call sites, helper extensions, tests, and external consumers must compile and behave identically without modification. Type names, method signatures, property names, and semantics (value vs. reference) must be preserved.
2. **Swift 6 Sendable conformance.** All generated types must conform to `Sendable`. Structs and enums with value-type-only members get automatic conformance. Hand-maintained class types use `@unchecked Sendable` with lock-guarded mutation (existing pattern). No mutable shared state in generated types.
3. **Production-ready output.** Generated code must be robust. Array size validation is added to the `decodeArray()` infrastructure function (protecting all types uniformly). Depth limiting for recursive types is deferred as a follow-up hardening task (the `XDRDecoder` buffer exhaustion provides natural protection). Not simplified implementations.

## Scope

- Build a Ruby generator class extending `Xdrgen::Generators::Base` that emits Swift files
- Extract ~18 files' worth of hand-written helper methods into separate extension files
- Maintain a set of hand-maintained types excluded from generation (~22 types: envelope classes, types with stored helper properties, struct-with-constants types, types with `[UInt8]`/`WrappedData32` mismatches, types defined outside `responses/xdr/`)
- Create Makefile with `xdr-update`, `xdr-clean`, `xdr-generate` targets
- Create Docker-based build for deterministic generation
- Create snapshot tests for the generator
- Ensure all existing unit and integration tests pass with generated code

## Reference material

| SDK | Generator location | Generator lines | Docker image |
|---|---|---|---|
| Python | `/Users/chris/projects/Stellar/py-stellar-base/xdr-generator/` | 789 | `ruby:3.4.2` |
| Java | `/Users/chris/projects/Stellar/java-stellar-sdk/xdr-generator/` | 761 | `ruby:3.4.2` |

Primary reference: Python SDK generator (most mature pipeline with Makefile, Docker, snapshot tests).

## Key directories

| Purpose | Path |
|---|---|
| Current XDR files (107) | `stellarsdk/stellarsdk/responses/xdr/` |
| XDR codable infrastructure | `stellarsdk/stellarsdk/utils/xdrCodable/` |
| Unit tests | `stellarsdk/stellarsdkUnitTests/` |
| Package definition | `Package.swift` |
| Helper extraction target | `stellarsdk/stellarsdk/xdr_helpers/` (new) |
| Generator | `xdr-generator/` (new) |
| XDR definitions | `xdr/` (new, fetched from stellar/stellar-xdr) |
| Generated output | `stellarsdk/stellarsdk/xdr/` (new) |

## Hand-maintained types (excluded from generation)

The following types must NOT be generated. They are excluded from the generator output and remain as hand-maintained files in their current location (moved to `stellarsdk/stellarsdk/xdr/` alongside generated files but marked with a "HAND-MAINTAINED" header instead of "DO NOT EDIT").

| Type | Current file | Reason |
|------|-------------|--------|
| `TransactionV1EnvelopeXDR` | `TransactionV1EnvelopeXDR.swift` | `class : NSObject, @unchecked Sendable` with `NSLock`-guarded `_signatures`. Reference semantics required by signing flow. |
| `TransactionV0EnvelopeXDR` | `TransactionV0EnvelopeXDR.swift` | Same class pattern with lock-guarded signatures. |
| `FeeBumpTransactionEnvelopeXDR` | `FeeBumpTransactionEnvelopeXDR.swift` | Same class pattern with lock-guarded signatures. |
| `TransactionXDR` | `TransactionXDR.swift` | Contains `public var signatures = [DecoratedSignatureXDR]()` -- a stored helper property not in the XDR wire format. Swift does not allow stored properties in extensions, so this type cannot be generated and then extended. |
| `FeeBumpTransactionXDR` | `FeeBumpTransactionXDR.swift` | Same pattern -- contains `signatures` stored property not in XDR spec. |
| `TransactionV0XDR` | `TransactionV0XDR.swift` | Same pattern -- contains `signatures` stored property. |
| `TransactionSignaturePayload` | (in `TransactionXDR.swift`) | Conforms only to `XDREncodable` (not `XDRDecodable`). Contains nested `EnvelopeType` with custom discriminant logic. |
| `AccountEd25519Signature` | (in `TransactionXDR.swift`) | `final class` that does not conform to `XDRCodable`. Pure SDK helper, not an XDR type. |
| `AssetType` | (in `AssetXDR.swift`) | Currently `struct` with static `Int32` constants. XDR defines as `enum`. Generating as enum would break all call sites using `AssetType.ASSET_TYPE_NATIVE` etc. |
| `EnvelopeType` | (in `TransactionEnvelopeXDR.swift`) | Same struct-with-constants pattern. Generating as enum would break `EnvelopeType.ENVELOPE_TYPE_TX` etc. |
| `CryptoKeyType` | (in `MuxedAccountXDR.swift`) | Same struct-with-constants pattern. Used by `MuxedAccountXDR`, `SignerKeyXDR`, `PublicKey`. Call sites use `CryptoKeyType.KEY_TYPE_ED25519` etc. |
| `MemoType` | (in `MemoXDR.swift`) | Same struct-with-constants pattern. Used by `MemoXDR`, `WebAuthenticator`. Call sites use `MemoType.MEMO_TYPE_NONE` etc. |
| `AccountFlags` | (in `AccountEntryXDR.swift`) | Same struct-with-constants pattern. Generating as enum would break any call sites using `AccountFlags.AUTH_REQUIRED_FLAG` etc. |
| `TrustLineFlags` | (in `TrustlineEntryXDR.swift`) | Same struct-with-constants pattern. `AllowTrustOperation` uses `TrustLineFlags.AUTHORIZED_FLAG`. |
| `ClaimableBalanceFlags` | (in `ClaimableBalanceEntryXDR.swift`) | Same struct-with-constants pattern. Generating as enum would break call-site syntax. |
| `MuxedAccountXDR` | (in `MuxedAccountXDR.swift`) | Uses `[UInt8]` for `.ed25519` case instead of `WrappedData32`. Contains helper computed properties (`ed25519AccountId`, `accountId`, `id`). Discriminant is `CryptoKeyType` (struct-with-constants). Generating would change field types and break pattern matching. |
| `MuxedAccountMed25519XDR` | (in `MuxedAccountXDR.swift`) | Uses `[UInt8]` for `sourceAccountEd25519` instead of `WrappedData32`. Same `[UInt8]` mismatch as `MuxedAccountXDR`. |
| `MuxedAccountMed25519XDRInverted` | (in `MuxedAccountMed25519XDR.swift`) | Custom SDK type NOT in the `.x` files. Same fields as `MuxedAccountMed25519XDR` but with inverted field order (used for muxed account encoding). Not generated since it has no XDR definition, but must remain in the hand-maintained file. |
| `OperationType` | `responses/operations_responses/OperationResponse.swift` | Proper `enum OperationType: Int32, Sendable` defined OUTSIDE the XDR directory. Generator would produce a duplicate definition. |
| `PublicKey` | `crypto/PublicKey.swift` | `final class PublicKey` defined OUTSIDE the XDR directory. Already conforms to `XDRCodable`. Has rich SDK functionality (account ID encoding, Ed25519 operations). Generator would produce a conflicting type. |
| `TransactionEnvelopeXDR` | `TransactionEnvelopeXDR.swift` | Union referencing three hand-maintained envelope classes. Contains `EnvelopeType` struct. Verify during Phase 0 audit whether generated output would produce identical case names and associated types. If any mismatch, exclude. |

The generator's `generate.rb` must maintain a `SKIP_TYPES` list. When the xdrgen AST encounters these type names, it skips file generation for them. The hand-maintained files provide the implementations instead.

**Important:** Types defined OUTSIDE `responses/xdr/` (like `PublicKey` at `crypto/PublicKey.swift` and `OperationType` at `responses/operations_responses/OperationResponse.swift`) must also be in `SKIP_TYPES`. The generator processes ALL definitions from the `.x` files, regardless of where the current SDK defines them. Task 0.1 must scan the entire `stellarsdk/stellarsdk/` tree to find all such cases.

**Nested types in hand-maintained files:** Hand-maintained files may contain nested type definitions. If the XDR spec defines these as top-level types, the generator (via xdrgen) would emit them as separate files with different names, creating duplicates. All such nested types must be added to `SKIP_TYPES`. Task 0.1 catalogs these. Known cases:
- `TransactionSignaturePayload.TaggedTransaction` -> xdrgen emits as `TransactionSignaturePayloadTaggedTransaction`. Add to SKIP_TYPES.
- `FeeBumpTransactionXDR.InnerTransactionXDR` -> xdrgen emits as `FeeBumpTransactionInnerTx`. Add to SKIP_TYPES.
- `FeeBumpTransactionXDR.ext` -> xdrgen emits as `FeeBumpTransactionExt`. Add to SKIP_TYPES.

## XDR commit to pin

`4b7a2ef7931ab2ca2499be68d849f38190b443ca` (same as Python SDK).

## XDR definition files

```
Stellar-SCP.x
Stellar-contract-config-setting.x
Stellar-contract-env-meta.x
Stellar-contract-meta.x
Stellar-contract-spec.x
Stellar-contract.x
Stellar-exporter.x
Stellar-internal.x
Stellar-ledger-entries.x
Stellar-ledger.x
Stellar-overlay.x
Stellar-transaction.x
Stellar-types.x
```

---

## Phase 0: Audit and inventory

**Goal:** Produce a complete map of every type, helper, and dependency in the current XDR files.

### Task 0.1: Catalog all XDR types and their categories

**Agent:** Explore
**Blocks:** 1.1, 1.2, 2.1
**Deliverable:** `xdr-generator/audit/type-catalog.md`

Scan all 107 files in `stellarsdk/stellarsdk/responses/xdr/`. For each file, record:

1. Every type defined (struct, enum, indirect enum, class, typealias)
2. Category: pure-XDR-serialization vs. helper/convenience
3. Whether it uses `WrappedData4`, `WrappedData12`, `WrappedData32` (fixed-size opaque)
4. Whether it uses `decodeArray()` or `decodeArrayOpt()` helpers
5. Whether it uses `indirect enum` (recursive types)
6. Which protocols it conforms to (`XDRCodable`, `Sendable`, others)
7. Total count of XDR types vs. distinct `.x` definition types
8. Whether struct fields use `let` or `var` (needed to determine generated field mutability)
9. Whether the type follows the struct-with-static-constants pattern (`public struct X: Sendable { static let Y: Int32 = N }` or `static let Y: UInt32 = N`). **Any XDR-defined enum type that the current SDK implements as a `struct` with static `Int32`/`UInt32` constants must be added to `SKIP_TYPES`**, because generating it as a Swift `enum` would break the call-site syntax (`TypeName.CONSTANT_NAME` vs `TypeName.caseName`). Known instances: `AssetType`, `EnvelopeType`, `CryptoKeyType`, `MemoType`, `AccountFlags`, `TrustLineFlags`, `ClaimableBalanceFlags`. Search for additional instances.
10. For each field typed as `[UInt8]`, record whether the XDR definition uses `uint256` / `opaque[32]` and note the mismatch with the generator's `WrappedData32` output. Types with this mismatch are candidates for `SKIP_TYPES` since the generator would change the field type (breaking change). Known instances: `MuxedAccountXDR` (`.ed25519` case), `MuxedAccountMed25519XDR` (`sourceAccountEd25519`), `TransactionV0XDR` (`sourceAccountEd25519`), `ClaimOfferAtomV0XDR` (`sellerEd25519`).
11. For each hand-maintained file, catalog all nested type definitions (e.g., `FeeBumpTransactionXDR.InnerTransactionXDR`) and ensure they are in `SKIP_TYPES` if the generator would also emit them as top-level types. The generator processes `.x` files where these may be defined as top-level types, creating duplicate definitions.
12. Catalog custom SDK types that do NOT appear in the `.x` files but live in hand-maintained XDR files (e.g., `MuxedAccountMed25519XDRInverted` in `MuxedAccountMed25519XDR.swift`). These are not generated and stay with their parent file. Record them so audit agents do not flag them as missing from generated output.

**Critical: also scan the ENTIRE `stellarsdk/stellarsdk/` tree** (not just `responses/xdr/`) for types whose names match XDR definitions from the `.x` files. Any XDR-defined type that already exists outside `responses/xdr/` must be added to `SKIP_TYPES`. Known examples:
- `PublicKey` at `crypto/PublicKey.swift`
- `OperationType` at `responses/operations_responses/OperationResponse.swift`
- Search for any others (e.g., `MuxedAccount`, `SignerKey`, etc. -- verify they are in `responses/xdr/` and not elsewhere)

### Task 0.2: Identify all helper methods requiring extraction and classify exclusions

**Agent:** Explore
**Blocks:** 1.1
**Deliverable:** `xdr-generator/audit/helpers-to-extract.md`

**Part A -- Validate the exclusion list.** For each type in the "Hand-maintained types" table above, verify:
- Is it a class or struct?
- Does it have stored properties not in the XDR wire format?
- Does it use `NSLock`, `NSObject`, or `@unchecked Sendable`?
- Does it conform only to `XDREncodable` (not `XDRCodable`)?
- Is it a struct-with-static-constants pattern (not a Swift enum)? Systematically search for ALL types matching `public struct X: Sendable { static let ... : Int32 = ... }`. The known list (AssetType, EnvelopeType, CryptoKeyType, MemoType, AccountFlags, TrustLineFlags, ClaimableBalanceFlags) may not be complete.
- Does it use `[UInt8]` for fields that the XDR spec defines as `opaque[32]` / `uint256`? If so, the generator would produce `WrappedData32` instead, breaking pattern matches and field access. Consider for exclusion.
- Add any additional types that meet these criteria to the exclusion list.

**Part B -- Catalog helpers to extract.** For each of the ~18 files containing helpers (identified below), catalog every method or computed property that is NOT part of XDR encode/decode:

**Files with confirmed helpers:**
- `TransactionXDR.swift` -- sign(), hash(), toEnvelopeXDR(), encodedEnvelope(), encodedV1Envelope(), encodedV1Transaction(), convenience init with PublicKey, `signatures` property, SorobanAuthorizationEntryXDR.sign(), AccountEd25519Signature class, SorobanAddressCredentialsXDR.appendSignature(), SorobanTransactionDataXDR.archivedSorobanEntries computed property, LedgerFootprintXDR.init(fromBase64:), SorobanAuthorizationEntryXDR.init(fromBase64:), SorobanTransactionDataXDR.init(fromBase64:)
- `FeeBumpTransactionXDR.swift` -- sign(), hash(), toEnvelopeXDR(), toFBEnvelopeXDR(), encodedEnvelope(), addSignature(), signatures property, InnerTransactionXDR.tx computed property
- `TransactionEnvelopeXDR.swift` -- init(fromBase64:), txSourceAccountId, txMuxedSourceId, txSeqNum, txTimeBounds, cond, sorobanTransactionData, txFee, txMemo, txOperations, txExt, txSignatures, txHash(), appendSignature()
- `TransactionV0XDR.swift` -- sign(), hash(), encodedEnvelope()
- `TransactionV1EnvelopeXDR.swift` -- txSourceAccountId, appendSignature()
- `TransactionV0EnvelopeXDR.swift` -- txSourceAccountId, appendSignature()
- `FeeBumpTransactionEnvelopeXDR.swift` -- convenience inits
- `OperationXDR.swift` -- deprecated init with PublicKey, setSorobanAuth()
- `AssetXDR.swift` -- assetCode, issuer computed properties, init(assetCode:issuer:)
- `AllowTrustOpAssetXDR.swift` -- assetCode, init(assetCodeString:)
- `ChangeTrustAssetXDR.swift` -- assetCode, issuer, init helpers
- `TrustlineAssetXDR.swift` -- assetCode, issuer, init helpers
- `Alpha4XDR / Alpha12XDR` (in AssetXDR.swift) -- assetCodeString, init(assetCodeString:issuer:)
- `ContractEventXDR.swift` -- convenience accessors
- `TransactionMetaXDR.swift` -- convenience computed properties
- `LedgerEntryXDR.swift` -- convenience accessors
- `LedgerExtryDataXDR.swift` -- convenience accessors
- `LedgerKeyXDR.swift` -- convenience accessors
- `SignerKeyXDR.swift` -- `Ed25519SignedPayload.encodeSignedPayload()`, `Ed25519SignedPayload.publicKey()`, explicit `Equatable` conformance on `Ed25519SignedPayload` (can be removed since generated version auto-synthesizes `Equatable`), explicit `==` on `SignerKeyXDR` (same -- remove if generated version auto-synthesizes)

Record for each helper:
- Method signature
- Which SDK types it depends on (KeyPair, Network, StellarSDKError, etc.)
- Whether it mutates self
- Which other XDR types it references
- Target extraction file name

### Task 0.3: Build the name override map

**Agent:** Explore
**Blocks:** 2.1
**Deliverable:** `xdr-generator/audit/name-mapping.md` AND `xdr-generator/generator/name_overrides.rb` AND `xdr-generator/generator/member_overrides.rb`

Compare every Swift type name in the current codebase against the canonical names in the `.x` files (download from stellar/stellar-xdr). Produce:

1. **Documentation** (`name-mapping.md`): Complete mapping table with columns: XDR canonical name, current Swift name, action (rename in generator / keep as-is / exclude).

2. **Concrete override map** (`name_overrides.rb`): A Ruby hash consumed by the generator:
```ruby
NAME_OVERRIDES = {
  "AlphaNum4" => "Alpha4XDR",
  "AlphaNum12" => "Alpha12XDR",
  # ... all mismatches
}.freeze
```

3. **Member/case name override map** (`member_overrides.rb`): For ALL enum and union types where the Swift member/case names differ from the mechanical `SCREAMING_SNAKE_CASE -> camelCase` conversion of the `.x` file names. This covers both SKIP_TYPES discriminants AND generated enums/unions:
```ruby
MEMBER_OVERRIDES = {
  # SKIP_TYPES discriminants (struct-with-constants -- member names referenced by generated unions)
  "MemoType" => {
    "MEMO_NONE" => "MEMO_TYPE_NONE",
    "MEMO_TEXT" => "MEMO_TYPE_TEXT",
    "MEMO_ID" => "MEMO_TYPE_ID",
    "MEMO_HASH" => "MEMO_TYPE_HASH",
    "MEMO_RETURN" => "MEMO_TYPE_RETURN",
  },
  "OperationType" => {
    "CREATE_ACCOUNT" => "accountCreated",
    "PAYMENT" => "payment",
    "PATH_PAYMENT_STRICT_RECEIVE" => "pathPayment",
    "MANAGE_SELL_OFFER" => "manageSellOffer",
    # ... all 27+ cases, full mapping built during audit
  },
  # Generated enums with non-mechanical name conversions
  "ClaimPredicateType" => {
    "CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME" => "claimPredicateBeforeAbsTime",
    "CLAIM_PREDICATE_BEFORE_RELATIVE_TIME" => "claimPredicateBeforeRelTime",
  },
  "RevokeSponsorshipType" => {
    "REVOKE_SPONSORSHIP_SIGNER" => "revokeSponsorshipSignerEntry",
  },
  # ... all other deviations found during audit
}.freeze
```

The generator applies `NAME_OVERRIDES` when choosing output type names and file names, and `MEMBER_OVERRIDES` when converting enum case names and union arm names. This ensures zero breaking changes.

**How MEMBER_OVERRIDES is used:** The generator implements a `swift_enum_case_name(xdr_name, type_name)` function that:
1. Applies mechanical `SCREAMING_SNAKE_CASE -> camelCase` conversion (strip common prefix, lowercase first letter, camelCase remaining words)
2. Checks `MEMBER_OVERRIDES[type_name][xdr_name]` for an override
3. If an override exists, returns it instead of the mechanical conversion

This function is used for:
- Enum case names in generated `render_enum` output
- Union arm names in generated `render_union` output
- Discriminant member references when the discriminant type is in SKIP_TYPES

**Why this is needed:** The xdrgen AST provides member names in `SCREAMING_SNAKE_CASE` from the `.x` files. Most convert mechanically to Swift camelCase, but some current SDK names use abbreviations or additions that a mechanical conversion would miss. Without overrides, the generated code uses wrong case names and does not compile.

**Confirmed non-mechanical conversions (require overrides):**
- `ClaimPredicateType`: `CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME` -> `.claimPredicateBeforeAbsTime` (abbreviated)
- `ClaimPredicateType`: `CLAIM_PREDICATE_BEFORE_RELATIVE_TIME` -> `.claimPredicateBeforeRelTime` (abbreviated)
- `RevokeSponsorshipType`: `REVOKE_SPONSORSHIP_SIGNER` -> `.revokeSponsorshipSignerEntry` (appended "Entry")
- `MemoType`: `MEMO_NONE` -> `MEMO_TYPE_NONE` (struct-with-constants, `_TYPE_` inserted)
- `OperationType`: `CREATE_ACCOUNT` -> `.accountCreated` (completely different naming convention)

**Confirmed mechanical conversions (no overrides needed):**
- `SCValType`: `SCV_BOOL` -> `.bool` (strip `SCV_` prefix, lowercase)
- `LedgerEntryType`: `CLAIMABLE_BALANCE` -> `.claimableBalance` (camelCase)
- `SignerKeyType`: `SIGNER_KEY_TYPE_ED25519` -> `.ed25519` (strip prefix, lowercase)
- `AssetType`, `EnvelopeType`, `CryptoKeyType`, `AccountFlags`, `TrustLineFlags`, `ClaimableBalanceFlags` -- struct-with-constants, member names match `.x` files exactly.

**Required analysis:**
- Cases where Swift names differ from XDR names (e.g., `Alpha4XDR` vs `AlphaNum4`)
- The `XDR` suffix convention: the generator must append `XDR` to all type names by default (current convention), configurable via the override map for types that deviate
- Cases where multiple XDR types are grouped into one Swift file (these will become separate files post-generation; verify no caller depends on the file grouping)
- Cases where the SDK has types not in the `.x` files (custom types that must not be generated)
- Verify every current public type name is preserved in the generated output
- For ALL enum types (not just SKIP_TYPES discriminants), compare the mechanically converted XDR member names against the current Swift case names. Record any deviations in `MEMBER_OVERRIDES`. The mechanical conversion is: strip common prefix, lowercase first letter, camelCase remaining words. Any case where this does not produce the current Swift name needs an override entry.
- For union types, apply the same comparison to union arm names (the case names of the generated Swift enum).

### Review checkpoint 0

**Agent:** code-reviewer
**Blocks:** Phase 1
**Input:** All three audit deliverables
**Criteria:**
- Type catalog is complete (all 230+ type declarations accounted for)
- Every helper method is identified with its SDK dependencies
- The exclusion list is validated: every type on it has a concrete reason, no types are missing. In particular, ALL struct-with-constants types and ALL `[UInt8]`-vs-`WrappedData32` mismatch types are accounted for.
- Name override map is complete: every current Swift type name has a corresponding entry
- Member override map is complete: for ALL enum and union types (not just SKIP_TYPES discriminants), member/case names are compared against the mechanical camelCase conversion of the `.x` file names. All non-mechanical deviations are recorded in `MEMBER_OVERRIDES`. Known deviations: `MemoType`, `OperationType`, `ClaimPredicateType`, `RevokeSponsorshipType`.
- The override maps preserve ALL existing public type names and member names (no breaking changes)
- Name mapping covers all 107 files
- No types are missing from the analysis

---

## Phase 1: Helper extraction

**Goal:** Move all non-serialization code out of XDR files into separate extension files, while keeping the test suite green.

### Task 1.1: Create the helpers directory and scaffold extension files

**Agent:** general-purpose
**Depends on:** 0.1, 0.2
**Blocks:** 1.2, 1.3
**Deliverable:** Empty extension file stubs in `stellarsdk/stellarsdk/xdr_helpers/`

Create one extension file per XDR type that has helpers. File naming convention: `{TypeName}+Helpers.swift`. Each file should:
- Import Foundation and any SDK modules needed
- Contain `extension TypeName { }` with a comment placeholder
- Compile successfully (empty extensions are fine)

### Task 1.2: Extract helpers -- batch 1 (Transaction types)

**Agent:** general-purpose
**Depends on:** 1.1
**Blocks:** 1.3
**Deliverable:** Working extraction of the most complex files

**Important -- excluded types stay intact.** The following types are hand-maintained and excluded from generation. They keep their `signatures` stored property, class semantics, and helper methods in-place. Only helpers for OTHER types defined in the same file are extracted:

- `TransactionXDR` -- stays hand-maintained (has `signatures` stored property)
- `TransactionV0XDR` -- stays hand-maintained (has `signatures` stored property)
- `FeeBumpTransactionXDR` -- stays hand-maintained (has `signatures` stored property)
- `TransactionV1EnvelopeXDR` -- stays hand-maintained (class with NSLock)
- `TransactionV0EnvelopeXDR` -- stays hand-maintained (class with NSLock)
- `FeeBumpTransactionEnvelopeXDR` -- stays hand-maintained (class with NSLock)
- `TransactionSignaturePayload` -- stays hand-maintained (XDREncodable only)
- `AccountEd25519Signature` -- stays hand-maintained (not an XDR type)

**What IS extracted from these files:** Helper methods on types that ARE generated but happen to live in the same file. For example, `TransactionXDR.swift` contains ~20 types; the non-excluded types (e.g., `SorobanAuthorizationEntryXDR`, `SorobanAddressCredentialsXDR`, `SorobanTransactionDataXDR`, `LedgerFootprintXDR`, etc.) have helpers that must be extracted to `xdr_helpers/` since those types will be generated.

Specific extractions:
1. `TransactionXDR.swift` -- Extract `SorobanAuthorizationEntryXDR` helpers (sign, init(fromBase64:)), `SorobanAddressCredentialsXDR.appendSignature()`, `LedgerFootprintXDR.init(fromBase64:)`, `SorobanTransactionDataXDR` helpers (archivedSorobanEntries, init(fromBase64:)). Leave TransactionXDR/TransactionSignaturePayload/AccountEd25519Signature untouched.
2. `TransactionEnvelopeXDR.swift` -- Move all computed properties and init(fromBase64:) into `TransactionEnvelopeXDR+Helpers.swift`. Leave `EnvelopeType` struct in-place (excluded from generation).
3. `OperationXDR.swift` -- Move deprecated init with PublicKey, setSorobanAuth() into helpers. Leave `OperationType` in-place if it is a struct-with-constants (verify during audit).

**Validation after each file:**
```
swift build 2>&1 | head -50
swift test --filter stellarsdkUnitTests 2>&1 | tail -20
```

### Task 1.3: Extract helpers -- batch 2 (Asset and remaining types)

**Agent:** general-purpose
**Depends on:** 1.2 (sequential -- must compile cleanly after batch 1 before starting batch 2)
**Blocks:** 1.4
**Deliverable:** Working extraction of remaining helper files

Extract helpers from:
1. `AssetXDR.swift` -- Move assetCode, issuer, init(assetCode:issuer:), Alpha4XDR.assetCodeString, Alpha4XDR.init(assetCodeString:issuer:), Alpha12XDR equivalents. Leave `AssetType` struct in-place (excluded from generation).
2. `AllowTrustOpAssetXDR.swift` -- Move convenience inits and computed properties
3. `ChangeTrustAssetXDR.swift` -- Move convenience inits and computed properties
4. `TrustlineAssetXDR.swift` -- Move convenience inits and computed properties
5. `ContractEventXDR.swift`, `TransactionMetaXDR.swift`, `LedgerEntryXDR.swift`, `LedgerExtryDataXDR.swift`, `LedgerKeyXDR.swift` -- Move convenience computed properties

### Task 1.4: Verify extraction completeness

**Agent:** code-reviewer
**Depends on:** 1.2, 1.3
**Blocks:** Phase 2
**Deliverable:** Verification report

Verify:
1. For non-excluded types: XDR files now contain ONLY type definition, `init(from decoder: Decoder)`, `encode(to encoder: Encoder)`, `type() -> Int32` (for unions), and pure XDR initializers
2. For excluded types (see "Hand-maintained types" table): files are unchanged and fully intact with all their stored properties, class semantics, and helpers
3. All extracted helper logic lives in `stellarsdk/stellarsdk/xdr_helpers/`
4. `swift build` succeeds with no warnings related to XDR types
5. `swift test --filter stellarsdkUnitTests` passes (all tests green)
6. No circular dependencies between xdr/ and xdr_helpers/
7. `EnvelopeType` struct and `AssetType` struct are preserved in-place (excluded from generation)
8. No public API changes: verify no type names, method signatures, or property names have changed

### Review checkpoint 1

**Agent:** code-reviewer
**Blocks:** Phase 2
**Criteria:**
- Clean separation between generated code and hand-written helpers
- All unit tests pass
- No regression in public API (no breaking changes to callers)
- Helper files compile independently of the future generated code's internal structure

---

## Phase 2: Build the Ruby generator

**Goal:** Create a complete Ruby generator that produces Swift files matching the current XDR serialization patterns.

### Task 2.1: Scaffold the generator project

**Agent:** general-purpose
**Depends on:** 0.3
**Blocks:** 2.2
**Deliverable:** `xdr-generator/` directory with working project structure

Create the following structure (modeled on Python SDK):
```
xdr-generator/
  Gemfile
  Gemfile.lock
  generate.rb
  generator/
    generator.rb
  test/
    generator_snapshot_test.rb
    fixtures/
      xdrgen/
        struct.x
        enum.x
        union.x
        optional.x
        const.x
        nesting.x
        keywords.x
        test.x
    snapshots/
      (initially empty, populated by UPDATE_SNAPSHOTS=1)
```

`Gemfile` contents:
```ruby
source "https://rubygems.org"
gem "xdrgen", git: "https://github.com/stellar/xdrgen", branch: "master"
gem "base64"
gem "benchmark"
gem "bigdecimal"
gem "logger"
gem "mutex_m"
```

`generate.rb` contents (adapted from Python SDK):
```ruby
require 'xdrgen'
require_relative 'generator/generator'

puts "Generating Swift XDR classes..."

Dir.chdir("..")

Xdrgen::Compilation.new(
  Dir.glob("xdr/*.x"),
  output_dir: "stellarsdk/stellarsdk/xdr/",
  generator: Generator,
  namespace: "stellar",
).compile

puts "Done!"
```

Test fixtures should be copied from Python SDK's `xdr-generator/test/fixtures/xdrgen/`.

### Task 2.2: Implement the Swift generator -- core type mapping

**Agent:** general-purpose
**Depends on:** 2.1, 0.1, 0.3
**Blocks:** 2.3, 2.4, 2.5
**Deliverable:** `xdr-generator/generator/generator.rb` with working struct, enum, and typedef generation

Implement `Generator < Xdrgen::Generators::Base` with the following methods. Use the Python SDK generator as structural reference but emit Swift syntax matching the current iOS SDK patterns.

**Swift-specific encoding pattern (current SDK uses `Codable` / `XDRCodable`):**

For structs:
```swift
public struct {Name}XDR: XDRCodable, Equatable, Sendable {
    public var {field}: {Type}

    public init({field}: {Type}, ...) {
        self.{field} = {field}
        ...
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        {field} = try container.decode({Type}.self)
        ...
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode({field})
        ...
    }
}
```

**Field mutability:** All generated struct fields use `public var` (not `public let`). The current hand-maintained code mixes `let` and `var` for different fields. Using `var` uniformly is the safe choice -- it matches the most permissive existing pattern and prevents compilation failures where existing code mutates a field.

For enums (simple, with raw values):
```swift
public enum {Name}: Int32, XDRCodable, Equatable, Sendable {
    case {member} = {value}
    ...
}
```

For unions (enums with associated values):
```swift
public enum {Name}XDR: XDRCodable, Equatable, Sendable {
    case {arm}({AssociatedType})
    case {voidArm}  // no associated value for void arms

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        switch discriminant {
        case {DiscriminantEnum}.{caseName}.rawValue:
            ...
        }
    }

    public func type() -> Int32 { ... }

    public func encode(to encoder: Encoder) throws { ... }
}
```

Methods to implement in order:
1. `generate` -- entry point, loads `SKIP_TYPES` list, `NAME_OVERRIDES` map, and `MEMBER_OVERRIDES` map
2. `render_definitions` / `render_definition` -- dispatch by AST type, skip types in `SKIP_TYPES`
3. `render_enum` -- simple enums with Int32 raw values
4. `render_struct` -- structs with XDRCodable
5. `render_typedef` -- type aliases (e.g., `typedef opaque Hash[32]` -> `WrappedData32`)
6. `render_const` -- constants
7. Type mapping: `type_string`, `encode_type`, `decode_type` -- applies `NAME_OVERRIDES` for output names
8. File header with auto-generated warning
9. `swift_safe_name` -- backtick-escapes Swift reserved words (see below)
10. `swift_enum_case_name(xdr_name, type_name)` -- converts XDR SCREAMING_SNAKE_CASE to Swift camelCase with MEMBER_OVERRIDES lookup (see below)

**Name override support:**
The generator loads `NAME_OVERRIDES` and `MEMBER_OVERRIDES` from `generator/name_overrides.rb` and `generator/member_overrides.rb` (produced by Task 0.3). Every type name lookup passes through `NAME_OVERRIDES`. The default behavior appends `XDR` suffix to all type names; the override map handles exceptions.

For enum case names and union arm names, the generator uses `swift_enum_case_name(xdr_name, type_name)`:
1. Apply mechanical `SCREAMING_SNAKE_CASE -> camelCase` conversion (strip common prefix, lowercase first letter, camelCase remaining)
2. Check `MEMBER_OVERRIDES[type_name][xdr_name]` -- if an override exists, use it instead
3. Apply `swift_safe_name()` for reserved word backtick-escaping

This function is used in `render_enum` (enum case names), `render_union` (union arm names), and when referencing SKIP_TYPES discriminant members (e.g., xdrgen's `MEMO_NONE` -> Swift's `MEMO_TYPE_NONE`).

**Swift reserved word handling:**
Implement a `SWIFT_RESERVED_WORDS` set and a `swift_safe_name(identifier)` method. When an XDR identifier collides with a Swift keyword, wrap it in backticks:
```ruby
SWIFT_RESERVED_WORDS = %w[
  associatedtype class deinit enum extension fileprivate func import init inout
  internal let open operator private precedencegroup protocol public rethrows
  static struct subscript typealias var break case catch continue default defer
  do else fallthrough for guard if in repeat return self Self super switch throw
  try where while as Any catch false is nil throws true
].to_set.freeze

def swift_safe_name(name)
  SWIFT_RESERVED_WORDS.include?(name) ? "`#{name}`" : name
end
```

**Critical Swift-specific type mappings:**

| XDR type | Swift type |
|---|---|
| int | Int32 |
| unsigned int | UInt32 |
| hyper | Int64 |
| unsigned hyper | UInt64 |
| bool | Bool |
| opaque<> (variable) | Data |
| opaque[N] (fixed, N=4) | WrappedData4 |
| opaque[N] (fixed, N=12) | WrappedData12 |
| opaque[N] (fixed, N=16) | WrappedData16 |
| opaque[N] (fixed, N=32) | WrappedData32 |
| opaque[N] (fixed, other) | Data (with fixed decode) |
| string<> | String |
| T* (optional) | T? (using optional-as-array encoding for struct members) |
| T<> (variable array) | [T] (using decodeArray helper) |
| T[N] (fixed array) | [T] (with fixed count) |

**Array encoding pattern (current SDK):**
- Variable arrays are encoded by the Array XDRCodable extension (prefix + elements)
- Decoding uses the `decodeArray(type:dec:)` free function
- Optional fields: encode via `container.encode(optionalField)` (the existing `Optional: XDREncodable` extension handles the 0/1 prefix automatically), decode via `decodeArray(type: T.self, dec: decoder).first`
- Do NOT double-wrap optionals in arrays for encoding. The infrastructure already handles it.

**Protocol conformance:**
- All generated structs: `XDRCodable, Equatable, Sendable`
- All generated enums (simple): `Int32, XDRCodable, Equatable, Sendable`
- All generated enums (unions): `XDRCodable, Equatable, Sendable`
- Swift auto-synthesizes `Equatable` for structs and enums when all members are `Equatable`. This is a safe, additive conformance (not a breaking change).
- **PublicKey Equatable prerequisite:** `PublicKey` is a `final class` that does NOT conform to `Equatable`. Generated types that reference `PublicKey` as a field (e.g., `Alpha4XDR`, `Alpha12XDR`, `SetOptionsOperationXDR`) will fail to auto-synthesize `Equatable`. **Fix:** Add `Equatable` conformance to `PublicKey` (comparing on `bytes` buffer). This is a safe, additive change. Task 0.1 must verify no other non-`Equatable` types are referenced by generated structs.
- No `var` properties with reference-type values in generated structs
- No `class` output from the generator (classes are hand-maintained only)

### Task 2.3: Implement the Swift generator -- union handling

**Agent:** general-purpose
**Depends on:** 2.2
**Blocks:** 2.6
**Deliverable:** Working union generation including recursive types

Implement `render_union` handling all union patterns found in the iOS SDK:

1. **Standard unions** (enum discriminant with associated values): e.g., `MemoXDR`, `OperationBodyXDR`, `LedgerKeyXDR`
2. **Integer-discriminated unions** (Int32 discriminant, not enum): e.g., `TransactionExtXDR`, `SorobanResourcesExt`
3. **Unions with void arms**: e.g., `.native` in `AssetXDR`, `.void` in extensions
4. **Unions with default arm**: some unions have a `default:` case
5. **Recursive/indirect unions**: The following types use `indirect enum` in the current SDK:
   - `ClaimPredicateXDR` -- arms contain `[ClaimPredicateXDR]` and `ClaimPredicateXDR?`. Technically `indirect` is not required here (recursion goes through `Array` and `Optional`, which are heap-allocated), but the current SDK uses it and the generator must match.
   - `SCSpecTypeDefXDR` -- arms reference `SCSpecTypeOptionXDR.valueType: SCSpecTypeDefXDR`, a direct value-type recursion that genuinely requires `indirect`.

   Types that do NOT need `indirect` (and the current SDK does not use it):
   - `SCValXDR` -- recursion is only through `[SCValXDR]?` and `[SCMapEntryXDR]?` (arrays/optionals are heap-allocated, so `indirect` is unnecessary). The current SDK defines it as `public enum SCValXDR` (not `indirect`). The generator must NOT add `indirect` here.

For recursive types, emit `public indirect enum` when the current SDK uses it. The generator must match the existing `indirect` usage to preserve API compatibility.

Detection heuristic for `indirect`:
- A type requires `indirect` when an enum case stores the same type (or a type containing it) as a **direct value-type field** -- not wrapped in `Array`, `Optional`, or other heap-allocated containers.
- Recursion only through `[T]` or `T?` does NOT require `indirect` because Swift arrays and optionals are heap-allocated.
- To match the current SDK exactly: use `indirect` for `ClaimPredicateXDR` and `SCSpecTypeDefXDR`. Do NOT use `indirect` for `SCValXDR`.
- For any new types added in future XDR updates: use DFS/BFS cycle detection on the AST type graph, but only mark as `indirect` if the cycle goes through a direct value-type path (not through arrays or optionals).

**Union discriminant patterns to handle:**
- Discriminant is a defined enum type -> use `.rawValue` for encoding
- Discriminant is `int` -> use integer literal cases
- Discriminant is a typedef of unsigned int (e.g., `Uint32`) -> special handling needed

### Task 2.4: Implement the Swift generator -- typedef and opaque handling

**Agent:** general-purpose
**Depends on:** 2.2
**Blocks:** 2.6
**Deliverable:** Working typedef generation including WrappedData mapping

Handle the special typedef cases:

1. `typedef opaque Hash[32]` -> should map to `WrappedData32` (or typealias)
2. `typedef opaque uint256[32]` -> `WrappedData32`
3. `typedef opaque Value<>` -> `Data`
4. `typedef unsigned int uint32` -> `typealias` or wrapper
5. `typedef int int32` -> `typealias`
6. `typedef unsigned hyper uint64` -> `typealias`
7. `typedef opaque AssetCode4[4]` -> `WrappedData4`
8. `typedef opaque AssetCode12[12]` -> `WrappedData12`
9. `typedef PublicKey AccountID` -> `typealias`

10. `typedef opaque Signature<64>` -> `Data` (variable-length, max 64 bytes)
11. `typedef opaque SignatureHint[4]` -> `WrappedData4`

**Fixed opaque sizing strategy:**
- `opaque[4]` -> `WrappedData4`
- `opaque[12]` -> `WrappedData12`
- `opaque[16]` -> `WrappedData16` (new -- add to `DataTypes.swift` following the existing pattern. Used by `PeerAddressIp.ipv6` in `Stellar-overlay.x` and `HmacSha256Key.seed` in `Stellar-types.x`.)
- `opaque[32]` -> `WrappedData32`
- `opaque[N]` for other N -> Generate a `WrappedDataN` type or use inline fixed-size decode. Audit the `.x` files during Task 0.1 to enumerate all fixed-opaque sizes used. If additional sizes beyond 4/12/16/32 appear as *fixed-length* (not variable-length with max), add corresponding `WrappedDataN` types to `DataTypes.swift`.
- `opaque<N>` (variable-length with max) -> `Data` (existing XDR extension handles length prefix + padding)

The generator must decide when to emit a `typealias` vs. a wrapper struct. Current iOS SDK uses `WrappedData` protocol conformers for fixed opaque, and relies on Swift primitive types for numeric typedefs.

### Task 2.5: Implement the Swift generator -- array and optional encoding

**Agent:** general-purpose
**Depends on:** 2.2
**Blocks:** 2.6
**Deliverable:** Correct array and optional encoding/decoding in generated code

Handle encoding patterns:

1. **Variable-length arrays** (`T<N>` or `T<>`):
   - Encode: use the `Array: XDRCodable` extension (writes count + elements automatically)
   - Decode: use `decodeArray(type: T.self, dec: decoder)` free function

2. **Fixed-length arrays** (`T[N]`):
   - Encode: iterate and encode each element (no count prefix)
   - Decode: loop N times and decode each element

3. **Optional fields** (`T*`):
   - Encode: `try container.encode(optionalField)` -- the existing `Optional: XDREncodable` extension in `XDRCodableExtensions.swift` handles the 0/1 discriminant prefix automatically. Do NOT manually wrap in arrays.
   - Decode: `optionalField = try decodeArray(type: T.self, dec: decoder).first`
   - Reference: see `ClaimPredicateXDR.claimPredicateNot` and `SetOptionsOperationXDR` for the canonical encode/decode pattern
   - **Note:** Two encoding patterns exist in the current SDK. Pattern A (used by `SetOptionsOperationXDR`, `ClaimPredicateXDR`): `container.encode(optionalField)`. Pattern B (used by `OperationXDR`, `TransactionV0XDR`): manual array wrapping (`container.encode([value])` / `container.encode([T]())`). Both produce identical XDR wire format because XDR optionals ARE encoded as 0-or-1 element arrays. The generator uses Pattern A exclusively. Pattern B only appears in hand-maintained files.

4. **Variable-length opaque** (`opaque<N>`):
   - Uses `Data` which already has XDRCodable conformance with padding

5. **Variable-length string** (`string<N>`):
   - Uses `String` which already has XDRCodable conformance

### Task 2.5b: Implement decode-path safety (size validation)

**Agent:** general-purpose
**Depends on:** 2.5
**Blocks:** 2.6
**Deliverable:** Decode safety features as infrastructure change + generated code awareness

The Java SDK uses `maxDepth` parameters on every decode method. The Python SDK validates array lengths against remaining buffer size. The Swift SDK must include equivalent protections.

**Size validation for variable-length arrays (infrastructure change):**
Add a bounds check to BOTH `decodeArray(type:dec:)` AND `decodeArrayOpt(type:dec:)` functions in `XDRCodableExtensions.swift`. Both functions decode a count prefix and iterate, so both need the same protection. This is a one-time infrastructure fix that protects ALL array decoding (both generated and hand-maintained types) uniformly:
```swift
func decodeArray<T: Codable>(type: T.Type, dec: Decoder, maxCount: UInt32 = 100_000) throws -> [T] {
    var container = try dec.unkeyedContainer()
    let count = try container.decode(UInt32.self)
    guard count <= maxCount else {
        throw StellarSDKError.xdrDecodingError(message: "Array count \(count) exceeds maximum \(maxCount)")
    }
    // ... existing decode loop
}
```
The generated code does not need per-field bounds checks since `decodeArray()` handles it. For fields with explicit max sizes in the `.x` definition (e.g., `signers<MAX_SIGNERS>`), the generator can pass the declared max as the `maxCount` argument.

**Depth limiting for recursive types:**
The proposed `init(from decoder: Decoder, depth: Int)` approach is NOT compatible with Swift's Codable infrastructure. The `init(from: Decoder)` protocol requirement is called by the Codable infrastructure (e.g., `container.decode(T.self)`), and there is no way to pass extra parameters through this call chain. The depth parameter would never propagate to recursive calls.

Instead, rely on the existing `XDRDecoder`'s natural protection: the decoder operates on a finite byte buffer and throws `prematureEndOfData` when the buffer is exhausted. This inherently limits recursion depth for any input -- a malicious payload cannot cause infinite recursion because each recursive decode consumes bytes.

**Deferred hardening (follow-up task, not blocking):** For additional protection against stack overflow from deeply nested but syntactically valid XDR, consider threading a depth counter through `Decoder.userInfo`:
```swift
// In XDRDecoder:
static let depthKey = CodingUserInfoKey(rawValue: "xdrDecodeDepth")!
// In generated init(from:):
let depth = (decoder.userInfo[XDRDecoder.depthKey] as? Int) ?? 0
guard depth < 200 else { throw ... }
// Before recursive decode: set depth + 1 in a child decoder
```
This requires modifying `XDRDecoder` to support userInfo propagation and is tracked as a separate follow-up task, not a blocker for initial generation.

### Task 2.6: Implement file-per-type output and constants

**Agent:** general-purpose
**Depends on:** 2.3, 2.4, 2.5, 2.5b
**Blocks:** 2.7
**Deliverable:** Generator produces one `.swift` file per top-level XDR type

**Note on file organization change:** The current SDK groups multiple types per file (e.g., `TransactionXDR.swift` contains 23 type declarations). The generated output uses one file per top-level type, matching the Python/Java/KMP pattern. This is an internal organization change, not a public API change -- Swift does not expose file boundaries to consumers.

Design decisions:
- One file per top-level type, NOT one file per `.x` source
- Nested definitions (e.g., `FeeBumpTransactionXDR.InnerTransactionXDR`) stay in the parent type's file
- Constants go into a separate `XDRConstants.swift` file
- File naming: `{TypeName}.swift` where TypeName comes from NAME_OVERRIDES (the generator controls the name)
- Types in `SKIP_TYPES` are not generated (hand-maintained files provide them)
- Each file starts with:
```swift
// Automatically generated by xdrgen
// DO NOT EDIT or your changes may be overwritten

import Foundation
```

### Task 2.7: Full generation dry-run against Stellar XDR definitions

**Agent:** general-purpose
**Depends on:** 2.6
**Blocks:** Review checkpoint 2
**Deliverable:** Complete set of generated files in `stellarsdk/stellarsdk/xdr/`

1. Fetch all `.x` files from `stellar/stellar-xdr` at the pinned commit
2. Run the generator against them
3. Output to `stellarsdk/stellarsdk/xdr/` (new directory, separate from current `responses/xdr/`)
4. Record: file count, total line count, any generation errors
5. Attempt `swift build` with BOTH old and new XDR directories (expect name conflicts -- this is informational only)

### Review checkpoint 2

**Agent:** code-reviewer
**Blocks:** Phase 3
**Input:** Generated files from 2.7, generator source from 2.2-2.6, SKIP_TYPES list, NAME_OVERRIDES map
**Criteria:**
- Generator handles all XDR construct types (struct, enum, union, typedef, const)
- Generated code follows existing SDK patterns exactly (XDRCodable, unkeyedContainer, etc.)
- `Sendable` conformance on all generated types (structs and enums)
- `indirect enum` matches current SDK: used for `ClaimPredicateXDR` and `SCSpecTypeDefXDR`; NOT used for `SCValXDR` (recursion through arrays/optionals only)
- Types in SKIP_TYPES are NOT present in generated output
- Generated type names match current SDK names via NAME_OVERRIDES (no breaking changes)
- WrappedData types used correctly for fixed-size opaque
- Optional encoding uses `container.encode(optionalField)` for encode, `decodeArray(...).first` for decode (no double-wrapping)
- Array encoding uses decodeArray() helper
- Decode-path safety: `decodeArray()` infrastructure has size validation (not per-field generated checks)
- Generated struct fields use `public var`
- `Equatable` conformance on all generated types
- Swift reserved words are backtick-escaped where needed
- File header present on all generated files
- No helper/convenience code in generated files
- All generatable type declarations from the audit are present in generated output

---

## Phase 3: Snapshot tests and validation

**Goal:** Ensure the generator produces deterministic, correct output via snapshot testing and XDR round-trip tests.

### Task 3.1: Create snapshot test infrastructure

**Agent:** general-purpose
**Depends on:** 2.6
**Blocks:** 3.2
**Deliverable:** Working snapshot test suite in `xdr-generator/test/`

Copy the test infrastructure from the Python SDK:
- `generator_snapshot_test.rb` (adapted for Swift output)
- Fixture `.x` files in `test/fixtures/xdrgen/`
- Generate initial snapshots in `test/snapshots/`

Each fixture should exercise one XDR construct type:
- `struct.x` -- basic struct with various field types
- `enum.x` -- simple enum with int values
- `union.x` -- union with void arms, default arm, multiple cases
- `optional.x` -- optional fields
- `const.x` -- constant definitions
- `nesting.x` -- nested type definitions
- `keywords.x` -- Swift reserved words as identifiers (backtick escaping)
- `block_comments.x` -- XDR source comments preserved correctly (matches Python SDK fixture)
- `recursive.x` -- indirect enum detection for direct and transitive recursion
- `test.x` -- complex mixed definitions

Run: `UPDATE_SNAPSHOTS=1 bundle exec ruby test/generator_snapshot_test.rb` to populate snapshots.

### Task 3.2: Validate snapshots match expected Swift output

**Agent:** code-reviewer
**Depends on:** 3.1
**Blocks:** 3.3
**Criteria:**
- Each snapshot file is valid Swift syntax
- Struct snapshots have correct init, encode, decode
- Union snapshots handle all arm patterns
- Optional encoding uses correct pattern
- Array encoding uses correct pattern

### Task 3.3: Create XDR round-trip unit tests in Swift

**Agent:** general-purpose
**Depends on:** 2.7
**Blocks:** Review checkpoint 3
**Deliverable:** Test file `stellarsdk/stellarsdkUnitTests/xdr/XDRGeneratedRoundTripTests.swift`

Write Swift unit tests that:
1. Create instances of key generated types with known values
2. Encode to XDR bytes
3. Decode back from XDR bytes
4. Assert equality

Test at minimum:
- A simple struct (e.g., PriceXDR equivalent)
- An enum (e.g., MemoType equivalent)
- A union with void arm (e.g., AssetXDR equivalent)
- A union with all non-void arms
- A recursive/indirect type (ClaimPredicateXDR equivalent)
- Optional fields (present and absent)
- Variable-length arrays
- Fixed-length opaque (WrappedData32)
- Variable-length opaque (Data)

**Binary compatibility test:** Additionally, create tests that encode a known type instance using the CURRENT hand-written implementation, capture the bytes, then verify the GENERATED implementation decodes those bytes correctly (and re-encodes to identical bytes). This catches subtle encoding differences between hand-written and generated code. Test at least: `AssetXDR`, `MemoXDR`, `PriceXDR`, and a struct with optional fields.

**Note on auto-synthesized vs explicit decode:** Some current types (e.g., `Alpha4XDR`, `Alpha12XDR`) rely on Swift's auto-synthesized `init(from:)` which uses keyed containers, while the generated version will use explicit `init(from:)` with `unkeyedContainer()`. Both produce identical wire output because `XDRDecoder` treats keyed and unkeyed containers identically (both read sequentially from the byte buffer). The binary compatibility tests will confirm this equivalence. Do not treat this difference as a bug.

### Task 3.4: Cross-validate against known XDR from the MCP tool

**Agent:** general-purpose
**Depends on:** 2.7
**Blocks:** Review checkpoint 3
**Deliverable:** Test that encodes/decodes real Stellar XDR against the MCP stellar-xdr tool

Use the MCP `stellar-xdr` tools to:
1. Encode a `TransactionEnvelope` from JSON to base64
2. In Swift, decode the same base64 using the generated types
3. Re-encode to base64 in Swift
4. Verify the base64 matches

This validates wire-compatibility with the canonical XDR implementation.

### Review checkpoint 3

**Agent:** code-reviewer
**Blocks:** Phase 4
**Criteria:**
- Snapshot tests pass: `bundle exec ruby test/generator_snapshot_test.rb`
- Round-trip tests pass: `swift test --filter stellarsdkUnitTests`
- MCP cross-validation produces matching XDR bytes
- No regressions in existing unit tests

---

## Phase 4: Switchover

**Goal:** Replace the hand-maintained XDR files with generated files and verify everything compiles and passes.

### Task 4.1: Create Makefile

**Agent:** general-purpose
**Depends on:** 2.7
**Blocks:** 4.2
**Deliverable:** `Makefile` in repo root

```makefile
.PHONY: xdr-clean-generated xdr-clean-all xdr-generate xdr-update xdr-generator-test xdr-generator-update-snapshots

XDRS = xdr/Stellar-SCP.x \
       xdr/Stellar-ledger-entries.x \
       xdr/Stellar-ledger.x \
       xdr/Stellar-overlay.x \
       xdr/Stellar-transaction.x \
       xdr/Stellar-types.x \
       xdr/Stellar-contract-env-meta.x \
       xdr/Stellar-contract-meta.x \
       xdr/Stellar-contract-spec.x \
       xdr/Stellar-contract.x \
       xdr/Stellar-internal.x \
       xdr/Stellar-contract-config-setting.x \
       xdr/Stellar-exporter.x

XDR_COMMIT = 4b7a2ef7931ab2ca2499be68d849f38190b443ca

xdr/%.x:
	curl -Lsf -o $@ https://raw.githubusercontent.com/stellar/stellar-xdr/$(XDR_COMMIT)/$(@F)

xdr-generate: $(XDRS)
	docker run --rm -v $(PWD):/wd -w /wd ruby:3.4.2 /bin/bash -c '\
		cd xdr-generator && \
		bundle install --quiet && \
		bundle exec ruby generate.rb'

# Remove only generated Swift files (preserves hand-maintained files and .x sources)
# Uses the "DO NOT EDIT" header to distinguish generated from hand-maintained files
xdr-clean-generated:
	grep -rl '// Automatically generated by xdrgen' stellarsdk/stellarsdk/xdr/ | xargs rm -f || true

# Remove everything: generated files AND downloaded .x definitions
xdr-clean-all:
	rm -f xdr/*.x || true
	rm -f stellarsdk/stellarsdk/xdr/*.swift || true

xdr-update: xdr-clean-all xdr-generate

xdr-generator-test:
	docker run --rm -v $(PWD):/wd -w /wd ruby:3.4.2 /bin/bash -c '\
		cd xdr-generator && \
		bundle install --quiet && \
		bundle exec ruby test/generator_snapshot_test.rb'

xdr-generator-update-snapshots:
	docker run --rm -v $(PWD):/wd -w /wd ruby:3.4.2 /bin/bash -c '\
		cd xdr-generator && \
		bundle install --quiet && \
		UPDATE_SNAPSHOTS=1 bundle exec ruby test/generator_snapshot_test.rb'
```

Note: Docker commands use `--rm` without `-it` for CI compatibility. The `-it` flags (interactive TTY) would cause CI failures. Use `docker run -it --rm` only for local interactive use.

### Task 4.2: Perform the switchover

**Agent:** general-purpose
**Depends on:** 4.1, 1.4
**Blocks:** 4.3
**Deliverable:** Repository compiles and tests pass with generated code

Steps:
1. Run `make xdr-update` to generate fresh files into `stellarsdk/stellarsdk/xdr/`
2. **Prepare hand-maintained files.** Many current files contain BOTH excluded types AND non-excluded types. Non-excluded types will be generated as separate files. Copying the entire original file would create duplicate definitions. For each hand-maintained file:
   - **If ALL types in the file are excluded** (e.g., `MuxedAccountXDR.swift` where both `CryptoKeyType` and `MuxedAccountXDR` are excluded): copy the file as-is.
   - **If the file contains a MIX of excluded and non-excluded types**: create a trimmed version containing ONLY the excluded type(s). Remove all type definitions that the generator provides.

   **Files requiring trimming (non-exhaustive -- Phase 0 audit will produce the definitive list):**
   - `TransactionXDR.swift`: 23 types, only 3 excluded (`TransactionXDR`, `TransactionSignaturePayload` + nested `TaggedTransaction`, `AccountEd25519Signature`). Remove the other ~20 types (e.g., `ContractIDPreimageXDR`, `InvokeContractArgsXDR`, `LedgerFootprintXDR`, `SorobanTransactionDataXDR`, `TransactionExtXDR`, etc.) -- they are generated separately.
   - `AssetXDR.swift`: 4 types, only `AssetType` excluded. Remove `Alpha4XDR`, `Alpha12XDR`, `AssetXDR` -- they are generated.
   - `AccountEntryXDR.swift`: 9 types, only `AccountFlags` excluded. Remove the other 8 types.
   - `MemoXDR.swift`: 2 types, only `MemoType` excluded. Remove `MemoXDR` -- it is generated.
   - `TrustlineEntryXDR.swift`: `TrustLineFlags` excluded. Remove all other types -- they are generated.
   - `ClaimableBalanceEntryXDR.swift`: `ClaimableBalanceFlags` excluded. Remove all other types.
   - `TransactionEnvelopeXDR.swift`: `EnvelopeType` excluded (plus `TransactionEnvelopeXDR` if excluded). Remove non-excluded types.

   **Files that can be copied as-is (all types excluded):**
   - `TransactionV0XDR.swift`, `FeeBumpTransactionXDR.swift`
   - `TransactionV1EnvelopeXDR.swift`, `TransactionV0EnvelopeXDR.swift`, `FeeBumpTransactionEnvelopeXDR.swift`
   - `MuxedAccountXDR.swift` (both `CryptoKeyType` and `MuxedAccountXDR` excluded)
   - `MuxedAccountMed25519XDR.swift` (both `MuxedAccountMed25519XDR` and `MuxedAccountMed25519XDRInverted` excluded/custom)

   **Types outside `responses/xdr/` -- nothing to copy:**
   - `OperationType` at `responses/operations_responses/OperationResponse.swift`
   - `PublicKey` at `crypto/PublicKey.swift`

3. Copy trimmed/as-is hand-maintained files into `stellarsdk/stellarsdk/xdr/`. Mark each with a "HAND-MAINTAINED" header.
4. Verify no duplicate type definitions between generated and hand-maintained files.
5. Update `Package.swift` if needed. Verify: Swift Package Manager includes sources recursively by default only if no explicit `sources` parameter is specified. If `Package.swift` has explicit source paths, add `xdr/` and `xdr_helpers/` to the list.
6. Rename `stellarsdk/stellarsdk/responses/xdr/` to `stellarsdk/stellarsdk/responses/xdr_legacy/` (temporary backup)
7. Verify `swift build` compiles with generated `xdr/` + hand-maintained files + helper `xdr_helpers/` (no legacy)
8. If compilation fails, identify missing types or name mismatches and fix the generator
9. Run `swift test --filter stellarsdkUnitTests`
10. If tests pass, delete `xdr_legacy/`
11. If tests fail, analyze failures and fix either the generator or the helper extraction

### Task 4.3: Fix compilation issues

**Agent:** general-purpose (with debugger backup)
**Depends on:** 4.2
**Blocks:** Review checkpoint 4
**Deliverable:** Clean build and all unit tests passing

Expected issues to resolve:
1. **Name mismatches**: Should be largely handled by NAME_OVERRIDES from Task 0.3. Any remaining mismatches found during compilation indicate gaps in the override map -- fix the map and regenerate.
2. **Multiple types per file**: Generated output has one file per type. Hand-maintained files (e.g., `TransactionXDR.swift`) may still contain multiple types. Verify no duplicate definitions between generated and hand-maintained files.
3. **EnvelopeType and AssetType**: These are on the exclusion list and hand-maintained. Verify they compile alongside generated code without name collisions.
4. **WrappedData mapping**: Ensure `Hash`, `uint256`, `AssetCode4`, `AssetCode12` correctly map to `WrappedData32`, `WrappedData4`, `WrappedData12`.
5. **PublicKey type**: `PublicKey` is used extensively and is a union in `.x` files. Verify the NAME_OVERRIDES map produces the correct Swift name.
6. **Sendable conformance**: All generated types must conform to `Sendable`. Structs and enums with value-type members get automatic conformance. Hand-maintained classes use `@unchecked Sendable` with `NSLock`. Verify no Swift 6 concurrency warnings.
7. **No breaking changes verification**: Run `swift build` and confirm zero errors. Grep the codebase for any references to types that changed names or structure. All existing call sites must work without modification.

### Review checkpoint 4

**Agent:** code-reviewer
**Blocks:** Phase 5
**Criteria:**
- `swift build` succeeds with zero errors and zero concurrency warnings
- `swift test --filter stellarsdkUnitTests` -- all tests pass
- No hand-written XDR serialization code remains in `responses/xdr/` (directory removed or empty)
- Generated files are in `stellarsdk/stellarsdk/xdr/`
- Hand-maintained excluded files are in `stellarsdk/stellarsdk/xdr/` alongside generated files
- Helper extensions are in `stellarsdk/stellarsdk/xdr_helpers/`
- `make xdr-generator-test` passes (snapshot tests)
- Generated files contain the "DO NOT EDIT" header
- Hand-maintained files contain a "HAND-MAINTAINED" header
- No breaking public API changes: all existing type names, method signatures, and property names preserved
- Envelope classes retain reference semantics (class, not struct)
- TransactionXDR/FeeBumpTransactionXDR/TransactionV0XDR retain `signatures` stored property
- All types conform to `Sendable` (generated: automatic; hand-maintained: `@unchecked Sendable`)
- `PublicKey` conforms to `Equatable` (prerequisite for generated types that reference it)
- All struct-with-constants types (AssetType, EnvelopeType, CryptoKeyType, MemoType, AccountFlags, TrustLineFlags, ClaimableBalanceFlags) are preserved as structs
- No `[UInt8]` to `WrappedData32` field type changes in any type (MuxedAccountXDR etc. are hand-maintained)

---

## Phase 5: CI integration and documentation

**Goal:** Integrate generation into CI and document the process.

### Task 5.1: Add CI workflow step

**Agent:** general-purpose
**Depends on:** 4.3
**Blocks:** 5.2
**Deliverable:** Updated `.github/workflows/tests.yml`

Add a CI step that runs snapshot tests. Since current CI runs on macOS with Xcode and Docker may not be available, use a Ruby setup step instead of Docker:
```yaml
- name: Set up Ruby
  uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.4'
    bundler-cache: true
    working-directory: xdr-generator
- name: Run XDR generator snapshot tests
  run: cd xdr-generator && bundle exec ruby test/generator_snapshot_test.rb
```

Optionally add a second step that verifies generated files are committed and up-to-date:
```yaml
- name: Verify generated XDR files are up-to-date
  run: |
    cd xdr-generator && bundle exec ruby generate.rb
    git diff --exit-code stellarsdk/stellarsdk/xdr/
```

### Task 5.2: Update .gitignore

**Agent:** general-purpose
**Depends on:** 4.3
**Deliverable:** Updated `.gitignore`

Add:
```
# XDR definition source files are fetched, not tracked
# (actually they should be tracked like the Python SDK does)
# xdr-generator vendor
xdr-generator/.bundle/
xdr-generator/vendor/
```

Do NOT gitignore:
- `xdr/*.x` -- these should be committed (matches Python SDK pattern)
- `stellarsdk/stellarsdk/xdr/*.swift` -- generated files are committed
- `xdr-generator/Gemfile.lock` -- should be committed for reproducibility

### Task 5.3: Final review and cleanup

**Agent:** code-reviewer
**Blocks:** Done
**Deliverable:** Final sign-off

Verify:
1. `make xdr-update` produces clean output
2. `make xdr-generator-test` passes
3. `swift build` succeeds
4. `swift test --filter stellarsdkUnitTests` passes
5. Generated file count matches expected (~200+ files for all XDR types)
6. No leftover temporary files or backup directories
7. `xdr-generator/audit/` directory can be removed or kept as reference
8. README or CONTRIBUTING.md updated with XDR update instructions

### Review checkpoint 5 (final)

**Agent:** code-reviewer
**Criteria:**
- Production ready: all tests pass, CI green
- Reproducible: `make xdr-clean && make xdr-generate` produces identical output
- Documented: developers know how to update XDR when upstream changes
- Rollback possible: git revert can restore pre-generation state

---

## Rollback strategy

If at any point the generated code produces incompatible output:

1. **Phase 1 rollback**: Revert helper extraction commits. The original XDR files are unchanged until Phase 4.
2. **Phase 2-3 rollback**: The generator is in a new directory (`xdr-generator/`). Delete it. No impact on existing code.
3. **Phase 4 rollback**: The `xdr_legacy/` backup exists until tests pass. If switchover fails:
   - Delete `stellarsdk/stellarsdk/xdr/`
   - Rename `xdr_legacy/` back to `responses/xdr/`
   - Move helpers back into XDR files (revert Phase 1 commits)
4. **Post-merge rollback**: `git revert` the merge commit. Generated and helper files revert to pre-generation state.

The key safety mechanism: **generated files go into a NEW directory** (`stellarsdk/stellarsdk/xdr/`), not into the existing `responses/xdr/`. The old files are only removed after the new ones are verified.

---

## Dependency graph

```
Phase 0: Audit
  0.1 (Explore) ----+
  0.2 (Explore) -+  |
  0.3 (Explore)  |  |
                 |  |
  Review 0 <-----+--+
                 |
Phase 1: Helper extraction
  1.1 (general) <--- 0.1, 0.2
  1.2 (general) <--- 1.1
  1.3 (general) <--- 1.2         [sequential: must compile cleanly after batch 1]
  1.4 (reviewer) <-- 1.3
  Review 1 <-------- 1.4

Phase 2: Generator                [can start after Review 0, parallel with Phase 1]
  2.1 (general) <--- 0.3
  2.2 (general) <--- 2.1
  2.3 (general) <--- 2.2
  2.4 (general) <--- 2.2         [2.3, 2.4, 2.5 can run in parallel]
  2.5 (general) <--- 2.2
  2.5b (general) <-- 2.5         [decode safety: size validation + depth limiting]
  2.6 (general) <--- 2.3, 2.4, 2.5b
  2.7 (general) <--- 2.6
  Review 2 <-------- 2.7

Phase 3: Tests                    [depends on Phase 2]
  3.1 (general) <--- 2.6
  3.2 (reviewer) <-- 3.1
  3.3 (general) <--- 2.7
  3.4 (general) <--- 2.7         [3.3 and 3.4 can run in parallel]
  Review 3 <-------- 3.2, 3.3, 3.4

Phase 4: Switchover               [depends on Phase 1 Review AND Phase 3 Review]
  4.1 (general) <--- 2.7
  4.2 (general) <--- 4.1, Review 1
  4.3 (general) <--- 4.2
  Review 4 <-------- 4.3

Phase 5: CI and docs              [depends on Phase 4 Review]
  5.1 (general) <--- 4.3
  5.2 (general) <--- 4.3         [5.1 and 5.2 can run in parallel]
  5.3 (reviewer) <-- 5.1, 5.2
  Review 5 <-------- 5.3
```

## Estimated effort

| Phase | Tasks | Estimated agent-hours |
|---|---|---|
| 0 - Audit | 3 + review | 4-6 |
| 1 - Helper extraction | 4 + review | 8-12 |
| 2 - Generator | 8 + review (includes 2.5b) | 18-26 |
| 3 - Tests | 4 + review | 6-8 |
| 4 - Switchover | 3 + review | 8-12 |
| 5 - CI/docs | 3 + review | 2-4 |
| **Total** | **25 + 6 reviews** | **46-68** |

## Checklist

### No-breaking-changes verification
- [ ] All existing public type names preserved (NAME_OVERRIDES applied correctly)
- [ ] All existing method signatures preserved (helpers in extensions match originals)
- [ ] All existing property names and types preserved
- [ ] Envelope classes retain `class` semantics with `NSLock` and `@unchecked Sendable`
- [ ] Transaction types retain `signatures` stored property
- [ ] All struct-with-constants types remain as structs: `AssetType`, `EnvelopeType`, `CryptoKeyType`, `MemoType`, `AccountFlags`, `TrustLineFlags`, `ClaimableBalanceFlags`
- [ ] `TransactionSignaturePayload` remains `XDREncodable`-only
- [ ] `AccountEd25519Signature` remains as-is (not generated, not modified)
- [ ] `PublicKey` is in SKIP_TYPES (type lives at `crypto/PublicKey.swift`)
- [ ] `OperationType` is in SKIP_TYPES (type lives at `responses/operations_responses/OperationResponse.swift`)
- [ ] All types defined outside `responses/xdr/` that match XDR definitions are identified and excluded
- [ ] `MuxedAccountXDR` and `MuxedAccountMed25519XDR` excluded (use `[UInt8]` instead of `WrappedData32`)
- [ ] All nested types in hand-maintained files are in `SKIP_TYPES` (no duplicate top-level definitions)
- [ ] `PublicKey` has `Equatable` conformance added (prerequisite for generated types referencing it)
- [ ] No call site in the SDK requires modification

### Swift 6 Sendable conformance
- [ ] All generated structs: `XDRCodable, Equatable, Sendable` (automatic for value types)
- [ ] All generated enums (simple): `Int32, XDRCodable, Equatable, Sendable`
- [ ] All generated enums (unions): `XDRCodable, Equatable, Sendable`
- [ ] Hand-maintained classes: `@unchecked Sendable` with `NSLock`-guarded mutation
- [ ] No mutable shared state in generated types
- [ ] No `var` properties with reference-type values in generated structs
- [ ] Swift 6 strict concurrency: zero warnings from `swift build`

### Generator correctness
- [ ] `indirect enum` matches current SDK usage: `ClaimPredicateXDR` (indirect), `SCSpecTypeDefXDR` (indirect), `SCValXDR` (NOT indirect -- recursion through arrays/optionals only)
- [ ] `XDRCodable` protocol conformance (combining `XDREncodable` & `XDRDecodable`)
- [ ] `Equatable` conformance on all generated types (auto-synthesized by Swift, requires all referenced types to also be `Equatable` -- including `PublicKey`)
- [ ] `unkeyedContainer`-based encoding/decoding pattern
- [ ] Generated struct fields use `public var` (not `public let`) to match existing mutation patterns
- [ ] Optional encode: `container.encode(optionalField)` (infrastructure handles 0/1 prefix)
- [ ] Optional decode: `decodeArray(type: T.self, dec: decoder).first`
- [ ] Both optional encoding patterns documented (Pattern A: direct encode, Pattern B: manual array wrapping -- both produce identical wire format)
- [ ] Variable arrays use `decodeArray(type:dec:)` free function
- [ ] Fixed opaque maps to `WrappedData4`/`WrappedData12`/`WrappedData16`/`WrappedData32`
- [ ] `WrappedData16` added to `DataTypes.swift` (for `opaque[16]` in overlay/types `.x` files)
- [ ] Variable opaque maps to `Data` with padding
- [ ] String maps to `String` with XDRCodable conformance
- [ ] Swift reserved words backtick-escaped (e.g., `` `default` ``, `` `self` ``)
- [ ] No `import UIKit` -- only `import Foundation`
- [ ] Generated files have "DO NOT EDIT" header
- [ ] Hand-maintained files have "HAND-MAINTAINED" header
- [ ] File names follow existing convention via NAME_OVERRIDES
- [ ] SKIP_TYPES list excludes all hand-maintained types, struct-with-constants types, `[UInt8]` mismatch types, nested types in hand-maintained files (e.g., `TransactionSignaturePayloadTaggedTransaction`, `FeeBumpTransactionInnerTx`, `FeeBumpTransactionExt`), AND types defined outside `responses/xdr/`
- [ ] `MEMBER_OVERRIDES` map covers ALL enum/union types with non-mechanical name conversions (known: `MemoType`, `OperationType`, `ClaimPredicateType`, `RevokeSponsorshipType`)
- [ ] Generator implements `swift_enum_case_name()` with mechanical conversion + MEMBER_OVERRIDES lookup for enum cases and union arms
- [ ] Hand-maintained files trimmed to contain ONLY excluded types (no duplicates with generated files)
- [ ] `decodeArray()` AND `decodeArrayOpt()` in `XDRCodableExtensions.swift` both have size validation (infrastructure change)
- [ ] Depth limiting deferred as follow-up (XDRDecoder buffer exhaustion provides natural protection)
- [ ] `xdr-clean-generated` Makefile target uses "DO NOT EDIT" header to distinguish generated files
- [ ] Binary compatibility test validates generated output matches current hand-written output byte-for-byte
- [ ] `Package.swift` source paths include `xdr/` and `xdr_helpers/` subdirectories
- [ ] Docker image pinned to specific version (ruby:3.4.2)
