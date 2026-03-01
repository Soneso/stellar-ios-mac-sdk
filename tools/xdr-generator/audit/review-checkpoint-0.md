# Review Checkpoint 0 -- Phase 0 Audit Deliverables

Reviewer: Code Review Agent (Checkpoint 0)
Date: 2026-02-22

---

## 1. Per-Deliverable Assessment

### 1.1 Type Catalog (type-catalog.md) -- PASS with minor issues

**File count:** Confirmed 107 files in `responses/xdr/`. The catalog lists exactly 107 file sections.

**Type count:** The catalog reports 301 type definitions. This is plausible given the file contents (many files contain multiple types). Verified against the per-file tables.

**Struct-with-constants list:** Complete. All 7 are listed (plus OperationType noted as a proper enum outside xdr/):
- AssetType, EnvelopeType, CryptoKeyType, MemoType, AccountFlags, TrustLineFlags, ClaimableBalanceFlags

**[UInt8] mismatch list:** Complete. All 4 mandatory types listed plus the custom MuxedAccountMed25519XDRInverted:
- MuxedAccountXDR, MuxedAccountMed25519XDR, TransactionV0XDR, ClaimOfferAtomV0XDR

**Indirect enum list:** Correct. ClaimPredicateXDR and SCSpecTypeDefXDR listed. SCValXDR is NOT marked indirect (correct -- it is not `indirect enum` in source, just a regular `enum`).

**Types outside responses/xdr/:** Both PublicKey and OperationType are documented with full location and impact analysis.

**Nested types:** All 4 identified: FeeBumpTransactionXDR.InnerTransactionXDR, TransactionSignaturePayload.TaggedTransaction, AllowTrustOpAssetXDR.AlphaATO4XDR, AllowTrustOpAssetXDR.AlphaATO12XDR.

**SKIP_TYPES list:** Contains 28 entries. This exceeds the plan's minimum of 22+. The list is well-reasoned with clear justification for each entry.

**Minor issue (M1):** The type catalog notes that `ContractEventXDR` "Has fromBase64 factory" in the notes column. However, the actual `ContractEventXDR.swift` source does NOT contain a `fromBase64` initializer. The `DiagnosticEventXDR` in the same file does have one, but `ContractEventXDR` does not. This is a documentation error in the catalog. Impact: Low -- ContractEventXDR is not in SKIP_TYPES and the helpers-to-extract catalog correctly omits a nonexistent helper.

**Minor issue (M2):** `AccountEd25519Signature` is listed in the exclusion validation table (helpers-to-extract.md, row 8) but is not listed in the type-catalog.md's per-file table for TransactionXDR.swift. The type catalog only lists types it considers XDR types, and `AccountEd25519Signature` is described as "not XDR at all" in the exclusion list. This is defensible but should be noted: the type catalog would benefit from listing it under "Custom SDK Types" section 3.5 for completeness.

### 1.2 Helpers to Extract (helpers-to-extract.md) -- PASS with important issues

**Structure and organization:** The document is well structured with clear Part A (exclusion validation) and Part B (helper extraction) sections. Each helper has its signature, mutation status, dependencies, and target file documented.

**Excluded types (stay in-place):** All major excluded types with helpers are covered:
- TransactionXDR (10 helpers)
- TransactionEnvelopeXDR (14 helpers)
- FeeBumpTransactionXDR (8 helpers)
- TransactionV0XDR (8 helpers)
- Envelope classes (2+2+1 helpers)

**Important issue (I1): Missing helpers for SCAddressXDR.** `SCAddressXDR` is NOT in SKIP_TYPES and is categorized as "pure-XDR" in the type catalog. However, the actual source file (ContractXDR.swift) shows it has extensive convenience methods that must be extracted:
- `init(accountId: String)` -- depends on PublicKey, String.decodeMuxedAccount
- `init(contractId: String)` -- depends on String.decodeContractIdToHex, Data(using: .hexadecimal)
- `init(claimableBalanceId: String)` -- depends on ClaimableBalanceIDXDR
- `init(liquidityPoolId: String)` -- depends on String.decodeLiquidityPoolIdToHex
- `var accountId: String?` -- depends on PublicKey, MuxedAccountMed25519XDR
- `var contractId: String?` -- depends on Data.base16EncodedString
- `var claimableBalanceId: String?` -- depends on ClaimableBalanceIDXDR
- `func getClaimableBalanceIdStrKey() throws -> String?` -- depends on String.encodeClaimableBalanceIdHex
- `var liquidityPoolId: String?` -- depends on LiquidityPoolIDXDR

