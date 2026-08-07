# SEP-51: XDR-JSON

**Purpose:** Convert any XDR structure to canonical JSON and back, byte for byte
**Prerequisites:** None
**SDK Protocol:** `XdrJsonCodable`, implemented by every generated XDR type

SEP-51 defines a canonical JSON mapping for Stellar's XDR structures. Use it for logs, diffs, test fixtures and interchange with tooling written against other SDKs. Do not use it as a wire format: Horizon and the RPC server take base64 XDR.

## API

Every generated XDR type in `stellarsdk` gains five members. No extra imports beyond `import stellarsdk`.

```swift
func toXdrJson() throws -> String
func toXdrJsonValue() throws -> XdrJsonValue
static func fromXdrJson(_ json: String) throws -> Self
static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> Self
static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> Self
```

Use `fromXdrJson(_:)` for text and `fromXdrJsonTree(_:)` for a tree you built by hand. `fromXdrJsonValue(_:)` is the recursion entry point and performs no depth check of its own.

Output is canonical: one line, no insignificant whitespace, object keys in XDR declaration order.

## Usage

### Envelope to JSON and back

```swift
import stellarsdk
import Foundation

let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                     data: Data(base64Encoded: xdrBase64)!)
let json = try envelope.toXdrJson()

let restored = try TransactionEnvelopeXDR.fromXdrJson(json)
let base64 = Data(try XDREncoder.encode(restored)).base64EncodedString()
assert(base64 == xdrBase64)
```

### Any XDR type

```swift
import stellarsdk

try TimeBoundsXDR(minTime: 1700000000, maxTime: 1700003600).toXdrJson()
// {"min_time":"1700000000","max_time":"1700003600"}

try AssetXDR.native.toXdrJson()
// "native"

try MemoXDR.text("hello").toXdrJson()
// {"text":"hello"}
```

### Reading one field without decoding the whole document

```swift
import stellarsdk

let tree = try bounds.toXdrJsonValue()
if case .string(let minTime)? = tree.member("min_time") {
    print(minTime)
}
```

`XdrJsonValue` is an ordered tree (`.null`, `.bool`, `.number(String)`, `.string`, `.array`, `.object([XdrJsonMember])`). Numbers hold the literal decimal text from the document, so 64-bit precision survives.

## Mapping rules

| XDR | JSON |
|-----|------|
| `int`, `unsigned int` | number |
| `hyper`, `unsigned hyper` | base-10 **string** (a number is accepted on input) |
| `bool` | `true` / `false` |
| `opaque[N]`, `opaque<>` | lowercase hex string, empty is `""` |
| `string<>` | escaped string (`\0`, `\t`, `\n`, `\r`, `\\`, printable ASCII, else `\xNN`) |
| array | JSON array, empty is `[]` |
| enum | snake_case member name, shared prefix stripped |
| struct | object, keys in declaration order |
| union, void arm | bare string naming the arm |
| union, valued arm | single-key object `{"arm": value}` |
| int-cased union | `"v0"`, `{"v1": value}` |
| optional | `null` or the value; **the key stays present** |
| `AccountID`, `PublicKey`, `NodeID` | `G…` strkey |
| `MuxedAccount` | `G…` or `M…` |
| `ContractID` / `PoolID` / `ClaimableBalanceID` | `C…` / `L…` / `B…` |
| `SignerKey` | `G…` / `T…` / `X…` / `P…` |
| `AssetCode4` / `AssetCode12` | trailing NULs trimmed, then escaped |
| `Int128Parts` and the other three parts types | one base-10 decimal string |
| `$schema` | accepted on input, stripped, never emitted |

## Types with no members

Some XDR definitions share a Swift type and render differently, so the shared type carries no conversion.

**Collapsed typedefs** get a codec namespace instead. There are 29, each named `<TypeName>JsonCodec` with the same five operations as a free function taking the value:

