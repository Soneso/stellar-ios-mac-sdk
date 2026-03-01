# XDR Type Name Mapping Audit

Generated for Task 0.3 of the XDR Code Generation plan.

XDR source: `stellar/stellar-xdr` commit `4b7a2ef7931ab2ca2499be68d849f38190b443ca`

## Summary Statistics

| Category | Count |
|----------|-------|
| Total XDR types across all .x files | ~280 |
| Types present in Swift SDK | ~210 |
| Types with default naming (XDRName + "XDR") | ~30 |
| Types requiring NAME_OVERRIDES | ~180 |
| Types not in SDK (overlay, SCP, exporter, internal) | ~70 |
| Enums requiring MEMBER_OVERRIDES | 8 |

## Naming Patterns

### Pattern 1: Standard XDR suffix (default -- no override needed)
Types where Swift name = XDR name + "XDR":
- `LedgerEntryChangesXDR`, `LedgerEntryDataXDR`, `ContractDataEntryXDR`, etc.

These need no entry in NAME_OVERRIDES because the generator produces them by default.

### Pattern 2: Enum types without XDR suffix
Many enums in Swift lack the "XDR" suffix, stored as plain Swift enums:
- `LedgerEntryType`, `ClaimPredicateType`, `SCValType`, `SCErrorType`, `ContractCostType`,
  `OperationType`, `ConfigSettingID`, `ContractDataDurability`, etc.

### Pattern 3: Struct-with-constants (replacing XDR enums)
Some XDR enums are implemented as Swift structs with static constants:
- `MemoType` (XDR enum -> Swift struct with MEMO_TYPE_NONE, MEMO_TYPE_TEXT, etc.)
- `AssetType` (XDR enum -> Swift struct with ASSET_TYPE_NATIVE, etc.)
- `CryptoKeyType` (XDR enum -> Swift struct)
- `EnvelopeType` (XDR enum -> Swift struct)
- `AccountFlags` (XDR enum -> Swift struct)
- `TrustLineFlags` (XDR enum -> Swift struct)
- `ClaimableBalanceFlags` (XDR enum -> Swift struct)

### Pattern 4: Renamed types
| XDR Name | Swift Name | Reason |
|----------|-----------|--------|
| `AlphaNum4` | `Alpha4XDR` | Shortened |
| `AlphaNum12` | `Alpha12XDR` | Shortened |
| `CreateAccountOp` | `CreateAccountOperationXDR` | "Op" expanded to "Operation" |
| `PaymentOp` | `PaymentOperationXDR` | "Op" expanded to "Operation" |
| `PathPaymentStrictReceiveOp` | `PathPaymentOperationXDR` | Renamed + shared type |
| `ManageSellOfferOp` | `ManageOfferOperationXDR` | "Sell" dropped + shared type |
| `CreatePassiveSellOfferOp` | `CreatePassiveOfferOperationXDR` | "Sell" dropped |
| `SetOptionsOp` | `SetOptionsOperationXDR` | "Op" expanded |
| `AllowTrustOp` | `AllowTrustOperationXDR` | "Op" expanded |
| `ChangeTrustOp` | `ChangeTrustOperationXDR` | "Op" expanded |
| `ManageDataOp` | `ManageDataOperationXDR` | "Op" expanded |
| `BumpSequenceOp` | `BumpSequenceOperationXDR` | "Op" expanded |
| `Transaction` | `TransactionXDR` | Generic name gets XDR suffix |
| `Operation` | `OperationXDR` | Generic name gets XDR suffix |
| `TrustLineEntry` | `TrustlineEntryXDR` | "TrustLine" -> "Trustline" (casing) |
| `MuxedEd25519Account` | `MuxedAccountMed25519XDR` | Completely different name |
| `CreateContractArgsV2` | `CreateContractV2ArgsXDR` | V2 position swapped |
| `LiquidityPoolDepositResultCode` | `LiquidityPoolDepositResulCode` | Typo: "Result" -> "Resul" |
| `LiquidityPoolWithdrawResultCode` | `LiquidityPoolWithdrawResulCode` | Typo: "Result" -> "Resul" |
| `PathPaymentStrictReceiveResultCode` | `PathPaymentResultCode` | Shortened (shared) |
| `PathPaymentStrictSendResultCode` | `PathPaymentResultCode` | Shortened (shared) |
| `ManageSellOfferResultCode` | `ManageOfferResultCode` | "Sell" dropped (shared) |
| `ManageBuyOfferResultCode` | `ManageOfferResultCode` | "Sell/Buy" dropped (shared) |

