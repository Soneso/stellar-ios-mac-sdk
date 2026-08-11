# SEP-51: XDR-JSON

Convert any XDR structure the SDK models to JSON and back, without losing a byte.

## Overview

> **Note:** SEP-51 is currently in Draft status (v2.0.1). The specification may evolve before reaching final status.

Stellar's wire format is XDR, and base64 XDR is what you submit to the network. A base64 blob is unreadable to a person and useless to a diff tool. SEP-51 defines a canonical JSON form for the same structures, so a transaction envelope, a ledger entry, a contract value or an operation result can be written down as JSON and read back as the identical XDR bytes.

Use it when you need to:

- Inspect an envelope or a result in a log, a bug report or a code review
- Diff two transactions field by field instead of comparing base64 blobs
- Store test fixtures in a form a reviewer can read
- Exchange XDR structures with tooling written against another SDK

Every generated XDR type gains five members:

```swift
func toXdrJson() throws -> String
func toXdrJsonValue() throws -> XdrJsonValue
static func fromXdrJson(_ json: String) throws -> Self
static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> Self
static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> Self
```

The two `String` members are what most code uses. The tree members exist for callers that want to inspect or build the document structurally rather than through text.

## Quick example

Read a base64 transaction envelope, render it as JSON, and read it back:

```swift
import stellarsdk
import Foundation

let xdrBase64 = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                     data: Data(base64Encoded: xdrBase64)!)

let json = try envelope.toXdrJson()
print(json)

// And back to the identical bytes
let restored = try TransactionEnvelopeXDR.fromXdrJson(json)
let restoredBase64 = Data(try XDREncoder.encode(restored)).base64EncodedString()
assert(restoredBase64 == xdrBase64)
```

Output (line-wrapped here; the SDK emits one line):

```json
{"tx":{"tx":{"source_account":"GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN",
"fee":100,"seq_num":"46489056724385793","cond":{"time":{"min_time":"1535756672",
"max_time":"1567292672"}},"memo":{"text":"Enjoy this transaction"},"operations":[
{"source_account":null,"body":{"payment":{
"destination":"GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O",
"asset":{"credit_alphanum4":{"asset_code":"USD",
"issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}},
"amount":"400004000"}}}],"ext":"v0"},"signatures":[{"hint":"4aa07ed0",
"signature":"defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d3
1b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c"}]}}
```

## Detailed usage

### Converting a value to JSON

Any generated XDR type works the same way:

```swift
import stellarsdk

let bounds = TimeBoundsXDR(minTime: 1700000000, maxTime: 1700003600)
print(try bounds.toXdrJson())
// {"min_time":"1700000000","max_time":"1700003600"}

let asset = try AssetXDR(assetCode: "USD",
                         issuer: try KeyPair(accountId: "GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"))
print(try asset.toXdrJson())
// {"credit_alphanum4":{"asset_code":"USD","issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}}

print(try AssetXDR.native.toXdrJson())
// "native"
```

Output is canonical: one line, no insignificant whitespace, object keys in the order the XDR file declares the fields.

### Working with the tree

`toXdrJsonValue()` returns the document as an `XdrJsonValue` before it is written to text, which is what you want when you need to read one field rather than the whole document:

```swift
import stellarsdk

let bounds = TimeBoundsXDR(minTime: 1700000000, maxTime: 1700003600)
let tree = try bounds.toXdrJsonValue()

if case .string(let minTime)? = tree.member("min_time") {
    print(minTime) // 1700000000
}
```

`XdrJsonValue` is an ordered tree: `.object` holds `XdrJsonMember` values in declaration order rather than a dictionary, because canonical XDR-JSON depends on key order and no Foundation container preserves it. Numbers are held as the literal decimal text from the document, so a 64-bit value never passes through `Double`.

To read a value from a tree you built by hand, use `fromXdrJsonTree(_:)` rather than `fromXdrJsonValue(_:)`. Both accept the same input; `fromXdrJsonTree` additionally bounds the nesting depth, which text input already gets from the parser:

```swift
import stellarsdk

let tree = XdrJsonValue.object([
    XdrJsonMember(key: "min_time", value: .string("0")),
    XdrJsonMember(key: "max_time", value: .string("1"))
])

let bounds = try TimeBoundsXDR.fromXdrJsonTree(tree)
```

### Types that share one Swift type

Several XDR typedefs collapse onto the same Swift type. `HashXDR`, `ContractIDXDR` and `PoolIDXDR` are all `WrappedData32`, and `AssetCode4XDR`, `ThresholdsXDR` and `SignatureHintXDR` are all `WrappedData4`. Their JSON forms differ: a hash is hex, a contract ID is a `C…` strkey, a pool ID is an `L…` strkey. So the shared Swift type carries no conversion of its own. There is no correct answer it could give.