```swift
import stellarsdk
import Foundation

let raw = WrappedData32(Data(repeating: 0x0b, count: 32))
try HashXDRJsonCodec.toXdrJson(raw)        // "0b0b…0b"
try ContractIDXDRJsonCodec.toXdrJson(raw)  // "CAFQ…X4KO"
try PoolIDXDRJsonCodec.toXdrJson(raw)      // "LAFQ…XFAD"
```

`WrappedData4`, `WrappedData12`, `WrappedData16`, `WrappedData32`, `Data`, `String`, `Int64`, `UInt64`, `Array` and `Optional` have no XDR-JSON members.

**Divergent operation and result types.** `PathPaymentOperationXDR`, `ManageOfferOperationXDR`, `PathPaymentResultCode` and `PathPaymentResultXDR` each cover two XDR definitions that disagree on field names, so they carry no members. Convert the enclosing `OperationXDR` or `OperationResultXDR`, which knows which definition applies.

## Errors

Every failure is an `XdrJsonError`. Read `error.message` for a one-line description naming the type and key.

| Case | Raised when |
|---|---|
| `malformedJson(message:)` | Not well-formed JSON. Also what a duplicate key in **text** raises |
| `unexpectedType(type:key:expected:got:)` | Wrong JSON type for the field |
| `missingField(type:key:)` | A declared key is absent |
| `duplicateKey(type:key:)` | Same key twice in a **hand-built tree** |
| `unknownEnumValue(type:value:)` | String names no enum member |
| `unknownUnionArm(type:key:)` | Key names no union arm |
| `unknownField(type:keys:declared:)` | Keys the type does not declare |
| `invalidValue(type:key:message:)` | Right JSON type, value out of domain |
| `recursionLimitExceeded(limit:)` | More than 128 nested containers |
| `unrepresentable(type:message:)` | No XDR-JSON form the ecosystem accepts |

A duplicate key raises a different case depending on the entry point. Text raises `malformedJson`, because the parser rejects it before any type is in hand; a hand-built tree raises `duplicateKey`, which can name the type. Code matching on the case has to accept both.

## Input rules

Input is stricter than the reference implementation. These are SDK rules, not spec requirements; everything the SDK emits stays valid for other consumers.

Rejected: uppercase or mixed-case hex, uppercase `\XNN` escapes, unrecognised escapes, a trailing backslash, odd-length hex, hex of the wrong length for a fixed opaque field, duplicate keys, any key the type does not declare, and the integer forms `1e10`, `1.0`, `0x10`, `+1` or with surrounding whitespace.

A field named `type` is emitted as `type` and also accepts the alias `type_`. Supplying both is a duplicate key.

## Limitations

- **Non-UTF-8 strings.** Every XDR `string<>` is a Swift `String`, so a value carrying invalid UTF-8 cannot be held by the SDK at all. Opaque fields are `Data` and are byte-exact.
- **Zero-length signed payloads.** A `SignerKey` of type `ED25519_SIGNED_PAYLOAD` with an empty payload raises `unrepresentable`: no `P…` strkey the ecosystem accepts encodes it. One byte and longer convert normally.

## Divergences from the reference implementation

The SDK follows the specification text where the `stellar-xdr` reference build does not:

1. A 64-bit integer converted on its own is a string, not a number.
2. Fixed-length opaque data declared inline in the XDR file is hex, not an array of byte numbers. Affects `Curve25519SecretXDR.key`, `Curve25519PublicXDR.key`, `HmacSha256KeyXDR.key`, `HmacSha256MacXDR.mac`, `ShortHashSeedXDR.seed`, `SerializedBinaryFuseFilterXDR` and the `PeerAddressXDRIpXDR` arms.
3. `$schema` is accepted on input.

## Cross-SDK compatibility

XDR-JSON produced by this SDK is byte-identical to the reference implementation for every type they share, except in the three divergences above, where the SDK follows the specification text and the reference does not. Those three are also the cases where the pinned reference build refuses to read a document this SDK emits: it rejects a standalone 64-bit integer written as a string (`invalid type: string "-9223372036854775808", expected i64`) and inline fixed-length opaque data written as hex (`expected an array of length 32`). Documents interchange with any other SDK implementing SEP-51 v2.0.1.
