# XDR Exclusion List Validation and Helper Extraction Catalog

## Part A: Exclusion List Validation

### Exclusion Validation Table

| # | Type | File | Kind | NSLock/NSObject/@unchecked | XDREncodable-only | Struct-with-static-constants | [UInt8] for opaque | Extra stored props | Status |
|---|------|------|------|---------------------------|-------------------|------------------------------|--------------------|--------------------|--------|
| 1 | `TransactionV1EnvelopeXDR` | TransactionV1EnvelopeXDR.swift | class : NSObject, XDRCodable, @unchecked Sendable | YES (NSLock, NSObject, @unchecked Sendable) | No | No | No | `_signatures` (private), `lock` (NSLock) | CONFIRMED |
| 2 | `TransactionV0EnvelopeXDR` | TransactionV0EnvelopeXDR.swift | class : NSObject, XDRCodable, @unchecked Sendable | YES (NSLock, NSObject, @unchecked Sendable) | No | No | No | `_signatures` (private), `lock` (NSLock) | CONFIRMED |
| 3 | `FeeBumpTransactionEnvelopeXDR` | FeeBumpTransactionEnvelopeXDR.swift | class : NSObject, XDRCodable, @unchecked Sendable | YES (NSLock, NSObject, @unchecked Sendable) | No | No | No | `_signatures` (private), `lock` (NSLock) | CONFIRMED |
| 4 | `TransactionXDR` | TransactionXDR.swift | struct : XDRCodable, Sendable | No | No | No | No | `signatures` (not part of wire format) | CONFIRMED |
| 5 | `FeeBumpTransactionXDR` | FeeBumpTransactionXDR.swift | struct : XDRCodable, Sendable | No | No | No | No | `signatures` (private, not part of wire format) | CONFIRMED |
| 6 | `TransactionV0XDR` | TransactionV0XDR.swift | struct : XDRCodable, Sendable | No | No | No | YES (`sourceAccountEd25519: [UInt8]` for opaque[32]) | `signatures` (private, not wire format) | CONFIRMED |
| 7 | `TransactionSignaturePayload` | TransactionSignaturePayload.swift | struct : XDREncodable | No | YES (XDREncodable only, no decode) | No | No | No | CONFIRMED |
| 8 | `AccountEd25519Signature` | TransactionXDR.swift | final class : Sendable | No | Not XDRCodable at all | No | YES (`signature: [UInt8]`) | No | CONFIRMED |
| 9 | `AssetType` | AssetXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants) | No | No | CONFIRMED |
| 10 | `EnvelopeType` | TransactionEnvelopeXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants) | No | No | CONFIRMED |
| 11 | `CryptoKeyType` | MuxedAccountXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants) | No | No | CONFIRMED |
| 12 | `MemoType` | MemoXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants) | No | No | CONFIRMED |
| 13 | `AccountFlags` | AccountEntryXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants, UInt32) | No | No | CONFIRMED |
| 14 | `TrustLineFlags` | TrustlineEntryXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants, UInt32) | No | No | CONFIRMED |
| 15 | `ClaimableBalanceFlags` | ClaimableBalanceEntryXDR.swift | struct : Sendable | No | Not XDRCodable | YES (static let constants, UInt32) | No | No | CONFIRMED |
| 16 | `MuxedAccountXDR` | MuxedAccountXDR.swift | enum : XDRCodable, Sendable | No | No | No | YES (`.ed25519([UInt8])` for opaque[32]) | No | CONFIRMED |
| 17 | `MuxedAccountMed25519XDR` | MuxedAccountMed25519XDR.swift | struct : XDRCodable, Sendable | No | No | No | YES (`sourceAccountEd25519: [UInt8]` for opaque[32]) | No | CONFIRMED |
| 18 | `MuxedAccountMed25519XDRInverted` | MuxedAccountMed25519XDR.swift | struct : XDRCodable, Sendable | No | No | No | YES (`sourceAccountEd25519: [UInt8]` for opaque[32]) | CONFIRMED |
| 19 | `OperationType` | OperationResponse.swift | enum : Int32, Sendable | No | Not XDRCodable | No (it is an enum with raw Int32 values) | No | No | CONFIRMED |
| 20 | `PublicKey` | crypto/PublicKey.swift | final class : XDRCodable, Sendable | No | No | No | YES (`buffer: [UInt8]` for opaque[32]) | No | CONFIRMED |
| 21 | `TransactionEnvelopeXDR` | TransactionEnvelopeXDR.swift | enum : XDRCodable, Sendable | No | No | No | No | Many helper computed properties | CONFIRMED |

