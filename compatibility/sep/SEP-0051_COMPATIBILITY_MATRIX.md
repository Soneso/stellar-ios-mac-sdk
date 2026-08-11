# SEP-0051 (XDR-JSON) Compatibility Matrix

**Generated:** 2026-08-11

**SDK Version:** 3.9.0

**SEP Version:** 2.0.1

**SEP Status:** Draft

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md

## SEP Summary

This proposal defines XDR-JSON, a standard mapping between Stellar's XDR (External Data Representation) structures and a JSON representation.

## Overall Coverage

**Total Coverage:** 100.0% (47/47 fields)

- ✅ **Implemented:** 47/47
- ❌ **Not Implemented:** 0/47

**Required Fields:** 100.0% (44/44)

**Optional Fields:** 100.0% (3/3)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/xdr_json/XdrJson.swift`
- `stellarsdk/stellarsdk/xdr_json/XdrJsonCodable.swift`
- `stellarsdk/stellarsdk/xdr_json/XdrJsonError.swift`
- `stellarsdk/stellarsdk/xdr_json/XdrJsonParser.swift`
- `stellarsdk/stellarsdk/xdr_json/XdrJsonValue.swift`
- `stellarsdk/stellarsdk/xdr_json/XdrJsonWriter.swift`
- `stellarsdk/stellarsdk/xdr_json/XdrWideInteger.swift`
- `stellarsdk/stellarsdk/xdr_json/handwritten/PublicKey+XdrJson.swift`
- `stellarsdk/stellarsdk/xdr_json/handwritten/Transaction+XdrJson.swift`
- `stellarsdk/stellarsdk/xdr_json/handwritten/TransactionEnvelope+XdrJson.swift`
- `stellarsdk/stellarsdk/responses/xdr/`

### Key Classes

- **`XdrJsonCodable`**: Protocol XDR types conform to, declaring toXdrJsonValue() and fromXdrJsonValue(_:) and deriving toXdrJson(), fromXdrJson(_:) and fromXdrJsonTree(_:); the three transaction envelope classes carry the same five members without the conformance
- **`XdrJsonValue`**: XDR-JSON document tree (null, bool, number, string, array, object) holding object members in XDR declaration order
- **`XdrJsonMember`**: One key and value of an XdrJsonValue object
- **`XdrJson`**: Shared runtime carrying the escaping, hex, strkey, integer, container and depth rules every conversion applies
- **`XdrJsonWriter`**: Renders an XdrJsonValue as XDR-JSON text with no insignificant whitespace
- **`XdrJsonParser`**: Parses XDR-JSON text into an XdrJsonValue
- **`XdrWideInteger`**: Base-10 conversion for the 128-bit and 256-bit integer parts types
- **`XdrJsonError`**: Error enum for conversion failures (malformedJson, unexpectedType, missingField, duplicateKey, unknownEnumValue, unknownUnionArm, unknownField, invalidValue, recursionLimitExceeded, unrepresentable)
- **`<Name>JsonCodec`**: Conversion entry points for XDR types a Swift typealias collapses onto another type, such as HashXDRJsonCodec, AccountIDXDRJsonCodec and AssetCode4XDRJsonCodec

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| XDR Data Types | 100.0% | 100.0% | 18 | 18 |
| Address Types | 100.0% | 100.0% | 12 | 12 |
| Asset Code Types | 100.0% | 100.0% | 3 | 3 |
| Integer Types | 100.0% | 100.0% | 4 | 4 |
| JSON Schema | 100.0% | 100.0% | 1 | 1 |
| XDR-JSON v1 Compatibility | 100.0% | 100.0% | 2 | 2 |
| Implementation Support | 100.0% | 100.0% | 7 | 7 |

## Detailed Field Comparison

### XDR Data Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `integer_32bit` | ✓ | ✅ | `XdrJson.int32` | 32-bit signed integer maps to a JSON number |
| `unsigned_integer_32bit` | ✓ | ✅ | `XdrJson.uint32` | 32-bit unsigned integer maps to a JSON number |
| `hyper_integer_64bit` | ✓ | ✅ | `XdrJson.int64` | 64-bit signed integer maps to a JSON string holding a base-10 integer |
| `unsigned_hyper_integer_64bit` | ✓ | ✅ | `XdrJson.uint64` | 64-bit unsigned integer maps to a JSON string holding a base-10 integer |
| `boolean` | ✓ | ✅ | `XdrJson.bool` | Boolean maps to a JSON boolean |
| `opaque_fixed_length` | ✓ | ✅ | `XdrJson.hex (declared width checked)` | Fixed-length opaque data maps to a hexadecimal string of the declared width |
| `opaque_variable_length` | ✓ | ✅ | `XdrJson.hex` | Variable-length opaque data maps to a hexadecimal string |
| `string_escape_ladder` | ✓ | ✅ | `XdrJson.escapedText / XdrJson.unescapeString` | String bytes escape nul, tab, line feed, carriage return and backslash by name, keep printable ASCII verbatim, and write every other byte as \xNN |
| `string_json_escaping` | ✓ | ✅ | `XdrJsonWriter.writeString` | Backslashes in an escaped string are escaped a second time when stored in JSON |
| `array_fixed_length` | ✓ | ✅ | `XdrJson.array (declared element count enforced)` | Fixed-length array maps to a JSON array of the declared element count |
| `array_variable_length` | ✓ | ✅ | `XdrJson.array` | Variable-length array maps to a JSON array |
| `enum_name_mapping` | ✓ | ✅ | `AssetType (snake_case, shared prefix removed)` | Enum maps to a JSON string: the identifier in snake_case with any shared prefix removed |
| `struct_object_keys` | ✓ | ✅ | `XdrJson.object` | Struct maps to a JSON object keyed by the member names in snake_case |
| `union_void_arm` | ✓ | ✅ | `AssetXDR (void arm as a bare string)` | A union whose active arm is void maps to a JSON string holding the arm name |
| `union_valued_arm` | ✓ | ✅ | `XdrJson.singleKeyObject` | A union whose active arm carries a value maps to a single-key JSON object |
| `union_integer_cases` | ✓ | ✅ | `AccountEntryExtXDR (v0, v1)` | A union switching on an integer names its arms by discriminant plus integer, such as v0 |
| `void` | ✓ | ✅ | `AssetXDR (object form of a void arm rejected)` | Void carries no JSON value of its own; the object form of a void arm is rejected |
| `optional_null` | ✓ | ✅ | `XdrJson.optional` | An absent optional maps to null and its key stays present in the parent object |

### Address Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `sc_address` | ✓ | ✅ | `SCAddressXDR` | ScAddress maps to a G, C, M, B or L strkey according to its arm |
| `account_id` | ✓ | ✅ | `AccountIDXDRJsonCodec` | AccountID maps to a G strkey |
| `contract_id` | ✓ | ✅ | `ContractIDXDRJsonCodec` | ContractID maps to a C strkey |
| `muxed_account` | ✓ | ✅ | `MuxedAccountXDR` | MuxedAccount maps to a G strkey for ed25519 and an M strkey for muxed ed25519 |
| `muxed_account_med25519` | ✓ | ✅ | `MuxedAccountMed25519XDR` | MuxedAccountMed25519 maps to an M strkey |
| `muxed_ed25519_account` | ✓ | ✅ | `SCAddressXDR.muxedAccount` | MuxedEd25519Account maps to an M strkey |
| `pool_id` | ✓ | ✅ | `PoolIDXDRJsonCodec` | PoolID maps to an L strkey |
| `claimable_balance_id` | ✓ | ✅ | `ClaimableBalanceIDXDR` | ClaimableBalanceID maps to a B strkey |
| `public_key` | ✓ | ✅ | `PublicKey` | PublicKey maps to a G strkey |
| `node_id` | ✓ | ✅ | `NodeIDXDRJsonCodec` | NodeID maps to a G strkey |
| `signer_key` | ✓ | ✅ | `SignerKeyXDR` | SignerKey maps to a G, T, X or P strkey according to its arm |
| `signer_key_ed25519_signed_payload` | ✓ | ✅ | `Ed25519SignedPayload` | SignerKeyEd25519SignedPayload maps to a P strkey |

### Asset Code Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset_code` | ✓ | ✅ | `AllowTrustOpAssetXDR` | AssetCode reads back as AssetCode4 at four encoded characters or fewer, otherwise AssetCode12 |
| `asset_code4` | ✓ | ✅ | `AssetCode4XDRJsonCodec` | AssetCode4 drops all trailing zero bytes, then escapes the remaining bytes as a string |
| `asset_code12` | ✓ | ✅ | `AssetCode12XDRJsonCodec` | AssetCode12 drops trailing zero bytes down to a floor of five, then escapes the remaining bytes |