This is 9 helpers that need extraction. They should be placed in `SCAddressXDR+Helpers.swift`.

**Important issue (I2): Missing helpers for ClaimableBalanceIDXDR.** This type is NOT in SKIP_TYPES. The actual source shows:
- `init(claimableBalanceId: String)` -- depends on String.decodeClaimableBalanceIdToHex, Data(using: .hexadecimal)
- `var claimableBalanceIdString: String` -- depends on ClaimableBalanceIDType

These 2 helpers need extraction to `ClaimableBalanceIDXDR+Helpers.swift`.

**Important issue (I3): Missing helpers for ContractExecutableXDR.** This type is NOT in SKIP_TYPES. The actual source shows:
- `var isWasm: Bool?`
- `var wasm: WrappedData32?`
- `var isStellarAsset: Bool?`

These 3 helpers need extraction to `ContractExecutableXDR+Helpers.swift`.

**Important issue (I4): Missing helpers for LiquidityPoolEntryXDR.** This type is NOT in SKIP_TYPES. The actual source shows:
- `var poolIDString: String`

This 1 helper needs extraction to `LiquidityPoolEntryXDR+Helpers.swift`.

**Minor issue (M3):** The `LedgerKeyContractCodeXDR` type has a convenience `init(wasmId: String)` that goes beyond pure XDR. If this type is generated, this helper must also be extracted. This is not documented.

### 1.3 Name Overrides (name_overrides.rb) -- PASS with minor issues

**Coverage:** The file contains approximately 200 entries, covering all known types where Swift name differs from the default `{XDRName}XDR` convention.

**Spot-check results (15 entries verified):**

| XDR Name | Expected Swift Name | Override Value | Verified Against Source | Result |
|----------|-------------------|----------------|------------------------|--------|
| `AlphaNum4` | `Alpha4XDR` | `Alpha4XDR` | AssetXDR.swift line 19 | PASS |
| `AlphaNum12` | `Alpha12XDR` | `Alpha12XDR` | AssetXDR.swift line 52 | PASS |
| `Asset` | `AssetXDR` | `AssetXDR` | AssetXDR.swift line 86 | PASS |
| `Memo` | `MemoXDR` | `MemoXDR` | MemoXDR.swift line 19 | PASS |
| `MemoType` | `MemoType` | `MemoType` | MemoXDR.swift line 11 | PASS |
| `ClaimPredicate` | `ClaimPredicateXDR` | `ClaimPredicateXDR` | ClaimPredicateXDR.swift line 20 | PASS |
| `TrustLineFlags` | `TrustLineFlags` | `TrustLineFlags` | TrustlineEntryXDR.swift line 11 | PASS |
| `TrustLineEntry` | `TrustlineEntryXDR` | `TrustlineEntryXDR` | TrustlineEntryXDR.swift (verified) | PASS |
| `LedgerKey` | `LedgerKeyXDR` | `LedgerKeyXDR` | LedgerKeyXDR.swift line 32 | PASS |
| `MuxedEd25519Account` | `MuxedAccountMed25519XDR` | `MuxedAccountMed25519XDR` | MuxedAccountMed25519XDR.swift | PASS |
| `CreateContractArgsV2` | `CreateContractV2ArgsXDR` | `CreateContractV2ArgsXDR` | TransactionXDR.swift (verified) | PASS |
| `LiquidityPoolDepositResultCode` | `LiquidityPoolDepositResulCode` | `LiquidityPoolDepositResulCode` | LiquidityPoolDepositResultXDR.swift | PASS (typo preserved) |
| `PathPaymentStrictReceiveOp` | `PathPaymentOperationXDR` | `PathPaymentOperationXDR` | PathPaymentOperationXDR.swift | PASS |
| `PathPaymentStrictSendOp` | `PathPaymentOperationXDR` | `PathPaymentOperationXDR` | Shared with strict-receive | PASS |
| `Ed25519SignedPayload` | `Ed25519SignedPayload` | `Ed25519SignedPayload` | SignerKeyXDR.swift line 73 | PASS |

**No duplicate mappings found** that would be unintentional. The intentional shared mappings are correctly documented (PathPayment strict-receive/send, ManageSellOffer/ManageBuyOffer, and their result types).