Each of those typedefs instead gets a codec namespace with the same five operations:

```swift
import stellarsdk
import Foundation

let raw = WrappedData32(Data(repeating: 0x0b, count: 32))

print(try HashXDRJsonCodec.toXdrJson(raw))
// "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"

print(try ContractIDXDRJsonCodec.toXdrJson(raw))
// "CAFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQX4KO"

print(try PoolIDXDRJsonCodec.toXdrJson(raw))
// "LAFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQXFAD"
```

There are 29 such namespaces, one per collapsed typedef, each named `<TypeName>JsonCodec`. `WrappedData4`, `WrappedData12`, `WrappedData16`, `WrappedData32`, `Data`, `String`, `Int32`, `UInt32`, `Int64`, `UInt64`, `Array` and `Optional` carry no XDR-JSON members for the same reason.

The same rule applies one level up, where two XDR definitions share a Swift type and disagree on field names. `PathPaymentOperationXDR` is the Swift form of both `PathPaymentStrictReceiveOp` (`send_max`, `dest_amount`) and `PathPaymentStrictSendOp` (`send_amount`, `dest_min`); `ManageOfferOperationXDR` covers `ManageSellOfferOp` (`amount`) and `ManageBuyOfferOp` (`buy_amount`); `PathPaymentResultCode` and `PathPaymentResultXDR` disagree on one member. Those four types carry no XDR-JSON members. Convert the enclosing `OperationXDR` or `OperationResultXDR` instead, which knows which definition applies:

```swift
import stellarsdk

// Convert the operation, not its body.
let operation = try OperationXDR.fromXdrJson(#"""
{"source_account":null,"body":{"manage_sell_offer":{"selling":"native","buying":{"credit_alphanum4":{"asset_code":"USD","issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}},"amount":"7","price":{"n":1,"d":2},"offer_id":"0"}}}
"""#)
print(try operation.toXdrJson())
```

### Booleans

An XDR `bool` is a JSON boolean, `true` or `false`, never `1`, `"true"` or `0`. Input is just as strict: `"true"` and `1` are both rejected for a boolean field.

```swift
import stellarsdk

let iterator = EvictionIteratorXDR(bucketListLevel: 3,
                                   isCurrBucket: true,
                                   bucketFileOffset: 4096)
print(try iterator.toXdrJson())
// {"bucket_list_level":3,"is_curr_bucket":true,"bucket_file_offset":"4096"}
```

The same document also shows the integer widths side by side: `bucket_list_level` is a 32-bit field and stays a number, while `bucket_file_offset` is 64-bit and becomes a string.

### 64-bit integers are strings

32-bit integers are JSON numbers. 64-bit integers are base-10 strings, because JSON numbers are doubles in most parsers and would lose precision above 2^53:

```swift
import stellarsdk

print(try LiabilitiesXDR(buying: -1, selling: 5).toXdrJson())
// {"buying":"-1","selling":"5"}
```

The same applies to a 64-bit value converted on its own, not only nested in a struct. On input, a JSON number is also accepted for a 64-bit field, which the specification allows for compatibility with XDR-JSON v1 documents. Output is always a string.

`Int128PartsXDR`, `UInt128PartsXDR`, `Int256PartsXDR` and `UInt256PartsXDR` render as a single base-10 string of the reassembled integer rather than as their limbs.

### Optional fields and void union arms

Two shapes look similar and mean different things.

An **optional XDR field** renders as `null` when absent, and its key stays present. Dropping the key is an error, not a shorthand:

```json
{"source_account":null,"body":{"payment":{...}}}
```

A **void union arm** renders as a bare string naming the arm, with no object around it:

```swift
import stellarsdk

print(try MemoXDR.none.toXdrJson())     // "none"
print(try AssetXDR.native.toXdrJson())  // "native"
```

A union arm that carries a value renders as a single-key object instead:

```swift
import stellarsdk

print(try MemoXDR.text("tag\ttest").toXdrJson())
// {"text":"tag\\ttest"}
```

Writing a void arm as `{"inflation":null}` is the mistake this distinction invites, and it is rejected:

```
OperationBodyXDR.inflation: this arm carries no value, so it is written as a bare string
```

Extension points are void arms of an integer-cased union, so they render as `"v0"` rather than `0`.

### Strings

An XDR `string<>` is escaped byte by byte before it becomes a JSON string: `0x00` to `\0`, `0x09` to `\t`, `0x0A` to `\n`, `0x0D` to `\r`, `0x5C` to `\\`, printable ASCII verbatim, and everything else to `\xNN` with lowercase hex digits. The result is then escaped a second time by the JSON writer, which is why the tab above appears as `\\t` in the document.