### Exclusion Reason Summary

Each excluded type falls into one or more of these categories:

- **Thread-safe wrapper classes (NSLock/NSObject/@unchecked Sendable):** Types 1-3. These use `class` instead of `struct`, inherit from `NSObject`, use `NSLock` for thread-safe signature mutation, and use `@unchecked Sendable`. The code generator produces `struct` types and cannot replicate this pattern.
- **Extra stored properties not in XDR wire format:** Types 4-6. `TransactionXDR`, `FeeBumpTransactionXDR`, and `TransactionV0XDR` each have a `signatures` property that is not part of the XDR encoding but is used for transaction signing workflows.
- **XDREncodable-only (no decode):** Type 7. `TransactionSignaturePayload` only implements `XDREncodable` (encode-only for hashing purposes). The code generator produces types that implement full `XDRCodable`.
- **Not XDR types at all / SDK helper classes:** Type 8 (`AccountEd25519Signature` is a plain Sendable class, not XDR), Type 19 (`OperationType` is a raw-value enum defined alongside Horizon response types), Type 20 (`PublicKey` is a cryptographic key class with verify logic, not a pure XDR type).
- **Struct-with-static-constants pattern:** Types 9-15. These are `struct : Sendable` with only `static let` constants that serve as named discriminant values. The XDR spec defines these as `enum`, but the SDK uses a struct-with-constants pattern to allow extensibility without breaking changes.
- **[UInt8] for opaque[32]/uint256:** Types 6, 16-18, 20. These use `[UInt8]` for fields that the XDR spec defines as `opaque<32>` or `uint256`. They perform manual `WrappedData32` conversion in encode/decode. The code generator would use `WrappedData32` directly.
- **Extensive helper methods:** Type 21. `TransactionEnvelopeXDR` has many convenience computed properties that cross-cut envelope versions, plus `init(fromBase64:)` and `appendSignature`.

### Additional Types Found That Should Be Excluded

No additional struct-with-static-constants types were found beyond those already in the exclusion list. All 7 struct-with-static-constants types in the XDR directory are accounted for: `AssetType`, `EnvelopeType`, `CryptoKeyType`, `MemoType`, `AccountFlags`, `TrustLineFlags`, `ClaimableBalanceFlags`.

The `TransactionSignaturePayload.TaggedTransaction` nested enum (in TransactionSignaturePayload.swift) is implicitly excluded along with its parent type.

---

## Part B: Helper Extraction Catalog

### 1. TransactionXDR.swift

#### Helpers on TransactionXDR (EXCLUDED -- stays in-place)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Notes |
|-----------|---------|------------------|-------------------|-------|
| `public init(sourceAccount: PublicKey, seqNum: Int64, cond: PreconditionsXDR, memo: MemoXDR, operations: [OperationXDR], maxOperationFee: UInt32 = 100, ext: TransactionExtXDR = .void)` | No | PublicKey | MuxedAccountXDR, PreconditionsXDR, MemoXDR, OperationXDR, TransactionExtXDR | Convenience init taking PublicKey instead of MuxedAccountXDR |
| `public mutating func sign(keyPair: KeyPair, network: Network) throws` | YES | KeyPair, Network | DecoratedSignatureXDR | Signs and appends signature |
| `public mutating func addSignature(signature: DecoratedSignatureXDR)` | YES | None | DecoratedSignatureXDR | Appends pre-built signature |
| `private func signatureBase(network: Network) throws -> Data` | No | Network | TransactionSignaturePayload, WrappedData32 | Computes signature base |
| `public func hash(network: Network) throws -> Data` | No | Network | None (uses signatureBase) | SHA256 hash of signature base |
| `public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR` | No | None | TransactionV1EnvelopeXDR, TransactionEnvelopeXDR | Wraps in envelope |
| `public func encodedEnvelope() throws -> String` | No | None | XDREncoder | Base64-encoded envelope |
| `public func toEnvelopeV1XDR() throws -> TransactionV1EnvelopeXDR` | No | None | TransactionV1EnvelopeXDR | Wraps in V1 envelope |
| `public func encodedV1Envelope() throws -> String` | No | None | XDREncoder | Base64-encoded V1 envelope |
| `public func encodedV1Transaction() throws -> String` | No | None | XDREncoder | Base64-encoded raw transaction |

**Action:** All stay in-place (excluded type).

#### Helpers on SorobanAuthorizationEntryXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | SorobanAuthorizationEntryXDR+Helpers.swift |
| `public mutating func sign(signer: KeyPair, network: Network, signatureExpirationLedger: UInt32? = nil) throws` | YES | KeyPair, Network, StellarSDKError | HashIDPreimageSorobanAuthorizationXDR, HashIDPreimageXDR, WrappedData32, XDREncoder, AccountEd25519Signature, SCValXDR, SorobanCredentialsXDR, SorobanAddressCredentialsXDR | SorobanAuthorizationEntryXDR+Helpers.swift |

#### Helpers on SorobanAddressCredentialsXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public mutating func appendSignature(signature: SCValXDR)` | YES | None | SCValXDR | SorobanAddressCredentialsXDR+Helpers.swift |

#### Helpers on LedgerFootprintXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | LedgerFootprintXDR+Helpers.swift |

#### Helpers on SorobanTransactionDataXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | SorobanTransactionDataXDR+Helpers.swift |
| `public var archivedSorobanEntries: [UInt32]?` | No | None | SorobanResourcesExt, SorobanResourcesExtV0 | SorobanTransactionDataXDR+Helpers.swift |

#### Helpers on ContractIDPreimageXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var fromAddress: ContractIDPreimageFromAddressXDR?` | No | None | ContractIDPreimageFromAddressXDR | ContractIDPreimageXDR+Helpers.swift |
| `public var fromAsset: AssetXDR?` | No | None | AssetXDR | ContractIDPreimageXDR+Helpers.swift |

#### Helpers on HostFunctionXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var invokeContract: InvokeContractArgsXDR?` | No | None | InvokeContractArgsXDR | HostFunctionXDR+Helpers.swift |
| `public var createContract: CreateContractArgsXDR?` | No | None | CreateContractArgsXDR | HostFunctionXDR+Helpers.swift |
| `public var uploadContractWasm: Data?` | No | None | None | HostFunctionXDR+Helpers.swift |
| `public var createContractV2: CreateContractV2ArgsXDR?` | No | None | CreateContractV2ArgsXDR | HostFunctionXDR+Helpers.swift |

#### Helpers on SorobanAuthorizedFunctionXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var contractFn: InvokeContractArgsXDR?` | No | None | InvokeContractArgsXDR | SorobanAuthorizedFunctionXDR+Helpers.swift |
| `public var contractHostFn: CreateContractArgsXDR?` | No | None | CreateContractArgsXDR | SorobanAuthorizedFunctionXDR+Helpers.swift |
| `public var contractV2HostFn: CreateContractV2ArgsXDR?` | No | None | CreateContractV2ArgsXDR | SorobanAuthorizedFunctionXDR+Helpers.swift |

#### Helpers on SorobanCredentialsXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var address: SorobanAddressCredentialsXDR?` | No | None | SorobanAddressCredentialsXDR | SorobanCredentialsXDR+Helpers.swift |

### 2. TransactionEnvelopeXDR.swift

#### Helpers on TransactionEnvelopeXDR (EXCLUDED -- stays in-place)

| Signature | Mutates | SDK Dependencies | XDR Dependencies |
|-----------|---------|------------------|-------------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder |
| `public var txSourceAccountId: String` | No | None | TransactionV0EnvelopeXDR, TransactionV1EnvelopeXDR, FeeBumpTransactionEnvelopeXDR |
| `public var txMuxedSourceId: UInt64?` | No | None | MuxedAccountXDR |
| `public var txSeqNum: Int64` | No | None | Various envelope types |
| `public var txTimeBounds: TimeBoundsXDR?` | No | None | TimeBoundsXDR, PreconditionsXDR |
| `public var cond: PreconditionsXDR` | No | None | PreconditionsXDR |
| `public var sorobanTransactionData: SorobanTransactionDataXDR?` | No | None | SorobanTransactionDataXDR, TransactionExtXDR |
| `public var txFee: UInt32` | No | None | Various envelope types |
| `public var txMemo: MemoXDR` | No | None | MemoXDR |
| `public var txOperations: [OperationXDR]` | No | None | OperationXDR |
| `public var txExt: TransactionExtXDR?` | No | None | TransactionExtXDR |
| `public var txSignatures: [DecoratedSignatureXDR]` | No | None | DecoratedSignatureXDR |
| `public func txHash(network: Network) throws -> Data` | No | Network | Various TX types |
| `public func appendSignature(signature: DecoratedSignatureXDR)` | No (mutates referenced class) | None | DecoratedSignatureXDR |