### Pattern 5: Shared types
Several XDR types that differ in the spec map to the same Swift type:
- `PathPaymentStrictReceiveOp` and `PathPaymentStrictSendOp` both map to `PathPaymentOperationXDR`
- `ManageSellOfferOp` and `ManageBuyOfferOp` both map to `ManageOfferOperationXDR`
- `PathPaymentStrictReceiveResult` and `PathPaymentStrictSendResult` both map to `PathPaymentResultXDR`
- `ManageSellOfferResult` and `ManageBuyOfferResult` both map to `ManageOfferResultXDR`
- All corresponding result code enums are similarly shared

## Types NOT in the SDK (from XDR .x files)

### Stellar-SCP.x (network consensus -- not needed for SDK)
- `SCPBallot`, `SCPNomination`, `SCPStatement`, `SCPEnvelope`, `SCPQuorumSet`
- `SCPStatementType`

### Stellar-overlay.x (network messaging -- not needed for SDK)
- `ErrorCode`, `Error`, `IPAddrType`, `PeerAddress`, `MessageType`
- `AuthCert`, `Hello`, `Auth`, `DontHave`, `SendMore`, `SendMoreExtended`
- `SurveyMessageCommandType`, `SurveyMessageResponseType`
- `StellarMessage`, `AuthenticatedMessage`
- All survey-related types
- `FloodAdvert`, `FloodDemand`

### Stellar-exporter.x
- `LedgerCloseMetaBatch`

### Stellar-internal.x
- `StoredTransactionSet`, `StoredDebugTransactionSet`
- `PersistedSCPState`, `PersistedSCPStateV0`, `PersistedSCPStateV1`

### Stellar-ledger.x (partially in SDK)
- `StellarValueType`, `StellarValue`, `LedgerCloseValueSignature`
- `LedgerHeaderFlags`, `LedgerHeaderExtensionV1`, `LedgerHeader`
- `LedgerUpgradeType`, `LedgerUpgrade`
- `TxSetComponentType`, `TxSetComponent`
- `TransactionPhase`, `GeneralizedTransactionSet`
- `TransactionSet`, `TransactionSetV1`
- `TransactionResultPair`, `TransactionResultSet`
- `TransactionHistoryEntry`, `TransactionHistoryResultEntry`
- `LedgerHeaderHistoryEntry`, `LedgerSCPMessages`
- `SCPHistoryEntry`, `SCPHistoryEntryV0`
- `TransactionResultMeta`, `TransactionResultMetaV1`
- `UpgradeEntryMeta`
- `LedgerCloseMetaV0`, `LedgerCloseMetaV1`, `LedgerCloseMetaV2`
- `LedgerCloseMetaExtV1`, `LedgerCloseMetaExt`, `LedgerCloseMeta`
- `ConfigUpgradeSet`, `ParallelTxsComponent`
- `BucketListType`, `BucketEntryType`, `BucketMetadata`
- `BucketEntry`, `HotArchiveBucketEntryType`, `HotArchiveBucketEntry`

### Stellar-types.x (partially in SDK)
- `Curve25519Secret`, `Curve25519Public`, `HmacSha256Key`, `HmacSha256Mac`
- `ShortHashSeed`, `SerializedBinaryFuseFilter`, `BinaryFuseFilterType`
- `PublicKeyType` (absorbed into PublicKey)

### Stellar-ledger-entries.x (partially in SDK)
- `AssetCode` union (not implemented separately)
- `ThresholdIndexes` enum
- `OfferEntryFlags` enum
- Various flag mask constants

### Typedefs not in SDK
- `Hash`, `uint256`, `TimePoint`, `Duration`, `Signature`, `SignatureHint`
- `NodeID`, `AccountID`, `ContractID`, `PoolID`
- `Thresholds`, `string32`, `string64`, `SequenceNumber`
- `DataValue`, `AssetCode4`, `AssetCode12`, `SponsorshipDescriptor`
- `SCVec`, `SCMap`, `SCBytes`, `SCString`, `SCSymbol`
- `UpgradeType`, `DependentTxCluster`, `ParallelTxExecutionStage`
- `EncryptedBody`, `TxAdvertVector`, `TxDemandVector`
- `SorobanAuthorizationEntries`, `TimeSlicedPeerDataList`

## Types in SDK but NOT in XDR .x files (SDK-only)

