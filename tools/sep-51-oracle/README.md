# SEP-0051 name derivation and reference probing

Ground truth for the SDK's XDR-JSON (SEP-0051) support. These tools derive the
JSON name of every enum member, struct field and union arm from the `.x` sources
and check that derivation against a pinned build of the XDR-JSON reference CLI.

Nothing here runs at build or test time. The SDK's unit tests never invoke the
reference CLI; these tools are used when the XDR pin or the reference pin moves.

## Prerequisites

Install the pinned reference CLI (user-level, no elevated privileges):

```bash
cargo install stellar-xdr --features cli --version 28.0.0 --locked
```

It installs to `~/.cargo/bin/stellar-xdr`. Set `STELLAR_XDR` to use a binary from
another location.

The pin is recorded in `oracle-pin.json` and verified on every run. This matters
independently of the XDR commit: releases before 28.0.0 emit the Rust
keyword-escaped key `type_` where SEP-0051 requires `type`, so a name table built
with an older build would bake seven wrong keys into the SDK.

`name_map.rb` also needs the generator's Ruby gems, because it reads the `.x`
sources through the same parser and resolves Swift type names through the same
name resolution the generator uses:

```bash
cd tools/xdr-generator && bundle install
```

## Files

| File | Role |
|---|---|
| `oracle-pin.json` | The pinned reference build: version, its vendored XDR commit, and the SDK's own XDR commit (`Makefile`'s `XDR_COMMIT`). `sep_spec` records the specification revision this implementation targets. |
| `probe.sh` | Prints the reference rendering of one value, one schema, or the type list. |
| `name_map.rb` | Derives all JSON names from the `.x` sources; `--diff` checks them against the reference. |
| `name-map.json` | Frozen derivation output, including the verification summary of the last `--diff` run. |
| `emitted_names.rb` | Reads the generated Swift back and diffs the names it actually emits against `name-map.json`. |
| `type_map.json` | Maps this SDK's type names (`SCValXDR`) to the reference CLI's (`ScVal`), plus any type the reference does not know. |

## Usage

```bash
# Verify the installed CLI matches the pin
./probe.sh --check

# Render one value: probe.sh <REFERENCE TYPE NAME> <BASE64>
./probe.sh ScVal AAAAAQAAAAU=
./probe.sh --schema AccountEntryExtensionV2

# Rebuild the name table and check it against the reference
ruby name_map.rb --diff

# Check without writing: are the names right, and are the artefacts current?
ruby name_map.rb --check

# Compare against a build other than the pinned one, writing nothing
STELLAR_XDR=/path/to/newer/stellar-xdr ruby name_map.rb --advisory

# Check the committed table against the .x sources, with no reference CLI
ruby name_map.rb --offline-check

# Check the names the generator actually emitted against that table
ruby emitted_names.rb
```

`name_map.rb --diff` exits non-zero if any derived name disagrees with the
reference, so it can gate a change. `--check` runs the same comparison but
writes nothing and additionally fails when a committed artefact is out of date,
which is the form to run from a build.

`--offline-check` asks the half of that question a machine with no Rust toolchain
can answer: does `name-map.json` still match the names derived from the `.x`
sources? It writes nothing, consults no reference build, and carries the committed
verification block over rather than rebuilding it, since an offline run has nothing
to say about it. `type_map.json` is not checked, because deciding which types the
reference knows is exactly what needs the reference. That makes it the per-pull-request
form; `--check` remains the authority and runs where the pinned CLI is installed.

### The type map is load-bearing

The reference CLI names every type in Rust `UpperCamelCase` derived from the `.x`
identifier, so its spelling differs from this SDK's in three separate ways:
acronym case (`IpAddrType`, `PoolId`, `ContractId`, `NodeId`, `AccountId`,
`TtlEntry`, `ExtendFootprintTtlOp`), the reserved-name escape that renders
`Stellar-overlay.x`'s `struct Error` as `SError`, and the `XDR` suffix this SDK
appends. Guessing one spelling from the other reports resolvable types as
unresolvable, so every tool that addresses the oracle goes through
`type_map.json`.

### Exit codes

`name_map.rb`:

| Code | Meaning |
|---|---|
| 0 | The derived names agree with the reference, and the artefacts are current. |
| 1 | A name disagrees, or a committed artefact is stale. |
| 2 | The reference CLI is missing or does not match the pin. |

Under `--offline-check` the codes mean the same things measured against the `.x`
sources alone: 0 that the committed table matches them, 1 that it does not or is
absent. No reference CLI is consulted, so exit 2 does not arise.

A missing CLI is a separate code because it calls for a different response —
install the pinned build — and a caller that read every non-zero exit as
disagreement would report it as a name mismatch.