**Action:** All stay in-place (excluded type).

### 3. OperationXDR.swift

#### Helpers on OperationXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `@available(*, deprecated) public init(sourceAccount: PublicKey?, body: OperationBodyXDR)` | No | PublicKey | MuxedAccountXDR, OperationBodyXDR | OperationXDR+Helpers.swift |
| `public mutating func setSorobanAuth(auth: [SorobanAuthorizationEntryXDR])` | YES | None | SorobanAuthorizationEntryXDR, OperationBodyXDR | OperationXDR+Helpers.swift |

### 4. AssetXDR.swift

#### Helpers on Alpha4XDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(assetCodeString: String, issuer: KeyPair) throws` | No | KeyPair, StellarSDKError | WrappedData4, PublicKey | Alpha4XDR+Helpers.swift |
| `public var assetCodeString: String` | No | None | WrappedData4 | Alpha4XDR+Helpers.swift |

#### Helpers on Alpha12XDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(assetCodeString: String, issuer: KeyPair) throws` | No | KeyPair, StellarSDKError | WrappedData12, PublicKey | Alpha12XDR+Helpers.swift |
| `public var assetCodeString: String` | No | None | WrappedData12 | Alpha12XDR+Helpers.swift |

#### Helpers on AssetXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var assetCode: String` | No | None | Alpha4XDR, Alpha12XDR | AssetXDR+Helpers.swift |
| `public var issuer: PublicKey?` | No | PublicKey | Alpha4XDR, Alpha12XDR | AssetXDR+Helpers.swift |
| `public init(assetCode: String, issuer: KeyPair) throws` | No | KeyPair, StellarSDKError | Alpha4XDR, Alpha12XDR | AssetXDR+Helpers.swift |

### 5. AllowTrustOpAssetXDR.swift

#### Helpers on AllowTrustOpAssetXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var assetCode: String` | No | None | AlphaATO4XDR, AlphaATO12XDR | AllowTrustOpAssetXDR+Helpers.swift |

Note: No `init(assetCodeString:)` exists on this type contrary to the task description.

### 6. ChangeTrustAssetXDR.swift

#### Helpers on ChangeTrustAssetXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(assetCode: String, issuer: KeyPair) throws` | No | KeyPair, StellarSDKError | Alpha4XDR, Alpha12XDR | ChangeTrustAssetXDR+Helpers.swift |
| `public init(params: LiquidityPoolConstantProductParametersXDR)` | No | None | LiquidityPoolParametersXDR, LiquidityPoolConstantProductParametersXDR | ChangeTrustAssetXDR+Helpers.swift |
| `public var assetCode: String?` | No | None | Alpha4XDR, Alpha12XDR | ChangeTrustAssetXDR+Helpers.swift |
| `public var issuer: PublicKey?` | No | PublicKey | Alpha4XDR, Alpha12XDR | ChangeTrustAssetXDR+Helpers.swift |

### 7. TrustlineAssetXDR.swift

#### Helpers on TrustlineAssetXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(assetCode: String, issuer: KeyPair) throws` | No | KeyPair, StellarSDKError | Alpha4XDR, Alpha12XDR | TrustlineAssetXDR+Helpers.swift |
| `public init(poolId: String)` | No | None | WrappedData32 | TrustlineAssetXDR+Helpers.swift |
| `public var assetCode: String?` | No | None | Alpha4XDR, Alpha12XDR | TrustlineAssetXDR+Helpers.swift |
| `public var issuer: PublicKey?` | No | PublicKey | Alpha4XDR, Alpha12XDR | TrustlineAssetXDR+Helpers.swift |
| `public var poolId: String?` | No | None | WrappedData32 | TrustlineAssetXDR+Helpers.swift |

### 8. ContractEventXDR.swift

#### Helpers on DiagnosticEventXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | DiagnosticEventXDR+Helpers.swift |

Note: `ContractEventXDR` itself has no helpers beyond encode/decode/memberwise init.

### 9. TransactionMetaXDR.swift