These are helper types defined only in the SDK:
- `LedgerKeyAccountXDR` -- helper for LedgerKey.account arm
- `LedgerKeyDataXDR` -- helper for LedgerKey.data arm
- `LedgerKeyOfferXDR` -- helper for LedgerKey.offer arm
- `LedgerKeyTrustLineXDR` -- helper for LedgerKey.trustline arm
- `LedgerKeyContractDataXDR` -- helper for LedgerKey.contractData arm
- `LedgerKeyContractCodeXDR` -- helper for LedgerKey.contractCode arm
- `LedgerKeyTTLXDR` -- helper for LedgerKey.ttl arm
- `LiquidityPoolIDXDR` -- wrapper around PoolID hash
- `MuxedAccountMed25519XDRInverted` -- inverted byte order helper
- `UploadContractWasmArgsXDR` -- SDK-specific wrapper
- `FromEd25519PublicKeyXDR` -- SDK-specific wrapper
- `AllowTrustOpAssetXDR` -- extracted from inline union in AllowTrustOp
- `OperationID` -- nested struct from HashIDPreimage
- `RevokeID` -- nested struct from HashIDPreimage
- `RevokeSponsorshipSignerXDR` -- extracted from RevokeSponsorshipOp arm
- `ClaimantV0XDR` -- extracted from Claimant union arm
- `ConstantProductXDR` -- extracted from LiquidityPoolBody arm
- `LiquidityPoolBodyXDR` -- body union extracted from LiquidityPoolEntry
- `ContractEventBodyXDR` -- body union extracted from ContractEvent
- `ContractEventBodyV0XDR` -- extracted from ContractEventBody arm
- `OperationBodyXDR` -- body union extracted from Operation
- `TransactionResultBodyXDR` -- body union extracted from TransactionResult
- `InnerTransactionResultBodyXDR` -- body union extracted from InnerTransactionResult
- `ManageOfferSuccessResultOfferXDR` -- offer union from ManageOfferSuccessResult
- `AccountEntryExtXDR` -- extension union from AccountEntry
- `AccountEntryExtV1XDR` -- extension union from AccountEntryExtensionV1
- `AccountEntryExtV2XDR` -- extension union from AccountEntryExtensionV2
- `TrustlineEntryExtXDR` -- extension union from TrustLineEntry
- `TrustlineEntryExtV1XDR` -- extension union from TrustLineEntryExtensionV1
- `LedgerEntryExtXDR` -- extension union from LedgerEntry
- `ClaimableBalanceEntryExtXDR` -- extension union from ClaimableBalanceEntry
- `TransactionExtXDR` -- extension union from Transaction
- `SorobanResourcesExt` -- extension union from SorobanResources
- `ContractCodeEntryExt` -- extension union from ContractCodeEntry
- `SorobanTransactionMetaExt` -- extension union from SorobanTransactionMeta
- `TransactionMetaType` -- discriminant enum for TransactionMeta (int v)

## Enum Member Override Summary

8 enum types require MEMBER_OVERRIDES:

1. **MemoType** (5 members) -- struct-with-constants: MEMO_ prefix becomes MEMO_TYPE_ prefix
2. **OperationType** (27 members) -- completely custom Swift names
3. **SignerKeyType** (1 member) -- ED25519_SIGNED_PAYLOAD shortened to signedPayload
4. **ClaimPredicateType** (6 members) -- keeps full prefix + abbreviates time names
5. **RevokeSponsorshipType** (2 members) -- keeps full prefix + appends "Entry"
6. **ClaimableBalanceIDType** (1 member) -- keeps full name with capitalized "ID"
7. **ClaimantType** (1 member) -- keeps full name
8. **LedgerEntryChangeType** (5 members) -- keeps full prefix + "Restored" -> "Restore"
9. **SCSpecEntryKind** (4 members) -- drops "UDT" sub-prefix
10. **TransactionEventStage** (1 member) -- drops trailing 's'

All other enum types use mechanical conversion (strip type prefix, camelCase remainder).

## Notes

1. **Typos in SDK**: `LiquidityPoolDepositResulCode` and `LiquidityPoolWithdrawResulCode` are missing a 't' in "Result". These should be preserved for backward compatibility.

2. **Shared operation types**: The SDK uses a single `PathPaymentOperationXDR` for both strict-receive and strict-send operations, and a single `ManageOfferOperationXDR` for both sell and buy offers. The generator must handle this (skip generating duplicates).

3. **Extension unions**: Many XDR structs have inline `union switch (int v)` extension fields. The SDK extracts these into separate named types (e.g., `AccountEntryExtXDR`). The generator must handle this pattern.

4. **Nested structs**: XDR unions contain inline struct definitions for some arms (e.g., `Claimant.v0`). The SDK extracts these into standalone types (e.g., `ClaimantV0XDR`).

5. **Trustline casing**: The SDK consistently uses "Trustline" (capital T, lowercase l) while XDR uses "TrustLine" (both capitalized). This affects `TrustlineEntryXDR`, `TrustlineAssetXDR`, `TrustlineEntryExtensionV1`, etc.
