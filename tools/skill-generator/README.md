# Skill Generator

Python script that generates the agent-skill API reference file
(`skills/stellar-ios-mac-sdk/references/api_reference.md`) from the SDK's Swift
source.

## What it does

Recursively walks `stellarsdk/stellarsdk/` and extracts every public class,
struct, enum, protocol, actor, and extension into a compact signature-only
markdown reference. The output is consumed by the `stellar-ios-mac-sdk` agent
skill and lets AI coding agents look up method/property signatures without
reading the raw Swift source.

## Prerequisites

- Python 3.9+ (standard library only, no external dependencies). The script uses
  subscripted-builtin type annotations such as `set[str]`, which require 3.9 or
  newer.

## Usage

The script derives all paths from its own location, so it can be run from any
working directory. The repository-root invocation below is just one example:

```bash
python3 tools/skill-generator/generate_api_reference.py
```

Output is written to
`skills/stellar-ios-mac-sdk/references/api_reference.md` (overwriting the
previous generation).

After regenerating, rebuild the skill zip so the bundled archive matches the
new reference content:

```bash
cd skills
rm -f stellar-ios-mac-sdk.zip
cd stellar-ios-mac-sdk && zip -r ../stellar-ios-mac-sdk.zip . -x "*.DS_Store"
```

## When to regenerate

Regenerate whenever the SDK's public API surface changes:

- New SEP implementation added
- New public class, method, or property in any non-XDR / non-SEP source area
- Type moved between directories
- Property renamed, type changed, or signature otherwise modified
- Type deprecated or removed

Stale generation will not break the SDK build, but the agent skill will offer
out-of-date guidance to consumers.

## What gets scanned

- **Scanned source**: a recursive walk of `stellarsdk/stellarsdk/`. SEP
  implementations (e.g. `kyc/`, `toml/`, `web_authentication/`,
  `transfer_server_protocol/`) ARE scanned; there is no `sep/` directory.
- **Excluded directories**: effectively only `xdr` and `Tests`, plus any
  `.xcodeproj` / `.xcassets` bundles. Exclusion is by **basename at any depth**
  (the `SKIP_DIRS` set is matched against a directory's final path component
  wherever it occurs), so the nested `responses/xdr` is also skipped — which is
  intended. This basename match is path-blind and therefore fragile: any future
  directory that happens to be named `xdr` or `Tests` anywhere under the source
  tree would be skipped too.
- **Excluded declarations**: `private`, `fileprivate`, and `internal` types,
  methods, and properties are never emitted.
- **Effectively-public members**: a member is emitted when it carries an
  explicit `public` / `open` modifier, OR when it carries no explicit access
  modifier and its enclosing context makes members public by default. The
  public-by-default contexts are:
  - **Protocol bodies** — all protocol requirements are public-by-default, so
    every requirement of a public/open protocol is emitted.
  - **`public` / `open` extensions** — members with no explicit access inherit
    the extension's access. A member explicitly marked
    `private`/`fileprivate`/`internal` inside such an extension is still
    excluded.

  Bare `extension Foo { ... }` blocks (no access modifier on the extension
  itself) are scanned, and only their explicitly `public` / `open` members are
  emitted.
- **Also captured**: enum cases, type-inferred constants and properties (those
  written without an explicit `: Type` annotation), `final`-prefixed and
  `private(set)` properties, and generic initializers.

## Output format

Each type produces a section like:

```
## class TypeName: ParentType, SomeProtocol
typealias Foo = Bar
static let shared: TypeName
var publicProperty: SomeType { get }
init(arg: Type) throws
func publicMethod(arg: Type) async throws -> ReturnType
```

Enums additionally list their cases first:

```
## enum SomeResult: Sendable
case success(response: SomeResponse)
case failure(error: SomeError)
```

Types are grouped into buckets driven by the source-file path (core, requests,
responses, soroban, crypto, operations, sdk).

## Limitations

This is a regex-based parser, not a Swift compiler frontend. It correctly
handles every pattern present in the current SDK source but is not a general
Swift parser. If a future SDK change uses a declaration shape that the script
does not yet recognize, the affected types silently drop from the output.
After any large API change, sanity-check the regenerated `api_reference.md`
against the actual source (counts and a few spot-checked sections).