### Byte equality and structural equality

The SDK emits canonical output, so converting the same value twice gives the same bytes. That guarantee does not extend to documents from elsewhere. Another producer may indent its output, order keys differently, or escape a character the SDK does not, and still describe exactly the same XDR value. The SDK ships no normaliser for foreign input.

When you consume third-party XDR-JSON, compare values or trees rather than strings:

```swift
import stellarsdk

let canonical = #"{"min_time":"0","max_time":"1"}"#
let foreign   = #"{ "max_time" : "1", "min_time" : "0" }"#

// Wrong: these differ as text.
assert(canonical != foreign)

// Right: they describe the same value.
let a = try TimeBoundsXDR.fromXdrJson(canonical)
let b = try TimeBoundsXDR.fromXdrJson(foreign)
assert(try a.toXdrJson() == b.toXdrJson())
```

### Input rules this SDK applies

These are SDK rules, not requirements of SEP-51. Input is a strict subset of what the reference implementation accepts, so a malformed document is caught rather than guessed at. On output, the SDK emits exactly what the reference emits for every form the two agree on, and those documents stay valid for other consumers. The exceptions are the three divergences below, where the reference departs from the specification text.

Rejected on input:

| Input | Reason |
|---|---|
| Uppercase or mixed-case hex (`"0A1B"`) | Canonical XDR-JSON hex is lowercase |
| Uppercase `\X` in a string escape | The escape ladder writes `\x`; `\X` is not one of its sequences |
| Uppercase hex digits after `\x` (`\xC3`) | Canonical escapes use lowercase hex digits |
| Any other unrecognised escape, a trailing backslash | Not part of the escape ladder |
| Odd-length hex, or hex of the wrong length for a fixed opaque field | Not decodable to the declared byte count |
| Duplicate object keys | No canonical meaning |
| Any key the type does not declare | A misspelled field name would otherwise be silently dropped |
| `1e10`, `1.0`, `0x10`, `+1`, or an integer with surrounding whitespace | Integers are plain base-10 literals |

A field named `type` in the XDR is emitted as `type`. The spelling `type_`, which older tooling produces, is accepted as an alias for it. Supplying both in one document is a duplicate key and is rejected whether or not the two values agree.

### The `$schema` property

SEP-51 says a JSON object should allow, but not require, a `$schema` property. The SDK accepts it at every struct and union entry point, strips it, and never emits it:

```swift
import stellarsdk

let withSchema = #"{"$schema":"https://example.com/xdr.json","min_time":"0","max_time":"1"}"#
let bounds = try TimeBoundsXDR.fromXdrJson(withSchema)
print(try bounds.toXdrJson())
// {"min_time":"0","max_time":"1"}
```

An object consisting only of `$schema` is rejected: stripping it would leave nothing to read.

The reference implementation rejects `$schema` on input, which contradicts the schema its own tooling publishes. Accepting it is the only place where this SDK deliberately takes input the reference refuses. It is not the only place the two disagree: the first two divergences below are output-side, and the reference will not read back the text this SDK emits for them.

### Deliberate divergences from the reference implementation

Three points where the SDK follows the specification text and the `stellar-xdr` reference build does not. In each case the SDK's form is what SEP-51 requires.

1. **A 64-bit integer converted on its own is a string.** The reference CLI renders a top-level `Int64` as a JSON number while rendering the same type nested in a struct as a string. SEP-51 §Hyper Integer requires the string in both positions.
2. **Fixed-length opaque data declared inline is hex.** Where the XDR file declares a named typedef such as `Hash` the reference emits hex; where it declares `opaque key[32]` inline, it emits an array of byte numbers. SEP-51 §Fixed-Length Opaque Data requires hex in both cases. Affected here: `Curve25519SecretXDR.key`, `Curve25519PublicXDR.key`, `HmacSha256KeyXDR.key`, `HmacSha256MacXDR.mac`, `ShortHashSeedXDR.seed`, `SerializedBinaryFuseFilterXDR`, and the `PeerAddressXDRIpXDR` arms.
3. **`$schema` is accepted on input**, as described above.

### Limitations

**Non-UTF-8 strings.** The escape ladder is byte-wise and reversible for any byte, but the SDK stores every XDR `string<>` in a Swift `String`, which is always well-formed Unicode. An XDR string carrying invalid UTF-8 cannot be held by this SDK at any layer, so those documents cannot be round-tripped here. Opaque fields are `Data` and are byte-exact, so asset codes and hashes are unaffected.