#### Helpers on TransactionMetaXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | TransactionMetaXDR+Helpers.swift |
| `public var transactionMetaV3: TransactionMetaV3XDR?` | No | None | TransactionMetaV3XDR | TransactionMetaXDR+Helpers.swift |
| `public var transactionMetaV4: TransactionMetaV4XDR?` | No | None | TransactionMetaV4XDR | TransactionMetaXDR+Helpers.swift |

### 10. LedgerEntryXDR.swift

#### Helpers on LedgerEntryXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | LedgerEntryXDR+Helpers.swift |

#### Helpers on LiquidityPoolIDXDR (GENERATED type, same file)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var poolIDString: String` | No | None | WrappedData32 | LiquidityPoolIDXDR+Helpers.swift |

### 11. LedgerExtryDataXDR.swift

#### Helpers on LedgerEntryDataXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | LedgerEntryDataXDR+Helpers.swift |
| `public var isBool: Bool` | No | None | SCValType | LedgerEntryDataXDR+Helpers.swift |
| `public var account: AccountEntryXDR?` | No | None | AccountEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var trustline: TrustlineEntryXDR?` | No | None | TrustlineEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var offer: OfferEntryXDR?` | No | None | OfferEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var data: DataEntryXDR?` | No | None | DataEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var claimableBalance: ClaimableBalanceEntryXDR?` | No | None | ClaimableBalanceEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var liquidityPool: LiquidityPoolEntryXDR?` | No | None | LiquidityPoolEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var contractData: ContractDataEntryXDR?` | No | None | ContractDataEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var contractCode: ContractCodeEntryXDR?` | No | None | ContractCodeEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var configSetting: ConfigSettingEntryXDR?` | No | None | ConfigSettingEntryXDR | LedgerEntryDataXDR+Helpers.swift |
| `public var ttl: TTLEntryXDR?` | No | None | TTLEntryXDR | LedgerEntryDataXDR+Helpers.swift |

### 12. LedgerKeyXDR.swift

#### Helpers on LedgerKeyXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(fromBase64 xdr: String) throws` | No | None | XDRDecoder | LedgerKeyXDR+Helpers.swift |

### 13. FeeBumpTransactionXDR.swift

#### Helpers on FeeBumpTransactionXDR (EXCLUDED -- stays in-place)

| Signature | Mutates | SDK Dependencies | XDR Dependencies |
|-----------|---------|------------------|-------------------|
| `public mutating func sign(keyPair: KeyPair, network: Network) throws` | YES | KeyPair, Network | DecoratedSignatureXDR |
| `public mutating func addSignature(signature: DecoratedSignatureXDR)` | YES | None | DecoratedSignatureXDR |
| `private func signatureBase(network: Network) throws -> Data` | No | Network | TransactionSignaturePayload, WrappedData32 |
| `public func hash(network: Network) throws -> Data` | No | Network | None |
| `public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR` | No | None | TransactionEnvelopeXDR, FeeBumpTransactionEnvelopeXDR |
| `public func toFBEnvelopeXDR() throws -> FeeBumpTransactionEnvelopeXDR` | No | None | FeeBumpTransactionEnvelopeXDR |
| `public func encodedEnvelope() throws -> String` | No | None | XDREncoder |

**Action:** All stay in-place (excluded type).

#### Helpers on InnerTransactionXDR (nested in FeeBumpTransactionXDR, EXCLUDED)

| Signature | Mutates | SDK Dependencies | XDR Dependencies |
|-----------|---------|------------------|-------------------|
| `public var tx: TransactionV1EnvelopeXDR` | No | None | TransactionV1EnvelopeXDR |

**Action:** Stays in-place (part of excluded type).

### 14. TransactionV0XDR.swift

#### Helpers on TransactionV0XDR (EXCLUDED -- stays in-place)

| Signature | Mutates | SDK Dependencies | XDR Dependencies |
|-----------|---------|------------------|-------------------|
| `public mutating func sign(keyPair: KeyPair, network: Network) throws` | YES | KeyPair, Network | DecoratedSignatureXDR |
| `public mutating func addSignature(signature: DecoratedSignatureXDR)` | YES | None | DecoratedSignatureXDR |
| `public func hash(network: Network) throws -> Data` | No | Network, PublicKey | TransactionXDR, PreconditionsXDR |
| `public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR` | No | None | TransactionV0EnvelopeXDR, TransactionEnvelopeXDR |
| `public func encodedEnvelope() throws -> String` | No | None | XDREncoder |
| `public func toEnvelopeV0XDR() throws -> TransactionV0EnvelopeXDR` | No | None | TransactionV0EnvelopeXDR |
| `public func encodedV0Envelope() throws -> String` | No | None | XDREncoder |
| `public func encodedV0Transaction() throws -> String` | No | None | XDREncoder |