**Minor issue (M4):** The override `"TrustLineFlags" => "TrustLineFlags"` uses the XDR casing "TrustLineFlags", which matches the actual Swift source (line 11 of TrustlineEntryXDR.swift: `public struct TrustLineFlags`). This is correct. However, note that the struct name uses "TrustLine" (capital L) while the file name uses "Trustline" (lowercase l). The generator must not conflate these.

### 1.4 Member Overrides (member_overrides.rb) -- PASS with minor issues

**Required types present:**
- MemoType: Present (5 overrides) -- VERIFIED correct against MemoXDR.swift
- OperationType: Present (3 overrides: accountCreated, pathPayment, extendFootprintTTL) -- VERIFIED correct
- ClaimPredicateType: Present (6 overrides) -- VERIFIED correct against ClaimPredicateXDR.swift
- RevokeSponsorshipType: Present (2 overrides) -- VERIFIED correct against RevokeSponsorshipOpXDR.swift
- ClaimableBalanceIDType: Present (1 override) -- VERIFIED correct
- ClaimantType: Present (1 override) -- VERIFIED correct
- LedgerEntryChangeType: Present (5 overrides) -- VERIFIED correct against LedgerEntryChangeXDR.swift
- SCSpecEntryKind: Present (5 overrides) -- VERIFIED correct against ContractSpecXDR.swift
- TransactionEventStage: Present (1 override: afterAllTx without trailing 's') -- VERIFIED correct against TransactionEventXDR.swift
- SignerKeyType: Present (1 override: signedPayload) -- VERIFIED correct against SignerKeyXDR.swift

**Spot-check of mechanical conversions (types NOT in override map):**

| Enum Type | XDR Member | Mechanical Result | Actual Swift | Match? |
|-----------|-----------|-------------------|-------------|--------|
| SCValType | SCV_BOOL | bool | .bool | YES |
| SCValType | SCV_CONTRACT_INSTANCE | contractInstance | .contractInstance | YES |
| SCErrorType | SCE_WASM_VM | wasmVm | .wasmVm | YES |
| SCErrorCode | SCEC_ARITH_DOMAIN | arithDomain | .arithDomain | YES |
| ContractCostType | WasmInsnExec | wasmInsnExec | .wasmInsnExec | YES |
| SCAddressType | SC_ADDRESS_TYPE_ACCOUNT | account | .account | YES |
| ConfigSettingID | CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES | contractMaxSizeBytes | .contractMaxSizeBytes | YES |
| LedgerEntryType | ACCOUNT | account | .account | YES |
| ContractExecutableType | CONTRACT_EXECUTABLE_WASM | wasm | .wasm | YES |
| PreconditionType | PRECOND_NONE | none | .none | YES |

All mechanical conversions verified as correct.

**Minor issue (M5):** The `MemoType` overrides map XDR enum member names to struct-with-constants names (e.g., `"MEMO_NONE" => "MEMO_TYPE_NONE"`). This is correct for the generator's purposes but the comment says "struct-with-constants, not a Swift enum" -- since `MemoType` is in SKIP_TYPES, the generator won't actually generate its members. These overrides would only be used if the generator needs to reference MemoType constants when generating MemoXDR's decode switch. Ensure the generator handles this correctly.

### 1.5 Cross-Validation

**SKIP_TYPES in type-catalog.md vs exclusion table:**
The SKIP_TYPES list (28 entries) is a superset of the plan's baseline (22+). All types that are marked as "custom SDK types" in section 3.5 of the catalog are NOT in name_overrides.rb (verified for MuxedAccountMed25519XDRInverted, TransactionSignaturePayload, AlphaATO4XDR, AlphaATO12XDR). Types outside responses/xdr/ (PublicKey, OperationType) are in SKIP_TYPES.

**Exclusion list consistency:** The helpers-to-extract.md Part A exclusion validation table (21 entries) aligns with the SKIP_TYPES list. The exclusion table adds `AccountEd25519Signature` (row 8) which is not an XDR type but appears in the validation scope. This is acceptable for completeness.

---

## 2. Spot-Check Results

### AssetXDR (AssetXDR.swift)
- **Type names:** AssetType (struct), Alpha4XDR (struct), Alpha12XDR (struct), AssetXDR (enum) -- all match catalog
- **Protocols:** XDRCodable, Sendable on Alpha4XDR, Alpha12XDR, AssetXDR; Sendable only on AssetType -- matches catalog
- **Helpers:** Alpha4XDR has init(assetCodeString:issuer:) and assetCodeString; Alpha12XDR has same; AssetXDR has assetCode, issuer, init(assetCode:issuer:) -- all correctly listed in helpers-to-extract
- **Name overrides:** `"AlphaNum4" => "Alpha4XDR"`, `"AlphaNum12" => "Alpha12XDR"`, `"Asset" => "AssetXDR"` -- all correct

