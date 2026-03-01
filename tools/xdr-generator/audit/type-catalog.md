# XDR Type Catalog -- iOS/macOS Stellar SDK

Generated for code-generation audit. This catalog drives the XDR generator and
determines which types are generated, skipped, or need special handling.

---

## 1. Summary Statistics

| Metric | Count |
|---|---|
| Total files in `responses/xdr/` | 107 |
| Total type definitions in `responses/xdr/` | 301 |
| Structs | 143 |
| Enums (union/discriminated) | 100 |
| Enums (Int32 result/type codes) | 51 |
| Classes (NSObject-based) | 3 |
| Indirect enums | 2 |
| Struct-with-static-constants (pseudo-enum) | 8 |
| Nested types | 4 |
| XDREncodable-only (not XDRCodable) | 5 |
| Custom SDK types (not in .x files) | 7 |
| Types using WrappedData4 | 5 |
| Types using WrappedData12 | 3 |
| Types using WrappedData32 | 36 |
| Types using `decodeArray()` | 37 |
| Types using `[UInt8]` for opaque[32] fields | 4 |
| Types outside `responses/xdr/` matching XDR names | 2 |

---

## 2. Per-File Type Table

### AccountEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `AccountFlags` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum implemented as struct with `static let` UInt32 constants. FLAGS: AUTH_REQUIRED_FLAG=1, AUTH_REVOCABLE_FLAG=2, AUTH_IMMUTABLE_FLAG=4, AUTH_CLAWBACK_ENABLED_FLAG=8 |
| `AccountEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData4 (thresholds), decodeArray (inflationDest, signers). Fields: let. References PublicKey. |
| `AccountEntryExtXDR` | enum | `XDRCodable, Sendable` | pure-XDR | v0/v1 extension union |
| `AccountEntryExtensionV1` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `AccountEntryExtV1XDR` | enum | `XDRCodable, Sendable` | pure-XDR | v0/v2 extension union |
| `AccountEntryExtensionV2` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (numSponsored, numSponsoring, signerSponsoringIDs) |
| `AccountEntryExtV2XDR` | enum | `XDRCodable, Sendable` | pure-XDR | v0/v3 extension union |
| `AccountEntryExtensionV3` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext, seqLedger, seqTime) |
| `ExtensionPoint` | enum | `XDRCodable, Sendable` | pure-XDR | Shared extension point used across many types |

### AccountMergeResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `AccountMergeResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `AccountMergeResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### AllowTrustOpAssetXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `AllowTrustOpAssetXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData4/WrappedData12 via nested types. Has convenience `assetCode` property. |
| `AllowTrustOpAssetXDR.AlphaATO4XDR` | struct (nested) | `XDRCodable, Sendable` | pure-XDR | Nested inside AllowTrustOpAssetXDR. Uses WrappedData4. |
| `AllowTrustOpAssetXDR.AlphaATO12XDR` | struct (nested) | `XDRCodable, Sendable` | pure-XDR | Nested inside AllowTrustOpAssetXDR. Uses WrappedData12. |

### AllowTrustOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `AllowTrustOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### AllowTrustResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `AllowTrustResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `AllowTrustResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### AssetXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `AssetType` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum as struct with `static let` Int32 constants. ASSET_TYPE_NATIVE=0, CREDIT_ALPHANUM4=1, CREDIT_ALPHANUM12=2, POOL_SHARE=3 |
| `Alpha4XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData4 (assetCode). Has convenience init(assetCodeString) and `assetCodeString` property. |
| `Alpha12XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData12 (assetCode). Has convenience init(assetCodeString) and `assetCodeString` property. |
| `AssetXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has convenience properties (assetCode, issuer) and convenience init methods. |

### BeginSponsoringFutureReservesOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `BeginSponsoringFutureReservesOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### BeginSponsoringFutureReservesResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `BeginSponsoringFutureReservesResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `BeginSponsoringFutureReservesResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### BumpSequenceOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `BumpSequenceOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### BumpSequenceResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `BumpSequenceResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `BumpSequenceResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ChangeTrustAssetXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ChangeTrustAssetXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has convenience properties (assetCode, issuer) |
| `LiquidityPoolParametersXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |

### ChangeTrustOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ChangeTrustOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ChangeTrustResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ChangeTrustResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ChangeTrustResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ClaimAtomXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClaimAtomType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ClaimAtomXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `ClaimOfferAtomXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ClaimOfferAtomV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses `[UInt8]` for sellerEd25519 (XDR: uint256). WrappedData32 used internally for codec. |
| `ClaimLiquidityAtomXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (liquidityPoolID). Fields: let |

### ClaimClaimableBalanceOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClaimClaimableBalanceOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ClaimClaimableBalanceResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClaimClaimableBalanceResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ClaimClaimableBalanceResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ClaimPredicateXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClaimPredicateType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ClaimPredicateXDR` | indirect enum | `XDRCodable, Sendable` | pure-XDR | RECURSIVE TYPE. Uses decodeArray for nested predicates. |

### ClaimableBalanceEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClaimableBalanceIDType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ClaimableBalanceFlags` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum as struct with `static let` UInt32 constant. CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG=1 |
| `ClaimableBalanceIDXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32. Has convenience `claimableBalanceIdString` property. |
| `ClaimableBalanceEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (claimants). Fields: let |
| `ClaimableBalanceEntryExtXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union |
| `ClaimableBalanceEntryExtensionV1` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ClaimantXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClaimantType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ClaimantXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `ClaimantV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ClawbackClaimableBalanceOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClawbackClaimableBalanceOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ClawbackClaimableBalanceResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClawbackClaimableBalanceResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ClawbackClaimableBalanceResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ClawbackOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClawbackOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ClawbackResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ClawbackResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ClawbackResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ContractEnvMetaXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SCEnvMetaKind` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCEnvMetaEntryXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |

### ContractEventXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ContractEventType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ContractEventXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (hash). Uses decodeArray (topics via nested body). Has fromBase64 factory. Fields: var (ext). |
| `ContractEventBodyV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (topics). Fields: let |
| `ContractEventBodyXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `DiagnosticEventXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Has fromBase64 factory. Fields: let |

### ContractMetaXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SCMetaKind` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCMetaV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCMetaEntryXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |

### ContractSpecXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SCSpecType` | enum (Int32) | `Int32, Sendable` | pure-XDR | Large enum (30+ cases) |
| `SCSpecTypeOptionXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecTypeResultXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecTypeVecXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecTypeMapXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecTypeBytesNXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecTypeTupleXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (valueTypes). Fields: let |
| `SCSpecTypeUDTXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecTypeDefXDR` | indirect enum | `XDRCodable, Sendable` | pure-XDR | RECURSIVE TYPE. Large union (30+ cases). |
| `SCSpecUDTStructFieldV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecUDTStructV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (fields). Fields: let |
| `SCSpecUDTUnionCaseVoidV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecUDTUnionCaseTupleV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (type). Fields: let |
| `SCSpecUDTUnionCaseV0Kind` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCSpecUDTUnionCaseV0XDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `SCSpecUDTUnionV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (cases). Fields: let |
| `SCSpecUDTEnumCaseV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecUDTEnumV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (cases). Fields: let |
| `SCSpecUDTErrorEnumV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (cases). Fields: let |
| `SCSpecFunctionInputV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecFunctionV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (inputs, outputs). Fields: let |
| `SCSpecEventV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (prefixTopics, params). Fields: let |
| `SCSpecEventDataFormat` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCSpecEventParamLocationV0` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCSpecEventParamV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCSpecEntryKind` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCSpecEntryXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |

### ContractXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SCValType` | enum (Int32) | `Int32, Sendable` | pure-XDR | Large enum (23 cases) |
| `SCErrorType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCErrorCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ContractCostType` | enum (Int32) | `Int32, Sendable` | pure-XDR | Large enum (~40 cases) |
| `SCErrorXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `SCAddressType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SCAddressXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (contract case). Has convenience properties (accountId, contractId, claimableBalanceId, liquidityPoolId). |
| `SCNonceKeyXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCValXDR` | enum | `XDRCodable, Sendable` | pure-XDR | LARGEST ENUM. 23+ cases. Uses decodeArray (vec, map). Has fromXdr factory, BigInt extension, many convenience properties (isBool, bool, isVoid, u32, i32, etc). |
| `SCMapEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ContractExecutableType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ContractExecutableXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (wasm hash). Has convenience properties (isWasm, wasm, isStellarAsset). |
| `Int128PartsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `UInt128PartsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `Int256PartsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `UInt256PartsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `SCContractInstanceXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (storage). Fields: let |

### CreateAccountOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `CreateAccountOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### CreateAccountResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `CreateAccountResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `CreateAccountResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### CreateClaimableBalanceOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `CreateClaimableBalanceOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (claimants). Fields: let |

### CreateClaimableBalanceResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `CreateClaimableBalanceResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `CreateClaimableBalanceResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### CreatePassiveOfferOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `CreatePassiveOfferOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### DataEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `DataEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### DecoratedSignatureXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `DecoratedSignatureXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData4 (hint). Fields: let |

### EndSponsoringFutureReservesResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `EndSponsoringFutureReservesResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `EndSponsoringFutureReservesResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ExtendFootprintTTLOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ExtendFootprintTTLOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext). |

### ExtendFootprintTTLResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ExtendFootprintTTLResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ExtendFootprintTTLResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### FeeBumpTransactionEnvelopeXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `FeeBumpTransactionEnvelopeXDR` | class (NSObject) | `NSObject, XDRCodable, @unchecked Sendable` | mixed (XDR + SDK) | CLASS, not struct. Thread-safe signature management with NSLock. Uses decodeArray (signatures). Has appendSignature method. |

### FeeBumpTransactionXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `FeeBumpTransactionXDR` | struct | `XDRCodable, Sendable` | mixed (XDR + SDK) | Has sign(), hash(), toEnvelopeXDR(), encodedEnvelope(), addSignature() convenience methods. private var signatures. Fields: let (except private var signatures). |
| `FeeBumpTransactionXDR.InnerTransactionXDR` | enum (nested) | `XDRCodable, Sendable` | pure-XDR | NESTED inside FeeBumpTransactionXDR. Would be top-level `FeeBumpTransactionInnerTx` in xdrgen output. |

### HashIDPreimageXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `HashIDPreimageXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `OperationID` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `RevokeID` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (liquidityPoolID). Fields: let |
| `HashIDPreimageContractIDXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (networkID). Fields: let |
| `HashIDPreimageSorobanAuthorizationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (networkID). Fields: let |

### InflationPayoutXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `InflationPayoutXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### InflationResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `InflationResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `InflationResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (inflationPayouts). Result union |

### InvokeHostFunctionOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `UploadContractWasmArgsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `FromEd25519PublicKeyXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (key, salt). Fields: let |
| `InvokeHostFunctionOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (auth). Fields: var (auth). |

### InvokeHostFunctionResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `InvokeHostFunctionResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `InvokeHostFunctionResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (success case). Result union |

### LedgerEntryChangeXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerEntryChangeType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `LedgerEntryChangeXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |

### LedgerEntryChangesXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerEntryChangesXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (ledgerEntryChanges). Fields: let |

### LedgerEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerEntryType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `TTLEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (keyHash). Fields: let |
| `LedgerEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Has fromBase64 factory. Fields: let |
| `LedgerEntryExtXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union. Uses decodeArray (commented out). |
| `LedgerEntryExtensionV1` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (signerSponsoringID). Fields: let |

### LedgerExtryDataXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerEntryDataXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Large union. Has fromBase64 factory. Has convenience properties (account, trustline, offer, data, etc). |
| `ContractDataEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ContractCodeEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (hash). Fields: let (hash), var (ext) |
| `ContractCodeCostInputsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext) |
| `ContractCodeEntryExtV1` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext) |
| `ContractCodeEntryExt` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union |
| `ConfigSettingContractBandwidthV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractComputeV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractHistoricalDataV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractLedgerCostV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractEventsV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ContractCostParamEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext) |
| `ContractCostParamsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (entries). Fields: let |
| `EvictionIteratorXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractParallelComputeV0` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractLedgerCostExtV0` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingSCPTiming` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingEntryXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Very large union. Uses decodeArray (liveSorobanStateSizeWindow). |
| `StateArchivalSettingsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigSettingContractExecutionLanesV0XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `ConfigUpgradeSetKeyXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (contractID, contentHash). Fields: let |

### LedgerKeyAccountXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerKeyAccountXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### LedgerKeyDataXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerKeyDataXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### LedgerKeyOfferXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerKeyOfferXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### LedgerKeyTrustlineXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LedgerKeyTrustLineXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### LedgerKeyXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ConfigSettingID` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `LedgerKeyXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Large union. Has fromBase64 factory. |
| `LiquidityPoolIDXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (liquidityPoolID). Has convenience poolIDString. Fields: let |
| `ContractDataDurability` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `LedgerKeyContractDataXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `LedgerKeyContractCodeXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (hash). Fields: let |
| `LedgerKeyTTLXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (keyHash). Fields: let |

### LiabilitiesXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LiabilitiesXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### LiquidityPoolDepositOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LiquidityPoolDepositOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (liquidityPoolID). Fields: let |

### LiquidityPoolDepositResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LiquidityPoolDepositResulCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | NOTE: typo in name ("Resul" not "Result") |
| `LiquidityPoolDepositResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### LiquidityPoolEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LiquidityPoolType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `LiquidityPoolEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (liquidityPoolID). Has convenience poolIDString. Fields: let |
| `LiquidityPoolBodyXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `ConstantProductXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `LiquidityPoolConstantProductParametersXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### LiquidityPoolWithdrawOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LiquidityPoolWithdrawOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (liquidityPoolID). Fields: let |

### LiquidityPoolWithdrawResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `LiquidityPoolWithdrawResulCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | NOTE: typo in name ("Resul" not "Result") |
| `LiquidityPoolWithdrawResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ManageDataOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ManageDataOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ManageDataResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ManageDataResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ManageDataResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ManageOfferOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ManageOfferOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### ManageOfferResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ManageOfferResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `ManageOfferResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### ManageOfferSuccessResult.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `ManageOfferEffect` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ManageOfferSuccessResultOfferXDR` | enum | `XDREncodable, Sendable` | pure-XDR | NOTE: XDREncodable only (not full XDRCodable). |
| `ManageOfferSuccessResultXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (offersClaimed). Fields: let (except var offer). |

### MemoXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `MemoType` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum as struct with `static let` Int32 constants. MEMO_TYPE_NONE=0, TEXT=1, ID=2, HASH=3, RETURN=4 |
| `MemoXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (hash, returnHash cases). |

### MuxedAccountMed25519XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `MuxedAccountMed25519XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses `[UInt8]` for sourceAccountEd25519 (XDR: uint256). WrappedData32 used internally for codec. Has convenience `accountId` property and `toMuxedAccountMed25519XDRInverted()`. Fields: let |
| `MuxedAccountMed25519XDRInverted` | struct | `XDRCodable, Sendable` | custom-SDK | NOT in .x files. Inverted field order (ed25519 before id) for muxed account encoding. Has `toMuxedAccountMed25519XDR()`. Fields: let |

### MuxedAccountXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `CryptoKeyType` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum as struct with `static let` Int32 constants. KEY_TYPE_ED25519=0, PRE_AUTH_TX=1, HASH_X=2, ED25519_SIGNED_PAYLOAD=3, MUXED_ED25519=0x100 |
| `MuxedAccountXDR` | enum | `XDRCodable, Sendable` | pure-XDR | .ed25519 case uses `[UInt8]` (XDR: uint256). WrappedData32 used internally. Has convenience properties (ed25519AccountId, accountId, id). |

### OfferEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `OfferEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### OperationBodyXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `OperationBodyXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Large union (27 cases). References `OperationType` from outside xdr/ directory. |

### OperationMetaV2XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `OperationMetaV2XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (events). Fields: let |

### OperationMetaXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `OperationMetaXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### OperationResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `OperationResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `OperationResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Large union |

### OperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `OperationXDR` | struct | `XDRCodable, Sendable` | mixed (XDR + SDK) | Uses decodeArray (sourceAccount optional). Has `setSorobanAuth()` mutating method. Fields: let (sourceAccount), var (body). |

### PathPaymentOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `PathPaymentOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (path). Fields: let |

### PathPaymentResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `PathPaymentResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `PathPaymentResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (offers in success case). Result union |

### PaymentOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `PaymentOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### PaymentResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `PaymentResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `PaymentResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### PreconditionsXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `PreconditionType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `PreconditionsXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `LedgerBoundsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `PreconditionsV2XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (timeBounds, ledgerBounds, sequenceNumber, extraSigners). Fields: let |

### PriceXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `PriceXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### RestoreFootprintOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `RestoreFootprintOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext). |

### RestoreFootprintResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `RestoreFootprintResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `RestoreFootprintResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### RevokeSponsorshipOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `RevokeSponsorshipType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `RevokeSponsorshipOpXDR` | enum | `XDRCodable, Sendable` | pure-XDR | |
| `RevokeSponsorshipSignerXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### RevokeSponsorshipResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `RevokeSponsorshipResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `RevokeSponsorshipResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### SetOptionsOperationXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SetOptionsOperationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray extensively (9 optional fields). Fields: let |

### SetOptionsResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SetOptionsResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `SetOptionsResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### SetTrustLineFlagsOpXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SetTrustLineFlagsOpXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### SetTrustLineFlagsResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SetTrustLineFlagsResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `SetTrustLineFlagsResultXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Result union |

### SignerKeyXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SignerKeyType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SignerKeyXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (ed25519, preAuthTx, hashX). Has `Equatable` extension. |
| `Ed25519SignedPayload` | struct | `XDRCodable, Equatable, Sendable` | pure-XDR | Uses WrappedData32 (ed25519). Fields: let |

### SignerXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SignerXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### SimplePaymentResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `SimplePaymentResultXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### TimeBoundsXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TimeBoundsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### TransactionEnvelopeXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `EnvelopeType` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum as struct with `static let` Int32 constants. 10 values (TX_V0 through SOROBAN_AUTHORIZATION). |
| `TransactionEnvelopeXDR` | enum | `XDRCodable, Sendable` | mixed (XDR + SDK) | Has fromBase64 factory. Many convenience properties (txSourceAccountId, txMuxedSourceId, txSeqNum, txTimeBounds, cond, sorobanTransactionData, txFee, txMemo, txOperations, txExt, txSignatures). Has txHash() and appendSignature() methods. |

### TransactionEventXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionEventStage` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `TransactionEventXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

### TransactionMetaV1XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionMetaV1XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (operations). Fields: let (txChanges), private var (operations) |

### TransactionMetaV2XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionMetaV2XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (operations). Fields: let (txChangesBefore, txChangesAfter), var (operations) |

### TransactionMetaV3XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionMetaV3XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (operations, sorobanMeta). Fields: var (ext, operations), let (txChangesBefore, txChangesAfter) |
| `SorobanTransactionMetaXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (events, diagnosticEvents). Fields: var (ext, events, returnValue) |
| `SorobanTransactionMetaExt` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union |
| `SorobanTransactionMetaExtV1` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (ext) |

### TransactionMetaV4XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionMetaV4XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (operations, sorobanMeta, events, diagnosticEvents). Fields: var (ext, operations, events), let (txChangesBefore, txChangesAfter) |
| `SorobanTransactionMetaV2XDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (returnValue). Fields: var (ext, returnValue) |

### TransactionMetaXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionMetaType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `TransactionMetaXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has fromBase64 factory. Uses decodeArray (operations in v0 case). Has convenience properties (transactionMetaV3, transactionMetaV4). |

### TransactionResultXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionResultCode` | enum (Int32) | `Int32, Sendable` | pure-XDR | Result code enum |
| `TransactionResultBodyXDR` | enum | `XDREncodable, Sendable` | pure-XDR | NOTE: XDREncodable only. |
| `InnerTransactionResultPair` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (hash). Fields: let |
| `TransactionResultXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (success/failed results). Has fromXdr factory. Fields: let |
| `InnerTransactionResultBodyXDR` | enum | `XDREncodable, Sendable` | pure-XDR | NOTE: XDREncodable only. |
| `InnerTransactionResultXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (success/failed results). Fields: let |

### TransactionSignaturePayload.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionSignaturePayload` | struct (internal) | `XDREncodable` | custom-SDK | NOT public. Internal only. XDREncodable only. Uses WrappedData32 (networkId). |
| `TransactionSignaturePayload.TaggedTransaction` | enum (nested, internal) | `XDREncodable` | custom-SDK | NOT public. Nested. Internal only. |

### TransactionV0EnvelopeXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionV0EnvelopeXDR` | class (NSObject) | `NSObject, XDRCodable, @unchecked Sendable` | mixed (XDR + SDK) | CLASS, not struct. Thread-safe with NSLock. Uses decodeArray (signatures). Has appendSignature(), txSourceAccountId. |

### TransactionV0XDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionV0XDR` | struct | `XDRCodable, Sendable` | mixed (XDR + SDK) | Uses `[UInt8]` for sourceAccountEd25519 (XDR: uint256). WrappedData32 used internally. Has sign(), hash(), toEnvelopeXDR(), encodedEnvelope(), addSignature(). Uses decodeArray (timeBounds, operations). private var signatures. Fields: let (except private var signatures). |

### TransactionV1EnvelopeXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionV1EnvelopeXDR` | class (NSObject) | `NSObject, XDRCodable, @unchecked Sendable` | mixed (XDR + SDK) | CLASS, not struct. Thread-safe with NSLock. Uses decodeArray (signatures). Has appendSignature(), txSourceAccountId. |

### TransactionXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TransactionXDR` | struct | `XDRCodable, Sendable` | mixed (XDR + SDK) | Has sign(), hash(), toEnvelopeXDR(), toEnvelopeV1XDR(), encodedEnvelope(), addSignature(). Uses decodeArray (operations). Fields: let (sourceAccount, seqNum), var (fee, cond, memo, operations, ext). |
| `ContractIDPreimageType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `ContractIDPreimageFromAddressXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (salt). Fields: var (address), let (salt) |
| `ContractIDPreimageXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has convenience properties (fromAddress, fromAsset). |
| `InvokeContractArgsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (args). Fields: let |
| `CreateContractArgsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `CreateContractV2ArgsXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (constructorArgs). Fields: let |
| `HostFunctionType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `HostFunctionXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has convenience properties (invokeContract, createContract, uploadContractWasm, createContractV2). |
| `SorobanAuthorizedFunctionType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SorobanAuthorizedFunctionXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has convenience properties (contractFn, contractHostFn, contractV2HostFn). |
| `SorobanAuthorizedInvocationXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (subInvocations). Fields: var (function, subInvocations) |
| `SorobanAddressCredentialsXDR` | struct | `XDRCodable, Sendable` | mixed (XDR + SDK) | Has appendSignature() mutating method. Fields: var (address, nonce, signatureExpirationLedger, signature) |
| `SorobanCredentialsType` | enum (Int32) | `Int32, Sendable` | pure-XDR | |
| `SorobanCredentialsXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Has convenience address property. |
| `SorobanAuthorizationEntryXDR` | struct | `XDRCodable, Sendable` | mixed (XDR + SDK) | Has sign() method, fromBase64 factory. Fields: var (credentials, rootInvocation) |
| `LedgerFootprintXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (readOnly, readWrite). Fields: var (readOnly, readWrite) |
| `InvokeHostFunctionSuccessPreImageXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (events). Fields: var (returnValue, events) |
| `SorobanResourcesXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: var (footprint, instructions, diskReadBytes, writeBytes) |
| `SorobanResourcesExtV0` | struct | `XDRCodable, Sendable` | pure-XDR | Uses decodeArray (archivedSorobanEntries). Fields: var (archivedSorobanEntries) |
| `SorobanResourcesExt` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union. Has convenience archivedSorobanEntries property. |
| `SorobanTransactionDataXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Has fromBase64 factory. Fields: var (ext, resources, resourceFee) |
| `TransactionExtXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union. Has convenience archivedSorobanEntries property. |

### TrustlineAssetXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TrustlineAssetXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Uses WrappedData32 (poolShare case). Has convenience properties (assetCode, issuer, poolId). |

### TrustlineEntryXDR.swift

| Type Name | Kind | Protocols | Category | Notes |
|---|---|---|---|---|
| `TrustLineFlags` | struct (static constants) | `Sendable` | pseudo-enum | XDR enum as struct with `static let` UInt32 constants. AUTHORIZED_FLAG=1, AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG=2, TRUSTLINE_CLAWBACK_ENABLED_FLAG=4 |
| `TrustlineEntryXDR` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `TrustlineEntryExtXDR` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union |
| `TrustlineEntryExtensionV1` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |
| `TrustlineEntryExtV1XDR` | enum | `XDRCodable, Sendable` | pure-XDR | Extension union |
| `TrustlineEntryExtensionV2` | struct | `XDRCodable, Sendable` | pure-XDR | Fields: let |

---

## 3. Special Patterns

### 3.1 Struct-with-Static-Constants (Pseudo-Enums)

These XDR enum types are implemented as structs with `static let` Int32/UInt32 constants instead of Swift enums. The generator must either preserve this pattern or convert to proper enums.