**Action:** All stay in-place (excluded type).

### 15. ContractXDR.swift (SCAddressXDR)

#### Helpers on SCAddressXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(accountId: String) throws` | No | PublicKey, String.decodeMuxedAccount | MuxedAccountXDR | SCAddressXDR+Helpers.swift |
| `public init(contractId: String) throws` | No | String.decodeContractIdToHex, Data(using: .hexadecimal) | WrappedData32 | SCAddressXDR+Helpers.swift |
| `public init(claimableBalanceId: String) throws` | No | ClaimableBalanceIDXDR | ClaimableBalanceIDXDR | SCAddressXDR+Helpers.swift |
| `public init(liquidityPoolId: String) throws` | No | String.decodeLiquidityPoolIdToHex | WrappedData32 | SCAddressXDR+Helpers.swift |
| `public var accountId: String?` | No | PublicKey, MuxedAccountMed25519XDR | None | SCAddressXDR+Helpers.swift |
| `public var contractId: String?` | No | Data.base16EncodedString | WrappedData32 | SCAddressXDR+Helpers.swift |
| `public var claimableBalanceId: String?` | No | ClaimableBalanceIDXDR | None | SCAddressXDR+Helpers.swift |
| `public func getClaimableBalanceIdStrKey() throws -> String?` | No | String.encodeClaimableBalanceIdHex | ClaimableBalanceIDXDR | SCAddressXDR+Helpers.swift |
| `public var liquidityPoolId: String?` | No | LiquidityPoolIDXDR | None | SCAddressXDR+Helpers.swift |

### 16. ClaimableBalanceEntryXDR.swift (ClaimableBalanceIDXDR)

#### Helpers on ClaimableBalanceIDXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(claimableBalanceId: String) throws` | No | String.decodeClaimableBalanceIdToHex, Data(using: .hexadecimal) | WrappedData32 | ClaimableBalanceIDXDR+Helpers.swift |
| `public var claimableBalanceIdString: String` | No | None | ClaimableBalanceIDType, WrappedData32 | ClaimableBalanceIDXDR+Helpers.swift |

### 17. ContractXDR.swift (ContractExecutableXDR)

#### Helpers on ContractExecutableXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var isWasm: Bool?` | No | None | None | ContractExecutableXDR+Helpers.swift |
| `public var wasm: WrappedData32?` | No | None | WrappedData32 | ContractExecutableXDR+Helpers.swift |
| `public var isStellarAsset: Bool?` | No | None | None | ContractExecutableXDR+Helpers.swift |

### 18. LiquidityPoolEntryXDR.swift

#### Helpers on LiquidityPoolEntryXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public var poolIDString: String` | No | None | WrappedData32 | LiquidityPoolEntryXDR+Helpers.swift |

### 19. LedgerKeyXDR.swift (LedgerKeyContractCodeXDR)

#### Helpers on LedgerKeyContractCodeXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public init(wasmId: String)` | No | String.wrappedData32FromHex | WrappedData32 | LedgerKeyContractCodeXDR+Helpers.swift |

### 20. SignerKeyXDR.swift

#### Helpers on Ed25519SignedPayload (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `public static func ==(lhs: Ed25519SignedPayload, rhs: Ed25519SignedPayload) -> Bool` | No | None | WrappedData32 | Ed25519SignedPayload+Helpers.swift |
| `public func encodeSignedPayload() throws -> String` | No | None | XDREncoder, Data extension | Ed25519SignedPayload+Helpers.swift |
| `public func publicKey() throws -> PublicKey` | No | PublicKey | WrappedData32 | Ed25519SignedPayload+Helpers.swift |

#### Helpers on SignerKeyXDR (GENERATED type)

| Signature | Mutates | SDK Dependencies | XDR Dependencies | Target File |
|-----------|---------|------------------|-------------------|-------------|
| `extension SignerKeyXDR: Equatable` with `public static func ==(lhs:rhs:) -> Bool` | No | None | WrappedData32, Ed25519SignedPayload | SignerKeyXDR+Helpers.swift |

---

## Part B Summary: Extraction Targets