**Zero-length signed payloads.** A `SignerKey` of type `ED25519_SIGNED_PAYLOAD` with an empty payload is valid XDR, but no `P…` strkey the ecosystem accepts encodes it. Converting one raises `XdrJsonError.unrepresentable` rather than emitting a strkey other software will reject. Payloads of one byte and longer convert normally.

## Error handling

Every failure is an `XdrJsonError`. Each case names the type being converted and, where one applies, the offending key, so a failure deep inside an envelope can be located without re-running the conversion. `message` renders a one-line description.

```swift
import stellarsdk

do {
    let _ = try TimeBoundsXDR.fromXdrJson(#"{"min_time":"0","max_time":"1","foo":1}"#)
} catch let error as XdrJsonError {
    print(error.message)
    // TimeBoundsXDR: unknown key "foo"; declared keys are min_time, max_time
}
```

| Case | Raised when |
|---|---|
| `malformedJson(message:)` | The text is not well-formed JSON |
| `unexpectedType(type:key:expected:got:)` | A value has the wrong JSON type for its field |
| `missingField(type:key:)` | A declared key is absent |
| `duplicateKey(type:key:)` | An object carries the same key twice |
| `unknownEnumValue(type:value:)` | A string names no member of the enumeration |
| `unknownUnionArm(type:key:)` | An object key names no arm of the union |
| `unknownField(type:keys:declared:)` | An object carries keys the type does not declare |
| `invalidValue(type:key:message:)` | The JSON type is right but the value is out of domain |
| `recursionLimitExceeded(limit:)` | The document nests more than 128 containers |
| `unrepresentable(type:message:)` | The XDR value has no XDR-JSON form the ecosystem accepts |

Typical messages:

```
TimeBoundsXDR: missing key "max_time"
TimeBoundsXDR.min_time: expected string or number, got boolean
TimeBoundsXDR.min_time: not a base-10 integer: 1e10
AssetType: unknown value "bogus"
MemoXDR: unknown union arm "bogus"
Ed25519SignedPayload: a signed payload of zero length has no strkey the ecosystem accepts
```

Untrusted text in a message is truncated and escaped, so an error echoed into a terminal cannot carry escape sequences of its own.

### Duplicate keys depend on the entry point

A duplicate key raises a different case depending on where the document came from, and a caller matching on the case has to accept both.

Reading **text** raises `malformedJson`. The parser rejects the duplicate before any type is in hand, so naming a type would be a guess:

```swift
import stellarsdk

do {
    let _ = try TimeBoundsXDR.fromXdrJson(#"{"min_time":"0","min_time":"1","max_time":"1"}"#)
} catch let error as XdrJsonError {
    print(error.message)
    // malformed JSON: duplicate object key "min_time"
}
```

Reading a **hand-built tree** raises `duplicateKey`, which can name the type, because the tree reached the type's own decoder without passing through the parser:

```swift
import stellarsdk

let tree = XdrJsonValue.object([
    XdrJsonMember(key: "min_time", value: .string("0")),
    XdrJsonMember(key: "min_time", value: .string("1")),
    XdrJsonMember(key: "max_time", value: .string("1"))
])

do {
    let _ = try TimeBoundsXDR.fromXdrJsonTree(tree)
} catch let error as XdrJsonError {
    print(error.message)
    // TimeBoundsXDR: duplicate key "min_time"
}
```

Both messages say "duplicate". Only the case differs.

## When not to use XDR-JSON

XDR-JSON is a developer-tooling and interchange format. It is not a wire format.

- **Do not submit it.** Horizon and the RPC server take base64 XDR. Convert back with `XDREncoder.encode` before submitting.
- **Do not store it in place of base64 XDR** where the bytes matter. A round trip through this SDK is exact, but the JSON form is larger and its stability across protocol versions is the stability of the XDR definitions, not of a frozen format.
- **Do not sign it.** Signatures are over XDR bytes.
- **Do not use it for Horizon or RPC responses.** SEP-51 maps XDR structures. The JSON those servers return is their own API format and is unrelated.

## Compatibility

See the [SEP-0051 compatibility matrix](../../compatibility/sep/SEP-0051_COMPATIBILITY_MATRIX.md) for the field-by-field coverage of the specification.

## Related SEPs

- [SEP-11](sep-11.md) - Txrep, a human-readable text representation of transactions
- [SEP-23](sep-23.md) - Strkey encoding, which supplies the `G…`, `C…`, `L…`, `B…` and `P…` forms used here

## Reference

- [SEP-51 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md)
- [XdrJsonCodable source code](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/xdr_json/XdrJsonCodable.swift)
- [XdrJsonError source code](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/xdr_json/XdrJsonError.swift)

---

[Back to SEP Overview](README.md)