`emitted_names.rb` needs no reference CLI. It exits 0 on agreement, 1 on any
mismatch, and 2 when the generated Swift carries no XDR-JSON emission at all,
which is a prerequisite failure rather than several hundred missing names.

### Advisory mode

`--advisory` answers a different question: *if we adopted this other build, would our
output change?* It accepts whatever `STELLAR_XDR` names instead of enforcing the pin,
reports the build it actually used, writes nothing, and leaves the pinned gates untouched.
Exit 0 means every derived name matches that build, so a pin bump would be routine; exit 1
enumerates the names that differ. A missing or unrunnable binary is still exit 2.

## Why `emitted_names.rb` exists

`name_map.rb` and `emitted_names.rb` check different things, and neither
substitutes for the other.

`name_map.rb` answers "are the derivation rules right?" It calls
`tools/xdr-generator/generator/json_names.rb` — the same module the generator
calls — and compares the result with the reference, member by member. But it
calls that module *its own way*, over its own walk of the `.x` sources. It
therefore cannot see how the generator invokes it. By construction it stays green
when the rules are right and the generator uses them wrongly.

`emitted_names.rb` answers the other half: "did those names reach the code?" It
parses the committed Swift and diffs what is actually written there against the
table. The failure modes it is the only guard against:

- an emitter fed the generator's own Swift case names rather than the `.x`
  identifiers. `xdr/Stellar-overlay.x` declares `IPv4` and `IPv6`; the generated
  `IPAddrTypeXDR` declares `case pv4` and `case pv6`, because the generator's
  camel-casing stripped the leading `IP`; the SEP-0051 wire strings are `i_pv4`
  and `i_pv6`. Emitting `pv4` would round-trip against itself perfectly and no
  round-trip test would see it;
- an enum member derived against the wrong sibling list, so the shared prefix is
  computed from the wrong set and every member of that enum is stripped wrongly;
- a key emitted under the wrong field, or a field emitted twice, or one dropped;
- struct keys emitted in an order other than `.x` declaration order, which is a
  wire-format change even though the key set is unchanged — so struct keys are
  compared as an ordered list, not a set;
- a type-level override that stopped being applied, leaving a type that should
  render as a single string emitting an object instead.

Enum members are matched by discriminant rather than by name, because the Swift
case name is the generator's own rendering and cannot be matched back to the `.x`
identifier from the emitted file alone.

It never writes. Run it after `make xdr-generate`.

## What the diff proves, and what it does not

The check is exhaustive over two surfaces:

- **Enum members.** Each member is probed individually by decoding its own
  four-byte value. Batched stream input is not used: a stream stops at the first
  value the CLI does not know and silently truncates, which would turn an unknown
  member into a false pass.
- **Struct field names.** Compared as sets against the reference's JSON schema.
  The reference orders schema properties alphabetically, so this is evidence
  about field *names* only and says nothing about emission order. Emission order
  is declaration order, and `decode` output is the authority there.

Seven structs are rendered by SEP-0051 as a single JSON string rather than an
object: the four integer-parts types, plus `MuxedEd25519Account` and the two
nested structs `med25519` and `ed25519SignedPayload`, which this SDK generates as
`MuxedAccountMed25519XDR` and `Ed25519SignedPayload`. They carry no field names,
so the field diff does not apply; `name_map.rb` classifies them separately and
asserts the set is exactly the expected one. A struct entering or leaving that
set is reported as a mismatch, because it means a type's wire form changed. A
type the reference cannot resolve is exempt from the leaving check — it is
reported once, as unresolvable, since an absent type is no evidence about its
rendering.

Union arm keys are derived rather than probed. An arm keyed by an enum member is
by construction the member's own JSON name, so the enum diff already covers it.

Typedefs carry no JSON names of their own and take no part in the diff. They are
recorded in `name-map.json` because the Swift form decides where their JSON codec
can live: a typedef the language collapses to a `typealias` shares its Swift type
with every other typedef collapsing to the same target, and those targets have
different JSON renderings.

## When to re-run

Re-run `ruby name_map.rb --diff` after either pin moves:

- **XDR pin** (`Makefile`'s `XDR_COMMIT`) — new enum members or types can
  introduce identifier shapes the rules handle differently from the reference.
- **Reference pin** (`oracle-pin.json`) — a reference release can change key
  spellings, as the `type_` to `type` fix in 28.0.0 did.

Two identifier shapes have no agreed JSON name and make `name_map.rb` raise
rather than guess: a member identifier equal to its enum's shared prefix, which
leaves an empty name, and a member whose stripped remainder is exactly `Error`,
which the reference escapes. Neither occurs in the current `.x` set.

The reference CLI vendors a different XDR commit than the SDK generates from, so
it can lag behind on newly added types. At the current pins it resolves
everything; when it does not, the affected members and types are reported as
unresolvable rather than as mismatches.