### Integer Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `uint128_parts` | ✓ | ✅ | `UInt128PartsXDR (XdrJson.wideDecimal)` | UInt128Parts maps to a JSON string holding the 128-bit unsigned value in base 10 |
| `int128_parts` | ✓ | ✅ | `Int128PartsXDR (XdrJson.wideDecimal)` | Int128Parts maps to a JSON string holding the 128-bit signed value in base 10 |
| `uint256_parts` | ✓ | ✅ | `UInt256PartsXDR (XdrJson.wideDecimal)` | UInt256Parts maps to a JSON string holding the 256-bit unsigned value in base 10 |
| `int256_parts` | ✓ | ✅ | `Int256PartsXDR (XdrJson.wideDecimal)` | Int256Parts maps to a JSON string holding the 256-bit signed value in base 10 |

### JSON Schema

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `schema_property` |  | ✅ | `XdrJson.stripSchema` | A $schema property is allowed but not required on any JSON object |

### XDR-JSON v1 Compatibility

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `hyper_json_number_input` |  | ✅ | `XdrJson.int64 (JSON number accepted on input)` | A JSON number is accepted where a Hyper is read; output stays a string |
| `unsigned_hyper_json_number_input` |  | ✅ | `XdrJson.uint64 (JSON number accepted on input)` | A JSON number is accepted where an Unsigned Hyper is read; output stays a string |

### Implementation Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `to_xdr_json` | ✓ | ✅ | `XdrJsonCodable.toXdrJson()` | Convert an XDR value to XDR-JSON text |
| `to_xdr_json_value` | ✓ | ✅ | `XdrJsonCodable.toXdrJsonValue()` | Convert an XDR value to an XDR-JSON tree |
| `from_xdr_json` | ✓ | ✅ | `XdrJsonCodable.fromXdrJson(_:)` | Read an XDR value from XDR-JSON text |
| `from_xdr_json_value` | ✓ | ✅ | `XdrJsonCodable.fromXdrJsonValue(_:)` | Read an XDR value from an XDR-JSON tree |
| `from_xdr_json_tree` | ✓ | ✅ | `XdrJsonCodable.fromXdrJsonTree(_:)` | Read an XDR value from a tree built by hand, with container nesting bounded |
| `typedef_codec_namespace` | ✓ | ✅ | `29 <Name>JsonCodec namespace(s)` | XDR types a typedef collapses onto another Swift type keep their own conversion entry points |
| `xdr_type_conversions` | ✓ | ✅ | `466 XDR type(s), all convertible` | Every XDR type in the SDK has an XDR-JSON conversion |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional