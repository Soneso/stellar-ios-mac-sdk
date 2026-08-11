# SEP-0051 conformance corpus

`corpus.json` pins, for a set of hand-chosen XDR values, the exact JSON text the
SDK must emit and the base64 XDR that value encodes to. The SDK's unit test
`Sep51CorpusUnitTests` walks it in both directions: JSON to XDR and XDR to JSON.

## Where the generated file lives

The generator is here; its output is committed at
`../../stellarsdk/stellarsdkUnitTests/sep/xdr_json/corpus.json`.

The split is a SwiftPM constraint. The corpus is declared as a `.copy` resource on
the unit-test target and read through `Bundle.module`, and SwiftPM resolves a
resource path relative to the target's own directory
(`stellarsdk/stellarsdkUnitTests`) and rejects one that escapes it. A corpus kept
beside its generator under `tools/` is therefore unreachable as a resource. The
alternative — duplicating it into a generated Swift constant — would give the
repository two copies of the same fixture and two places to forget to update, so
there is exactly one committed corpus file and it sits where the test target can
load it.

The corpus targets the renderings that are not mechanical — strkey-valued union
arms, integers that become strings, the escape ladder over bytes-typed and
string-typed fields, empty and populated variable-length data, optionals in both
states, and the name rules a pin bump could disturb. It is not an enumeration of
every type; the generated per-type suites cover that.

## Files

| File | Role |
|---|---|
| `seeds.py` | Hand-authored seed values, each written in XDR-JSON form. |
| `generate_corpus.py` | Encodes and decodes every seed with the reference CLI and writes the corpus. |
| `refresh_corpus.sh` | Regenerates into `.tmp/` and diffs against the committed file. |
| `../../stellarsdk/stellarsdkUnitTests/sep/xdr_json/corpus.json` | Generated and committed. Read by the unit tests, never edited by hand. |

## Ground truth

The reference is the XDR-JSON CLI pinned in `../sep-51-oracle/oracle-pin.json`.
`generate_corpus.py` verifies that pin before it does anything else and refuses
to run against a different build, because key spellings differ between reference
releases.

Every seed is encoded to XDR and decoded straight back through the reference, so
a seed that is not valid XDR-JSON for its type fails the run rather than
reaching the corpus. The decoded document — not the authored one — is what the
corpus records, which is why authoring a value in a non-canonical form is
harmless.

Fixtures come from the reference build alone. The SDK's own output is never
snapshotted into the committed file: a corpus that records what the SDK already
does can detect drift but can never report an error, which is how the same
defect survives release after release. The generator enforces this by rejecting
any seed that carries the fields the reference is supposed to produce.

## Type names

`../sep-51-oracle/type_map.json` is the sole authority on the pairing between a
Swift type name and the reference CLI's spelling of the same type. The two differ
in acronym case (`IPAddrTypeXDR` against `IpAddrType`), in the reserved-name
escape (`ErrorXDR` against `SError`) and in the `XDR` suffix this SDK appends, so
a seed whose SDK type has no mapping fails the run rather than falling back to a
derived guess.

That strictness carries a second rule. Several XDR definitions can share one
Swift type, and where their renderings disagree the Swift type has no single
correct form, so it carries no conversion of its own and only the union arm that
selects a definition can render it. The mapping records one definition per Swift
type, so a seed naming the other definition directly finds no mapping and stops
the run; those pairs are seeded through the selecting union instead, with both
arms present. A fixture exercising one side cannot see a helper that emits the
other side's names.

## No seed may carry `$schema`

SEP-0051 says a JSON object should allow, but not require, a `$schema` property.
The pinned reference **rejects** it — including on documents its own published
schema advertises the property for. The corpus is built by encoding each seed's
JSON with the reference, so a seed carrying `$schema` fails generation with
`error: unknown fields in JSON input: $schema`, which reads like a bug in the SDK
rather than a limitation of the reference.

The generator therefore refuses any seed carrying `$schema` anywhere, with that
explanation. `$schema` acceptance is a real SDK behaviour and is pinned by the
hand-written `Sep51SchemaPropertyUnitTests`, not here.

## A value reaching an XDR `string<>` must be valid UTF-8

This SDK models every XDR `string<>` as a Swift `String`, which is guaranteed
well-formed Unicode, and the binary decoder rejects a non-UTF-8 payload outright.
A value carrying a lone continuation or lead byte therefore round-trips through
the reference but cannot be constructed, decoded or held here at any layer, so a
seed asking for one pins a conformance target the SDK is not built to meet.
Changing those field declarations to `Data` is a separate proposal.

Opaque fields are unaffected. They are backed by `Data` or `WrappedDataN` and are
byte-exact, which is why an asset code may legitimately carry a bare `\xc3`.

The document alone does not say which of the two a string came from, and the
distinction is a property of the XDR declaration that the committed artefacts do
not record. So the seed declares it: `non_utf8_paths` lists the paths whose
escape-ladder bytes are deliberately not valid UTF-8, in the syntax
`spec_form_paths` uses, and the generator fails when the declared set and the set
it finds differ in either direction. An undeclared one is the case that matters —
a `string<>` value the SDK cannot hold, caught at generation instead of as an
`invalidUTF8` deep inside the binary decoder during a Swift test.

Only a string carrying a backslash can be affected: every other rendering the
spec produces — hex, a strkey, an enum name, a decimal string — is printable
ASCII.

## Comparable and incomparable entries

Most entries are **comparable**: the reference's own output is exactly what the
SDK must emit, and the entry records it verbatim under `oracle: "reference"`.

Some entries are **incomparable**: SEP-0051 specifies one form and the reference
emits another. Those entries carry `oracle: "incomparable"`, the specified text
under `json`, the reference's text under `oracle_json`, a `reason`, and the
`spec_form` and `spec_form_paths` that derived one from the other. Two
transformations exist:

- `integer_string` — SEP-0051 §Hyper Integer requires a 64-bit integer to be a
  base-10 string. The reference emits a bare JSON number for a standalone
  `Int64` or `Uint64`.
- `opaque_hex` — SEP-0051 §Fixed-Length Opaque Data requires fixed-length opaque
  data to be a lowercase hex string. Where the `.x` declares such a field
  inline, the reference emits an array of byte numbers. The transformation walks
  the whole document, so nested occurrences and union arm payloads are rewritten
  too.

Two properties are machine-checked rather than trusted. The derived value must
actually differ from the reference's, so a divergence that quietly disappears in
a future release fails the run instead of passing unnoticed. And every
incomparable seed declares the JSON paths its transformation is expected to
rewrite; the transformation reports the paths it did rewrite, and a difference in
either direction fails the run. That second check is what makes the byte-array
heuristic safe: an integer array that is not opaque data stops the build instead
of being baked into the corpus as a hex string.

`spec_form_paths` is required on every incomparable seed with no exemption. A
seed whose transformation rewrites nothing declares the empty list; omitting the
field is a generation failure, not a default, because an absent field would read
as "not applicable" while meaning "unchecked".

Path syntax is dotted for object keys and `[n]` for array indices. The empty
string names the whole document, which is what `integer_string` rewrites. A union
arm key is an ordinary object key, so `ip.i_pv4` addresses an arm payload with the
same syntax struct fields use.

Two SEP-0051 divergences deliberately have no corpus entry. A
`SignerKeyEd25519SignedPayload` with a zero-length payload decodes to a strkey the
reference then refuses to encode, so it cannot round-trip through the generator;
and `$schema` acceptance is input-side and cannot survive the encode step above.
Both are pinned by hand-written tests.

## Input variants

An entry may carry `input_variants`: further JSON documents that must decode to
the same XDR. The corpus records what the SDK must emit and the reference emits
one spelling per key, so an accepted alternative spelling cannot arrive through
the normal path. A variant is verified by encoding it with the reference and
requiring the entry's own base64, which keeps it oracle-verified and keeps the
corpus non-self-referential. The current use is the escaped spelling `type_`,
which the reference accepts alongside the `type` it emits.

An incomparable entry may not carry variants: a variant has to be written in the
form the reference accepts, while an incomparable entry records the form SEP-0051
requires, and the two are not the same document.

## Refreshing

```bash
# Check the committed artefacts against each other, with no reference CLI
python3 generate_corpus.py --validate-committed

# Check the committed corpus against a fresh generation
bash refresh_corpus.sh

# Ask whether a newer reference build would render the corpus differently.
# Reports only; the committed corpus is never written.
STELLAR_XDR=/path/to/newer/stellar-xdr bash refresh_corpus.sh --advisory

# Rewrite it
python3 generate_corpus.py
```

