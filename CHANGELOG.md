# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.13.0] - 2026-10-16

Migration guide: [docs/migration/3.13.0.md](docs/migration/3.13.0.md)

### Added
- Muxed contract addresses (`W...`, CAP-0084).
  `Data.encodeMuxedContractId()` encodes the SEP-0023 payload: the 32-byte contract id followed by
  the 8-byte big-endian id. `String.decodeMuxedContractId()` and `String.isValidMuxedContractId()`
  decode and validate it. `SCAddressXDR` gains `init(muxedContractId:)` and `init(contractId:id:)`;
  `toStrKey()` and `SCValXDR.toNative()` render the new arm as `W...`. `MuxedContractXDR` gains
  `init(muxedContractId:)` and `toStrKey()`. `MuxedContract` exposes `contractId`, optional `UInt64`
  `id`, and `address`, which is `W...` with an id and `C...` without. Its `init(contractId:id:)`
  takes a `C...` strkey and an id; `init(address:)`, `init(scAddress:)`, and `toSCAddress()` convert
  between strkeys and XDR. TxRep represents `MuxedContractXDR` as one `W...` line.
  `StellarProtocolConstants` gains `STRKEY_ENCODED_LENGTH_MUXED_CONTRACT` (69),
  `STRKEY_DECODED_SIZE_MUXED_CONTRACT` (40), and `STRKEY_PREFIX_MUXED_CONTRACT` ("W").
- The [SEP-23 compatibility matrix](compatibility/sep/SEP-0023_COMPATIBILITY_MATRIX.md) documents
  strkey format support and specification test vectors.
- The [SEP-29 compatibility matrix](compatibility/sep/SEP-0029_COMPATIBILITY_MATRIX.md) documents
  account memo requirement support.

### Changed
- Breaking: `AssetCode12XDRJsonCodec` rejects an XDR-JSON string that unescapes to fewer than five
  bytes, as the reference implementation does since 30.0.0, and so do the asset types that carry a
  twelve-byte code (`Alpha12XDR` inside `AssetXDR`, `ChangeTrustAssetXDR` and `TrustlineAssetXDR`);
  a short code is written with escaped NUL bytes, `"ABC\\0\\0"` for a three-character code. Before
  this change, `"ABC"` was accepted and produced an asset code that the network rejects as invalid.
- Breaking: `ContractSpec.nativeToXdrSCVal(val:ty:)` and `funcArgsToXdrSCValues(name:args:)` accept
  `G...` or `C...` strkeys or account or contract `SCAddressXDR` values for an `Address` parameter.
  A `MuxedAddress` parameter also accepts `M...` and `W...` strkeys or the corresponding
  `SCAddressXDR` values. Callers passing a muxed address to an `Address` parameter must use its
  underlying account or contract address, or a contract function with a `MuxedAddress` parameter.
  Claimable balance and liquidity pool addresses, malformed strings, addresses that cannot encode,
  and other value types throw `ContractSpecError.invalidType` naming the parameter type and the
  value or its type. Prebuilt `SCValXDR` values pass through; `nil` is accepted only for void or
  optional types. Before this change, an `Address` parameter also accepted an `M...` strkey and a
  64-character hex id beginning with uppercase `C`, and a `MuxedAddress` parameter threw for every
  string. A malformed string for an `Address` parameter threw `StellarSDKError`, `KeyUtilsError`,
  or `Ed25519Error`, depending on its prefix.
- Breaking: XDR definitions support CAP-0084 muxed contract addresses and CAP-0087 ML-DSA cost
  types. Add the new cases to exhaustive switches over `SCAddressType`, `SCAddressXDR`, and
  `ContractCostType`. `SCAddressType.muxedContract` has value 5; `SCAddressXDR.muxedContract`
  carries `MuxedContractXDR`, whose initializer takes `id`, then `contractId`. `ContractCostType`
  gains nine cases from `mlDsa44DecodeVerifyingKey` (86) through `verifyMlDsa87Sig` (94). XDR-JSON
  renders a muxed contract as its `W...` strkey and adds the enum names `muxed_contract` and
  `ml_dsa44_decode_verifying_key` through `verify_ml_dsa87_sig`. Before this change, decoding
  address type 5 or a cost type from 86 to 94 threw for an unknown value.
- Breaking: `SorobanAuthorizationEntryXDR.sign` rejects a muxed account (`M...`) or muxed contract
  (`W...`) credential address or `forAddress` target with `StellarSDKError.invalidArgument`;
  `withDelegates` also rejects such credentials and delegates. Use the underlying `G...` or `C...`
  address for authorization. `AssembledTransaction.signAuthEntries` and
  `WebAuthForContracts.signAuthorizationEntries` reject muxed credential addresses before writing
  any expiration or invoking a signing callback. Before this change, muxed targets and delegates
  failed with another message, entry-level `sign` and `withDelegates` accepted muxed account
  credentials, and the list signing APIs could leave unmatched entries unsigned.
- Breaking: OpenZeppelin smart-account signing rejects muxed account (`M...`) and muxed contract
  (`W...`) addresses. Pass the underlying `G...` or `C...` address to
  `OZExternalSignerManager.signAuthEntry` and
  `OZSmartAccountAuth.buildSourceAccountAuthPayloadHash`; `OZSmartAccountAuth.buildAuthPayloadHash`
  rejects an entry whose credential address is muxed. Rejection uses
  `SmartAccountTransactionException.SigningFailed`. `OZMultiSignerManager` rejects muxed wallet
  addresses in `selectedSigners` with `SmartAccountValidationException.InvalidInput` before checking
  signer availability. Before this change, the payload builders hashed muxed account credentials,
  while `OZExternalSignerManager.signAuthEntry` threw `SmartAccountSignerException.NotFound` unless
  a wallet adapter claimed the address.