### Helper Files to Create (for generated types that need extracted helpers)

| Target File | Source Type | Helper Count | Primary Dependencies |
|-------------|------------|--------------|---------------------|
| `SorobanAuthorizationEntryXDR+Helpers.swift` | SorobanAuthorizationEntryXDR | 2 | KeyPair, Network, StellarSDKError, XDRDecoder, XDREncoder, AccountEd25519Signature, HashIDPreimageXDR |
| `SorobanAddressCredentialsXDR+Helpers.swift` | SorobanAddressCredentialsXDR | 1 | SCValXDR |
| `LedgerFootprintXDR+Helpers.swift` | LedgerFootprintXDR | 1 | XDRDecoder |
| `SorobanTransactionDataXDR+Helpers.swift` | SorobanTransactionDataXDR | 2 | XDRDecoder |
| `ContractIDPreimageXDR+Helpers.swift` | ContractIDPreimageXDR | 2 | None (pure accessors) |
| `HostFunctionXDR+Helpers.swift` | HostFunctionXDR | 4 | None (pure accessors) |
| `SorobanAuthorizedFunctionXDR+Helpers.swift` | SorobanAuthorizedFunctionXDR | 3 | None (pure accessors) |
| `SorobanCredentialsXDR+Helpers.swift` | SorobanCredentialsXDR | 1 | None (pure accessor) |
| `OperationXDR+Helpers.swift` | OperationXDR | 2 | PublicKey, SorobanAuthorizationEntryXDR |
| `Alpha4XDR+Helpers.swift` | Alpha4XDR | 2 | KeyPair, StellarSDKError |
| `Alpha12XDR+Helpers.swift` | Alpha12XDR | 2 | KeyPair, StellarSDKError |
| `AssetXDR+Helpers.swift` | AssetXDR | 3 | KeyPair, PublicKey, StellarSDKError |
| `AllowTrustOpAssetXDR+Helpers.swift` | AllowTrustOpAssetXDR | 1 | None |
| `ChangeTrustAssetXDR+Helpers.swift` | ChangeTrustAssetXDR | 4 | KeyPair, PublicKey, StellarSDKError |
| `TrustlineAssetXDR+Helpers.swift` | TrustlineAssetXDR | 5 | KeyPair, PublicKey, StellarSDKError |
| `DiagnosticEventXDR+Helpers.swift` | DiagnosticEventXDR | 1 | XDRDecoder |
| `TransactionMetaXDR+Helpers.swift` | TransactionMetaXDR | 3 | XDRDecoder |
| `LedgerEntryXDR+Helpers.swift` | LedgerEntryXDR | 1 | XDRDecoder |
| `LedgerEntryDataXDR+Helpers.swift` | LedgerEntryDataXDR | 12 | XDRDecoder, SCValType |
| `LedgerKeyXDR+Helpers.swift` | LedgerKeyXDR | 1 | XDRDecoder |
| `LiquidityPoolIDXDR+Helpers.swift` | LiquidityPoolIDXDR | 1 | None |
| `Ed25519SignedPayload+Helpers.swift` | Ed25519SignedPayload | 3 | PublicKey, XDREncoder, Data extensions |
| `SignerKeyXDR+Helpers.swift` | SignerKeyXDR | 1 (Equatable conformance) | None |
| `SCAddressXDR+Helpers.swift` | SCAddressXDR | 9 | PublicKey, MuxedAccountMed25519XDR, ClaimableBalanceIDXDR, LiquidityPoolIDXDR, String extensions, Data extensions |
| `ClaimableBalanceIDXDR+Helpers.swift` | ClaimableBalanceIDXDR | 2 | String.decodeClaimableBalanceIdToHex, Data extensions |
| `ContractExecutableXDR+Helpers.swift` | ContractExecutableXDR | 3 | None (pure accessors) |
| `LiquidityPoolEntryXDR+Helpers.swift` | LiquidityPoolEntryXDR | 1 | None |
| `LedgerKeyContractCodeXDR+Helpers.swift` | LedgerKeyContractCodeXDR | 1 | String.wrappedData32FromHex |

**Total: 28 helper files, 72 individual helpers**

### Types with Helpers That Stay In-Place (excluded types)