`corpus.json` has no timestamp and a fixed entry and key order, so an unchanged
input produces a byte-identical file and any diff is real drift.

Re-run after either pin moves: the SDK's XDR pin, which is `XDR_COMMIT` in the
repository root `Makefile`, or the reference pin in
`../sep-51-oracle/oracle-pin.json`.

## Exit codes

`generate_corpus.py`

| Code | Meaning |
|---|---|
| 0 | Corpus written. |
| 1 | A seed failed, a declared divergence no longer holds, or a declared rewrite path set does not match what the transformation rewrote. |
| 2 | The reference CLI is missing or does not match the pin. |

`generate_corpus.py --validate-committed` checks the committed artefacts against
each other rather than against the reference, so it runs where no CLI is
installed: every seed obeys the shape rules, every seed reached the corpus with
its declared metadata unchanged, every seed's SDK type has a reference spelling
in `type_map.json`, the corpus records the pins committed today, and every
completeness assertion holds. It cannot check the recorded JSON and base64 —
those come from the reference and only `refresh_corpus.sh` can confirm them. It
writes nothing and exits 0 on agreement, 1 on disagreement, 2 when a committed
artefact it needs is absent.

`refresh_corpus.sh`

| Code | Meaning |
|---|---|
| 0 | No drift. |
| 1 | Drift; the diff is printed. |
| 2 | A prerequisite is missing. |

In `--advisory` mode the same codes mean the same things, measured against whatever build
`STELLAR_XDR` names rather than the pinned one: 0 that the build renders the corpus
identically, 1 that it does not, with the diff and any per-seed findings both printed. A seed
the build cannot process is recorded as a finding and its entry omitted, so one run
enumerates every affected seed instead of stopping at the first, and the omission shows up in
the diff as a smaller `entry_count`.

The advisory comparison ignores `reference_version` and `reference_xdr_commit`. The generated
document records the build that actually produced it, but those two fields differ on every
real release and would otherwise mask the only question being asked: does anything the SDK
emits change? `entry_count` stays in the comparison, because a dropped seed is a real
difference.

## Entry schema

| Key | Present on | Meaning |
|---|---|---|
| `type` | every entry | Reference CLI type name. |
| `ios_type` | every entry | SDK type name the entry dispatches to. |
| `xdr` | every entry | Base64 XDR of the value. |
| `json` | every entry | Compact JSON text the SDK must emit. |
| `oracle` | every entry | `reference`, `incomparable` or `spec`. |
| `note` | every entry | One sentence naming the shape the entry pins. |
| `input_variants` | optional | Further compact JSON texts that must decode to the same XDR. |
| `reason` | incomparable | Why the reference is not authoritative here. |
| `spec_form` | incomparable | `integer_string` or `opaque_hex`. |
| `spec_form_paths` | incomparable | The JSON paths the transformation rewrote. |
| `oracle_json` | incomparable | What the reference emits, recorded for the diff. |

`oracle: "spec"` covers a type the pinned reference cannot resolve at all, whose
value is written from SEP-0051 and the `.x`. The generator admits one only for a
name that `../sep-51-oracle/name-map.json` lists as unresolvable and that the
reference genuinely does not know, so the class stays empty while the reference
vendors an XDR commit at least as new as the SDK's.

## Completeness

The generator fails if the corpus loses any of the following. Each is read from
the committed artefacts, so a pin bump that changes the `.x` changes what is
required without an edit here.

- Every enum member and every type `../sep-51-oracle/name-map.json` records as
  unresolvable by the pinned reference carries a spec-derived entry.
- All three `BinaryFuseFilterType` members, the only exercise of the rule that
  prepends the prefix's first character to a remainder starting with a digit.
- Both `IPAddrType` members, the word split that yields `i_pv4`.
- Every type carrying an XDR field named `type`, and at least one of them
  carrying the alternative input spelling.
- `FeeBumpTransactionInnerTx`, whose arm key must come from its discriminant
  enum's full member list.
- Every wire name on which XDR definitions sharing one Swift type disagree, which
  is what requires both arms of each such pair.