| Type Name | File | Constant Type | Values |
|---|---|---|---|
| `AssetType` | AssetXDR.swift | `Int32` | ASSET_TYPE_NATIVE=0, CREDIT_ALPHANUM4=1, CREDIT_ALPHANUM12=2, POOL_SHARE=3 |
| `EnvelopeType` | TransactionEnvelopeXDR.swift | `Int32` | TX_V0=0, SCP=1, TX=2, AUTH=3, SCPVALUE=4, TX_FEE_BUMP=5, OP_ID=6, POOL_REVOKE_OP_ID=7, CONTRACT_ID=8, SOROBAN_AUTHORIZATION=9 |
| `CryptoKeyType` | MuxedAccountXDR.swift | `Int32` | KEY_TYPE_ED25519=0, PRE_AUTH_TX=1, HASH_X=2, ED25519_SIGNED_PAYLOAD=3, MUXED_ED25519=0x100 |
| `MemoType` | MemoXDR.swift | `Int32` | NONE=0, TEXT=1, ID=2, HASH=3, RETURN=4 |
| `AccountFlags` | AccountEntryXDR.swift | `UInt32` | AUTH_REQUIRED_FLAG=1, AUTH_REVOCABLE_FLAG=2, AUTH_IMMUTABLE_FLAG=4, AUTH_CLAWBACK_ENABLED_FLAG=8 |
| `TrustLineFlags` | TrustlineEntryXDR.swift | `UInt32` | AUTHORIZED_FLAG=1, AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG=2, TRUSTLINE_CLAWBACK_ENABLED_FLAG=4 |
| `ClaimableBalanceFlags` | ClaimableBalanceEntryXDR.swift | `UInt32` | CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG=1 |
| `OperationType` | OperationResponse.swift (OUTSIDE xdr/) | `Int32` (proper Swift enum) | 27 cases, accountCreated=0 through restoreFootprint=26 |

NOTE: `OperationType` is actually a proper Swift enum with `Int32` rawValue, not a struct-with-constants. But it is defined outside `responses/xdr/` and its XDR name is defined in Stellar-types.x. It is used as the discriminant for `OperationBodyXDR`.

### 3.2 `[UInt8]` Mismatch with WrappedData32

These types use `[UInt8]` for fields that the XDR spec defines as `uint256` / `opaque[32]`. The generator would emit `WrappedData32` but the hand-maintained code uses raw byte arrays. WrappedData32 is still used internally for XDR encoding/decoding.

| Type Name | Field | XDR Type | Current Swift Type | File |
|---|---|---|---|---|
| `MuxedAccountXDR` | .ed25519 case | uint256 | `[UInt8]` | MuxedAccountXDR.swift |
| `MuxedAccountMed25519XDR` | sourceAccountEd25519 | uint256 | `[UInt8]` | MuxedAccountMed25519XDR.swift |
| `MuxedAccountMed25519XDRInverted` | sourceAccountEd25519 | n/a (custom) | `[UInt8]` | MuxedAccountMed25519XDR.swift |
| `TransactionV0XDR` | sourceAccountEd25519 | uint256 | `[UInt8]` | TransactionV0XDR.swift |
| `ClaimOfferAtomV0XDR` | sellerEd25519 | uint256 | `[UInt8]` | ClaimAtomXDR.swift |

### 3.3 Indirect Enums (Recursive Types)

| Type Name | File | Notes |
|---|---|---|
| `ClaimPredicateXDR` | ClaimPredicateXDR.swift | Recursive via `and([ClaimPredicateXDR])`, `or([ClaimPredicateXDR])`, `not(ClaimPredicateXDR?)` |
| `SCSpecTypeDefXDR` | ContractSpecXDR.swift | Recursive via option(SCSpecTypeDefXDR), result(ok/error of SCSpecTypeDefXDR), vec/map/tuple containing SCSpecTypeDefXDR |

### 3.4 Nested Types

Types defined inside other types, which xdrgen would emit as top-level types.

| Nested Type | Parent Type | File | Notes |
|---|---|---|---|
| `FeeBumpTransactionXDR.InnerTransactionXDR` | FeeBumpTransactionXDR | FeeBumpTransactionXDR.swift | xdrgen: `FeeBumpTransactionInnerTx` |
| `TransactionSignaturePayload.TaggedTransaction` | TransactionSignaturePayload | TransactionSignaturePayload.swift | Internal, not public. xdrgen: `TransactionSignaturePayloadTaggedTransaction` |
| `AllowTrustOpAssetXDR.AlphaATO4XDR` | AllowTrustOpAssetXDR | AllowTrustOpAssetXDR.swift | Nested struct for alphanum4 asset code |
| `AllowTrustOpAssetXDR.AlphaATO12XDR` | AllowTrustOpAssetXDR | AllowTrustOpAssetXDR.swift | Nested struct for alphanum12 asset code |

### 3.5 Custom SDK Types (Not in .x Files)

Types that exist in the hand-maintained XDR files but have no corresponding definition in the Stellar .x specification files.