| Type | File | Helper Count |
|------|------|-------------|
| TransactionXDR | TransactionXDR.swift | 10 |
| TransactionEnvelopeXDR | TransactionEnvelopeXDR.swift | 14 |
| FeeBumpTransactionXDR | FeeBumpTransactionXDR.swift | 8 |
| TransactionV0XDR | TransactionV0XDR.swift | 8 |
| TransactionV1EnvelopeXDR | TransactionV1EnvelopeXDR.swift | 2 |
| TransactionV0EnvelopeXDR | TransactionV0EnvelopeXDR.swift | 2 |
| FeeBumpTransactionEnvelopeXDR | FeeBumpTransactionEnvelopeXDR.swift | 1 |

---

## Part B: Dependency Graph

### SDK Type Dependencies (non-XDR types used by helpers)

```
KeyPair
  <- TransactionXDR.sign (excluded, in-place)
  <- FeeBumpTransactionXDR.sign (excluded, in-place)
  <- TransactionV0XDR.sign (excluded, in-place)
  <- SorobanAuthorizationEntryXDR.sign (EXTRACT)
  <- Alpha4XDR.init(assetCodeString:issuer:) (EXTRACT)
  <- Alpha12XDR.init(assetCodeString:issuer:) (EXTRACT)
  <- AssetXDR.init(assetCode:issuer:) (EXTRACT)
  <- ChangeTrustAssetXDR.init(assetCode:issuer:) (EXTRACT)
  <- TrustlineAssetXDR.init(assetCode:issuer:) (EXTRACT)

Network
  <- TransactionXDR.sign, .hash, .signatureBase (excluded, in-place)
  <- FeeBumpTransactionXDR.sign, .hash, .signatureBase (excluded, in-place)
  <- TransactionV0XDR.sign, .hash (excluded, in-place)
  <- SorobanAuthorizationEntryXDR.sign (EXTRACT)
  <- TransactionEnvelopeXDR.txHash (excluded, in-place)

PublicKey
  <- TransactionXDR.init(sourceAccount:PublicKey...) (excluded, in-place)
  <- OperationXDR.init(sourceAccount:PublicKey...) (EXTRACT, deprecated)
  <- AssetXDR.issuer (EXTRACT)
  <- ChangeTrustAssetXDR.issuer (EXTRACT)
  <- TrustlineAssetXDR.issuer (EXTRACT)
  <- Ed25519SignedPayload.publicKey() (EXTRACT)
  <- TransactionV0EnvelopeXDR.txSourceAccountId (excluded, in-place)

StellarSDKError
  <- SorobanAuthorizationEntryXDR.sign (EXTRACT)
  <- Alpha4XDR.init (EXTRACT)
  <- Alpha12XDR.init (EXTRACT)
  <- AssetXDR.init (EXTRACT)
  <- ChangeTrustAssetXDR.init (EXTRACT)
  <- TrustlineAssetXDR.init (EXTRACT)

XDREncoder
  <- SorobanAuthorizationEntryXDR.sign (EXTRACT)
  <- Ed25519SignedPayload.encodeSignedPayload (EXTRACT)
  <- TransactionXDR.encoded* (excluded, in-place)
  <- FeeBumpTransactionXDR.encodedEnvelope (excluded, in-place)
  <- TransactionV0XDR.encoded* (excluded, in-place)

XDRDecoder
  <- All fromBase64 inits (EXTRACT: 7 types)

AccountEd25519Signature
  <- SorobanAuthorizationEntryXDR.sign (EXTRACT)

SCValType
  <- LedgerEntryDataXDR.isBool (EXTRACT)

Data extensions (.sha256Hash, .encodeMuxedAccount, .encodeSignedPayload, .base16EncodedString)
  <- Various helpers in excluded and extracted types
```

### Helper Categories

1. **`fromBase64` convenience initializers** (7 types): Simple pattern, all identical. XDRDecoder only dependency.
2. **Case accessor computed properties** (19 properties across 5 types): Pure accessors returning optional associated values from enum cases. No SDK dependencies.
3. **Asset convenience initializers and accessors** (13 helpers across 5 types): Depend on KeyPair, PublicKey, StellarSDKError.
4. **Signing/crypto helpers** (1 extracted: SorobanAuthorizationEntryXDR.sign): Complex, depends on KeyPair, Network, XDREncoder, and several XDR types.
5. **Equatable conformances** (2 types): Ed25519SignedPayload and SignerKeyXDR.
6. **Mutation helpers** (3 extracted): setSorobanAuth, appendSignature, deprecated OperationXDR init.