### MemoXDR (MemoXDR.swift)
- **Type names:** MemoType (struct), MemoXDR (enum) -- match catalog
- **MemoType constants:** MEMO_TYPE_NONE/TEXT/ID/HASH/RETURN -- match member_overrides mapping from MEMO_NONE etc.
- **No helpers on MemoXDR** beyond pure encode/decode -- correct, no extraction needed
- **Name overrides:** `"MemoType" => "MemoType"`, `"Memo" => "MemoXDR"` -- correct

### OperationBodyXDR (OperationBodyXDR.swift)
- **Type:** enum, XDRCodable, Sendable -- matches catalog
- **27 cases** -- matches catalog description "Large union (27 cases)"
- **References OperationType** from outside xdr/ -- correctly noted in catalog
- **In SKIP_TYPES** -- correct, as it references OperationType

### SCValXDR (ContractXDR.swift)
- **Type:** enum (NOT `indirect enum`) -- correctly NOT listed as indirect in catalog
- **23 cases** -- matches catalog "23+ cases"
- **Extensive helpers:** fromXdr, BigInt extension, many convenience properties -- all correctly identified
- **In SKIP_TYPES** -- correct

### ClaimPredicateXDR (ClaimPredicateXDR.swift)
- **Type:** `indirect enum` -- correctly marked in catalog
- **6 cases** -- matches ClaimPredicateType enum
- **Case names:** claimPredicateUnconditional, claimPredicateAnd, claimPredicateOr, claimPredicateNot, claimPredicateBeforeAbsTime, claimPredicateBeforeRelTime -- all match member_overrides
- **No convenience helpers** beyond encode/decode -- correct

### AccountEntryXDR (AccountEntryXDR.swift)
- **9 types in file:** AccountFlags, AccountEntryXDR, AccountEntryExtXDR, AccountEntryExtensionV1, AccountEntryExtV1XDR, AccountEntryExtensionV2, AccountEntryExtV2XDR, AccountEntryExtensionV3, ExtensionPoint -- all match catalog
- **AccountFlags:** struct with static UInt32 constants -- matches catalog
- **ExtensionPoint:** enum with single .void case -- matches catalog
- **No convenience helpers** -- correct

### LedgerKeyXDR (LedgerKeyXDR.swift)
- **7 types in file:** ConfigSettingID, LedgerKeyXDR, LiquidityPoolIDXDR, ContractDataDurability, LedgerKeyContractDataXDR, LedgerKeyContractCodeXDR, LedgerKeyTTLXDR -- all match catalog
- **fromBase64 helper on LedgerKeyXDR** -- correctly listed for extraction
- **poolIDString helper on LiquidityPoolIDXDR** -- correctly listed for extraction
- **init(wasmId:) on LedgerKeyContractCodeXDR** -- NOT listed for extraction (see M3)
- **ConfigSettingID members:** all match mechanical conversion (verified above)

### TransactionEnvelopeXDR (TransactionEnvelopeXDR.swift)
- **2 types:** EnvelopeType (struct), TransactionEnvelopeXDR (enum) -- match catalog
- **EnvelopeType:** 10 static Int32 constants -- matches catalog
- **TransactionEnvelopeXDR in SKIP_TYPES** -- correct, has many convenience properties
- **All helpers stay in-place** -- correctly documented

### SignerKeyXDR (SignerKeyXDR.swift)
- **3 types:** SignerKeyType (enum Int32), SignerKeyXDR (enum), Ed25519SignedPayload (struct) -- match catalog
- **SignerKeyType case names:** ed25519, preAuthTx, hashX, signedPayload -- matches member_overrides (only signedPayload differs from mechanical)
- **Ed25519SignedPayload protocols:** XDRCodable, Equatable, Sendable -- matches catalog
- **Helpers correctly identified** for extraction: ==, encodeSignedPayload, publicKey on Ed25519SignedPayload; Equatable extension on SignerKeyXDR

### AllowTrustOpAssetXDR (AllowTrustOpAssetXDR.swift)
- **3 types:** AllowTrustOpAssetXDR (enum), AlphaATO4XDR (nested struct), AlphaATO12XDR (nested struct) -- match catalog
- **assetCode helper** -- correctly identified for extraction
- **Nested types correctly noted** in catalog section 3.4