| Type Name | File | Purpose |
|---|---|---|
| `MuxedAccountMed25519XDRInverted` | MuxedAccountMed25519XDR.swift | Inverted field order (ed25519 before id) for muxed account M-address encoding/decoding |
| `TransactionSignaturePayload` | TransactionSignaturePayload.swift | Internal struct for building signature payloads. XDREncodable only. |
| `TransactionSignaturePayload.TaggedTransaction` | TransactionSignaturePayload.swift | Internal nested enum for tagged transaction in signature payload |
| `AlphaATO4XDR` (nested) | AllowTrustOpAssetXDR.swift | Wrapper for 4-byte asset code in AllowTrust |
| `AlphaATO12XDR` (nested) | AllowTrustOpAssetXDR.swift | Wrapper for 12-byte asset code in AllowTrust |
| `UploadContractWasmArgsXDR` | InvokeHostFunctionOpXDR.swift | Helper struct; may correspond to partial XDR type |
| `FromEd25519PublicKeyXDR` | InvokeHostFunctionOpXDR.swift | Helper struct; may correspond to partial XDR type |

### 3.6 XDREncodable-Only Types (Not Full XDRCodable)

These types only implement encoding, not decoding. The generator produces full XDRCodable.

| Type Name | File | Notes |
|---|---|---|
| `TransactionResultBodyXDR` | TransactionResultXDR.swift | Encode-only union for result body |
| `InnerTransactionResultBodyXDR` | TransactionResultXDR.swift | Encode-only union for inner result body |
| `ManageOfferSuccessResultOfferXDR` | ManageOfferSuccessResult.swift | Encode-only union for offer result |
| `TransactionSignaturePayload` | TransactionSignaturePayload.swift | Internal encode-only struct |
| `TransactionSignaturePayload.TaggedTransaction` | TransactionSignaturePayload.swift | Internal encode-only nested enum |

### 3.7 Class Types (NSObject-Based)

These use `class` instead of `struct` for thread-safe mutable signatures via NSLock.

| Type Name | File | Base Class | Notes |
|---|---|---|---|
| `TransactionV0EnvelopeXDR` | TransactionV0EnvelopeXDR.swift | NSObject | `@unchecked Sendable`, NSLock for signatures |
| `TransactionV1EnvelopeXDR` | TransactionV1EnvelopeXDR.swift | NSObject | `@unchecked Sendable`, NSLock for signatures |
| `FeeBumpTransactionEnvelopeXDR` | FeeBumpTransactionEnvelopeXDR.swift | NSObject | `@unchecked Sendable`, NSLock for signatures |

### 3.8 Types with Convenience/SDK Methods (Beyond Pure XDR)

These types have methods that go beyond XDR serialization.

| Type Name | SDK Methods | File |
|---|---|---|
| `TransactionXDR` | sign(), hash(), toEnvelopeXDR(), toEnvelopeV1XDR(), encodedEnvelope(), addSignature() | TransactionXDR.swift |
| `TransactionV0XDR` | sign(), hash(), toEnvelopeXDR(), encodedEnvelope(), addSignature() | TransactionV0XDR.swift |
| `FeeBumpTransactionXDR` | sign(), hash(), toEnvelopeXDR(), toFBEnvelopeXDR(), encodedEnvelope(), addSignature() | FeeBumpTransactionXDR.swift |
| `TransactionEnvelopeXDR` | txHash(), appendSignature(), fromBase64, many computed properties | TransactionEnvelopeXDR.swift |
| `SorobanAuthorizationEntryXDR` | sign(), fromBase64 | TransactionXDR.swift |
| `SorobanAddressCredentialsXDR` | appendSignature() | TransactionXDR.swift |
| `OperationXDR` | setSorobanAuth() | OperationXDR.swift |
| `SCValXDR` | fromXdr(), BigInt extension (u128/i128/u256/i256 string/data conversion), many computed properties | ContractXDR.swift |

### 3.9 Types with Equatable Conformance

| Type Name | File |
|---|---|
| `Ed25519SignedPayload` | SignerKeyXDR.swift (declared on type) |
| `SignerKeyXDR` | SignerKeyXDR.swift (via extension) |

---

## 4. Types Outside `responses/xdr/`

### 4.1 PublicKey

- **Location:** `stellarsdk/stellarsdk/crypto/PublicKey.swift`
- **Kind:** `public final class PublicKey: XDRCodable, Sendable`
- **XDR Name:** `PublicKey` (defined in Stellar-types.x as a union on CryptoKeyType)
- **Notes:** This is a CLASS (not struct/enum). It wraps a 32-byte ed25519 key. It implements XDRCodable with discriminant Int32(0) for KEY_TYPE_ED25519. It has convenience methods for accountId, verify(). Referenced by many XDR types (AccountEntryXDR, ClaimOfferAtomXDR, SetOptionsOperationXDR, etc.). The XDR definition is a union but the SDK implements it as a class with only the ed25519 variant.
- **Impact:** Generator must NOT generate `PublicKey` -- it would conflict with this hand-maintained class.

### 4.2 OperationType

- **Location:** `stellarsdk/stellarsdk/responses/operations_responses/OperationResponse.swift`
- **Kind:** `public enum OperationType: Int32, Sendable`
- **XDR Name:** `OperationType` (defined in Stellar-types.x)
- **Notes:** Proper Swift enum with Int32 rawValue. 27 cases. Used by `OperationBodyXDR` as discriminant. Also used by SDK response layer.
- **Impact:** Generator must NOT generate `OperationType` -- it would conflict with this existing enum.

---

## 5. Recommended SKIP_TYPES List

Types the generator should NOT produce, with reasons.