- Breaking: XDR definitions support millisecond ledger close times (CAP-0088). Add cases for
  `StellarValueTypeXDR.signedMs` (3) and `emptyTxSetMs` (4), and for
  `StellarValueXDRExtXDR.signedMsValue` and `proposedMsValue`, to exhaustive switches over these
  enums. The arms carry `StellarValueXDRSignedMsValueXDR` and `StellarValueXDRProposedMsValueXDR`,
  respectively, with `closeTimeMs` as `UInt64`. `TimePointMsXDR` aliases `UInt64`. XDR-JSON uses
  `signed_ms`, `empty_tx_set_ms`, and `close_time_ms`; existing values and JSON keys retain their
  meaning. Before this change, decoding value type 3 or 4 or one of the new extension arms threw for
  an unknown discriminant.
- The Horizon compatibility matrix targets Horizon v29.0.0 and the Soroban RPC matrix targets
  stellar-rpc v29.0.1; both retain their reported coverage.
- The [SEP guide index](docs/sep/README.md) and [contract parser
  guide](docs/soroban.md#contract-parser) document SEP-46 metadata, SEP-47 interface discovery, and
  SEP-48 interface specifications. The parser example shows the declared SEP numbers in
  `SorobanContractInfo.supportedSeps`. The agent skill documents the same three SEPs.
- The documentation and agent skill 1.9.0 cover muxed contract addresses (`W...`), the
  `ContractSpec` address rules, and the refusal of muxed addresses in Soroban authorization. They
  state the unsigned placeholder rule, the expiration rule of `signAuthEntries`, the host key order
  of map arguments, the issuer order of liquidity pool assets, the five-byte floor of twelve-byte
  XDR-JSON asset codes, and the top-level `diagnosticEventsXdr` field. The [delegated
  authorization example](docs/soroban.md#delegated-authorization) runs as printed, and the
  [documentation index](docs/README.md) lists the migration guides.
- The repository documents its build, test, generation and contribution rules in `AGENTS.md` and
  `CONTRIBUTING.md`; CI checks the repository paths and globs that `AGENTS.md` names.

### Deprecated
- `TransactionEvents.diagnosticEventsXdr` is deprecated because stellar-rpc supplies diagnostic
  events at the transaction's top level. Read `GetTransactionResponse.diagnosticEventsXdr` for a
  single transaction or `TransactionInfo.diagnosticEventsXdr` for a transaction list. The deprecated
  property continues decoding the nested field in older response data.

### Fixed
- Breaking: `AssembledTransaction.signAuthEntries` and `SorobanAuthorizationEntryXDR.sign` keep
  `signatureExpirationLedger` when any top-level or delegate node already carries a signature, so
  earlier signatures stay valid when another signer signs the entry. Callers must omit an explicit
  expiration or pass the stored value; a conflicting `validUntilLedgerSeq` or
  `signatureExpirationLedger` throws `StellarSDKError.invalidArgument` naming both values.
  `signAuthEntries` fetches the latest ledger at most once, only for unsigned entries that need the
  default of the latest ledger plus 100. The transaction's auth entries are replaced only after
  every matching entry signs successfully, so a failure leaves them unchanged. Before this change,
  `signAuthEntries` passed a fresh expiration ledger on every call. A second signer whose call
  computed a later default or passed another explicit value therefore signed a different payload
  than the first, and the host rejected the entry. A signature value of void or an empty vector
  counts as unsigned; `SorobanAuthorizationEntryXDR.carriesSignature(_:)` exposes the check.
- Breaking: `ContractSpec` builds maps and map-encoded structs in the Soroban host's key order.
  Callers must supply distinct keys; keys equal in host order throw
  `StellarSDKError.invalidArgument` naming the duplicate key. The public `compareScValHostOrder`
  comparator covers every value type, including signed integer and nonce ordering, and
  `SCValXDR.sortedMap(_:)` sorts and validates caller-supplied entries. Decoding preserves the wire
  order. Before this change, `ContractSpec` emitted the entries in insertion order, and the host
  rejected an argument whose keys were out of order.
- Breaking: `ChangeTrustAsset` validates credit assets of the same type and code by the issuers' raw
  32-byte public keys, as stellar-core does. Strkey text orders some issuer pairs differently.
  Construction and `ChangeTrustAsset.fromXDR(assetXDR:)` accept the correct order and reject the
  reversed pair with `StellarSDKError.invalidArgument` naming both assets. Before this change, the
  SDK used that text order, so for such a pair it rejected the order stellar-core accepts and
  accepted the reversed one.
- Breaking: `AssembledTransaction.sign` stops on every unsigned account that
  `needsNonInvokerSigningBy` reports, at the top level of an entry and in its delegate nodes at any
  depth. It never stops on a contract address, because the contract's `__check_auth` decides which
  signatures it needs. Before this change, `sign` treated an unsigned account at the top level of a
  `SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES` entry as satisfied when every delegate node carried a
  signature. It skipped every other unsigned entry of that account as well, and the host rejected
  the envelope, because an account authenticates with its own signatures (CAP-71). It also stopped
  on every unsigned contract address.
- `GetTransactionResponse` decodes the top-level `diagnosticEventsXdr` list returned by
  `SorobanServer.getTransaction(transactionHash:)`. Before this change, events that stellar-rpc
  supplied outside the nested events object went unread. The documentation of
  `GetTransactionResponse.latestLedgerCloseTime` describes the latest ledger's close time.