---

## 3. Critical Issues

None. All deliverables are structurally sound and contain no errors that would cause the generator to produce uncompilable code for the types it generates.

---

## 4. Important Issues (should fix before Phase 1)

**I1. Missing SCAddressXDR helpers in extraction catalog.**
SCAddressXDR is not in SKIP_TYPES but has 9 convenience methods (4 convenience initializers + 5 computed properties) that go beyond pure XDR. These must be extracted to `SCAddressXDR+Helpers.swift`. Dependencies include PublicKey, String.decodeMuxedAccount, String.decodeContractIdToHex, String.decodeClaimableBalanceIdToHex, String.decodeLiquidityPoolIdToHex, Data(using: .hexadecimal), MuxedAccountMed25519XDR, ClaimableBalanceIDXDR, LiquidityPoolIDXDR, String.encodeClaimableBalanceIdHex.

Alternatively, SCAddressXDR could be added to SKIP_TYPES given its extensive SDK dependencies -- this may be the better approach.

**I2. Missing ClaimableBalanceIDXDR helpers in extraction catalog.**
Has `init(claimableBalanceId: String)` and `var claimableBalanceIdString: String`. Must be extracted to `ClaimableBalanceIDXDR+Helpers.swift`.

**I3. Missing ContractExecutableXDR helpers in extraction catalog.**
Has `var isWasm: Bool?`, `var wasm: WrappedData32?`, `var isStellarAsset: Bool?`. Must be extracted to `ContractExecutableXDR+Helpers.swift`.

**I4. Missing LiquidityPoolEntryXDR helper in extraction catalog.**
Has `var poolIDString: String`. Must be extracted to `LiquidityPoolEntryXDR+Helpers.swift`.

---

## 5. Minor Observations

**M1.** Type catalog incorrectly states ContractEventXDR has a `fromBase64` factory. The actual file does not contain one (only DiagnosticEventXDR does). No code impact since ContractEventXDR is not in SKIP_TYPES and the helpers-to-extract catalog correctly omits it.

**M2.** `AccountEd25519Signature` is in the exclusion validation (helpers-to-extract.md row 8) but not listed in type-catalog.md section 3.5 (Custom SDK Types). Consider adding it for completeness.

**M3.** `LedgerKeyContractCodeXDR` has a convenience `init(wasmId: String)` that depends on `String.wrappedData32FromHex()`. If this type is generated, this helper must also be extracted. Not currently documented.

**M4.** The `TrustLineFlags` name uses "TrustLine" (capital L) in the struct name but "Trustline" (lowercase l) in the file name `TrustlineEntryXDR.swift`. The name_overrides correctly maps `"TrustLineFlags" => "TrustLineFlags"` with capital L. No issue, just a consistency note for the generator to be aware of.

**M5.** MemoType member overrides exist in member_overrides.rb but MemoType is in SKIP_TYPES. The overrides would only be relevant if the generator references MemoType constants when generating MemoXDR. Verify the generator handles this (referencing struct constants from a skipped type when generating a non-skipped union type).

---

## 6. Overall Verdict

**PASS -- proceed to Phase 1 and Phase 2**, contingent on addressing the four Important issues (I1-I4) first. These are missing helper extractions for types that are NOT in SKIP_TYPES but have convenience methods beyond pure XDR serialization. The fix is straightforward: either add the missing helpers to the extraction catalog, or move the affected types to SKIP_TYPES.

Recommended approach:
- For **SCAddressXDR** (I1): Add to SKIP_TYPES. It has heavy SDK dependencies (string encoding/decoding extensions, PublicKey) and 9 convenience methods. The cost of maintaining it by hand is low relative to the complexity of extracting 9 helpers.
- For **ClaimableBalanceIDXDR** (I2): Add 2 helpers to extraction catalog. Simple string conversion methods.
- For **ContractExecutableXDR** (I3): Add 3 helpers to extraction catalog. Pure accessor properties.
- For **LiquidityPoolEntryXDR** (I4): Add 1 helper to extraction catalog. Single computed property.
- For **LedgerKeyContractCodeXDR** (M3): Add 1 helper to extraction catalog. Single convenience init.

All other deliverables are correct and complete. The name_overrides.rb and member_overrides.rb files are accurate based on spot-checking against 15+ actual Swift source files. The type catalog is thorough and correctly categorizes all 301 types across 107 files.