| Type | Reason |
|---|---|
| `PublicKey` | Hand-maintained class at `crypto/PublicKey.swift`. Full custom implementation with accountId, verify, etc. |
| `OperationType` | Hand-maintained enum at `responses/operations_responses/OperationResponse.swift`. Used by both XDR and response layers. |
| `AssetType` | Struct-with-constants pseudo-enum. Referenced by AssetXDR, AllowTrustOpAssetXDR. Must be preserved as-is or carefully migrated. |
| `EnvelopeType` | Struct-with-constants pseudo-enum. Referenced by TransactionEnvelopeXDR, FeeBumpTransactionXDR, TransactionSignaturePayload. |
| `CryptoKeyType` | Struct-with-constants pseudo-enum. Referenced by MuxedAccountXDR, SignerKeyXDR. |
| `MemoType` | Struct-with-constants pseudo-enum. Referenced by MemoXDR. |
| `AccountFlags` | Struct-with-constants pseudo-enum. Referenced by AccountEntryXDR. These are bitmask flags, not discriminated enum values. |
| `TrustLineFlags` | Struct-with-constants pseudo-enum. Bitmask flags. |
| `ClaimableBalanceFlags` | Struct-with-constants pseudo-enum. Bitmask flags. |
| `MuxedAccountMed25519XDRInverted` | Custom SDK type not in .x files. |
| `TransactionSignaturePayload` | Custom SDK internal type not in .x files. |
| `TransactionSignaturePayload.TaggedTransaction` | Custom SDK internal nested type. |
| `AlphaATO4XDR` (nested) | Custom nested type inside AllowTrustOpAssetXDR. |
| `AlphaATO12XDR` (nested) | Custom nested type inside AllowTrustOpAssetXDR. |
| `TransactionV0EnvelopeXDR` | NSObject class with thread-safe signature management. Cannot be generated as struct. |
| `TransactionV1EnvelopeXDR` | NSObject class with thread-safe signature management. Cannot be generated as struct. |
| `FeeBumpTransactionEnvelopeXDR` | NSObject class with thread-safe signature management. Cannot be generated as struct. |
| `TransactionXDR` | Heavy SDK convenience methods (sign, hash, toEnvelope). Must be hand-maintained. |
| `TransactionV0XDR` | Heavy SDK convenience methods (sign, hash, toEnvelope). Uses [UInt8] for ed25519. |
| `FeeBumpTransactionXDR` | Heavy SDK convenience methods (sign, hash, toEnvelope). Contains nested InnerTransactionXDR. |
| `FeeBumpTransactionXDR.InnerTransactionXDR` | Nested type inside a skip type. |
| `TransactionEnvelopeXDR` | Heavy SDK convenience methods and properties. |
| `OperationXDR` | Has setSorobanAuth() mutating method. |
| `OperationBodyXDR` | References OperationType from outside xdr/. Large union, tightly coupled to SDK. |
| `SCValXDR` | Massive type with BigInt extension, many convenience properties, fromXdr factory. |
| `SorobanAuthorizationEntryXDR` | Has sign() method with crypto dependency. |
| `SorobanAddressCredentialsXDR` | Has appendSignature() mutating method. |
| `UploadContractWasmArgsXDR` | Custom SDK helper, uncertain .x mapping. |
| `FromEd25519PublicKeyXDR` | Custom SDK helper, uncertain .x mapping. |
| `ExtensionPoint` | Shared utility type used across many files. Simple but must be defined exactly once. |

### Types That ARE Safe to Generate

All types not in the skip list above, including:
- All `*ResultCode` enums (Int32 result codes)
- All `*ResultXDR` enums (result unions) -- except TransactionResultBodyXDR and InnerTransactionResultBodyXDR which are XDREncodable-only
- Most operation structs (`CreateAccountOperationXDR`, `PaymentOperationXDR`, etc.)
- Most entry structs (`DataEntryXDR`, `OfferEntryXDR`, `LiabilitiesXDR`, etc.)
- Type code enums (`ClaimAtomType`, `ClaimantType`, `LedgerEntryType`, etc.)
- Contract spec types (`SCSpec*`)
- Contract meta types (`SCMeta*`, `SCEnvMeta*`)
- Ledger key types (`LedgerKeyXDR`, `LedgerKeyAccountXDR`, etc.)
- Config setting types
- All account/trustline extension types

### Special Handling Notes

1. **WrappedData4/12/32:** Generator must emit these types for opaque fixed-size fields. Existing code already uses them.
2. **decodeArray():** Generator must use this helper for XDR variable-length arrays. Already used throughout.
3. **`var` vs `let`:** Some types use `var` for fields that need mutation (operations, ext, etc.). Generator should default to `let` for pure XDR types.
4. **Typos to preserve:** `LiquidityPoolDepositResulCode` and `LiquidityPoolWithdrawResulCode` are misspelled (missing 't') -- if generating these, decide whether to fix the name.
5. **NSObject classes:** The 3 envelope classes use NSObject + NSLock for thread safety. These cannot be generated as structs.
6. **XDREncodable-only:** `TransactionResultBodyXDR`, `InnerTransactionResultBodyXDR`, and `ManageOfferSuccessResultOfferXDR` only implement encoding. If generating full XDRCodable, this changes their API surface.
