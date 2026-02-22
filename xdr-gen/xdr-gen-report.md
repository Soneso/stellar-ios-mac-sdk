# XDR Code Generation: Cross-SDK Analysis Report

## Overview

This report analyzes how the KMP, Python, and Java Stellar SDKs use automated XDR code generation, and assesses what it would take to implement similar functionality in the iOS/macOS Stellar SDK.

---

## How the Other SDKs Do It

All three SDKs (KMP, Python, Java) use the same core pipeline:

1. **Stellar's `xdrgen`** - A Ruby-based meta-compiler from `github.com/stellar/xdrgen`
2. **Custom language generator** - A Ruby class extending `Xdrgen::Generators::Base` that outputs language-specific code
3. **XDR `.x` files** fetched from `github.com/stellar/stellar-xdr` at a pinned commit hash
4. **Docker execution** (Python/Java) or direct Ruby (KMP) to run the generator
5. **Generated files committed** to the repo (not generated at build time)

### Comparison Table

| Aspect | Java | Python | KMP |
|--------|------|--------|-----|
| Generator file | `generator.rb` (761 lines) | `generator.rb` (790 lines) | `kotlin.rb` (1,027 lines) |
| Output files | ~300 Java classes | ~468 Python modules | 424 Kotlin files |
| XDR commit pinned | Yes (Makefile) | Yes (Makefile) | Manual (copy .x files) |
| Trigger | `make xdr-update` | `make xdr-update` | `./generate.rb` |
| Post-processing | Spotless formatter | black/isort/autoflake | None |
| Helper separation | Clean - helpers in separate SDK classes | Clean - no hand-written code in `xdr/` | Clean - extensions in separate files |
| Excluded .x files | None | None | exporter, internal, overlay |
| Snapshot tests | No | Yes (Minitest) | No |
| Execution | Docker (Ruby 3.4) | Docker (Ruby 3.4) | Direct Ruby |

### Common Architecture

All three generators share the same xdrgen framework and produce:

- **One file per XDR type** (struct, enum, union, typedef)
- **Constants file** collecting all XDR constants
- **Utility/infrastructure classes** (reader/writer, primitives)
- **encode/decode methods** on every type
- **Base64 conversion helpers** (fromXdrBase64, toXdrBase64)

Key design principle: Generated XDR files are pure serialization types with zero business logic. All convenience methods, builders, signing, etc. live in separate, hand-written files.

---

## Python SDK: Reference Implementation

The Python SDK is the most mature reference for this work.

### Generation Pipeline

```
make xdr-update
  |-- make xdr-clean          # Removes previous xdr/ and stellar_sdk/xdr/*.py
  |-- make xdr-generate
      |-- Fetch .x files      # Download from stellar-xdr repo via curl
      |-- Replace keywords    # Sed replaces Python reserved words (from -> from_)
      |-- Docker Ruby build   # Run xdrgen with custom generator
      |-- Update docs         # Generate XDR API documentation
      |-- Pre-commit hooks    # Run formatting/linting
```

### Docker Execution

```bash
docker run -it --rm -v $(PWD):/wd -w /wd ruby:3.4 /bin/bash -c '
  cd xdr-generator &&
  bundle install --quiet &&
  bundle exec ruby generate.rb'
```

### Generator Structure (generator.rb, 790 lines)

- Main class: `Generator < Xdrgen::Generators::Base`
- Methods for each XDR type: `render_struct`, `render_enum`, `render_union`, `render_typedef`, `render_const`
- All pack/unpack methods are procedurally generated based on XDR type structure
- Template-based base classes for primitives (`base.py`)

### Generated Code Features

Every generated class includes:
- `pack(packer)` / `unpack(unpacker)` - XDR binary serialization
- `to_xdr_bytes()` / `from_xdr_bytes()` - convenience byte conversion
- `to_xdr()` / `from_xdr()` - Base64 string conversion
- `__hash__()`, `__eq__()`, `__repr__()` - standard Python methods
- Array length and string size validation
- DoS prevention via buffer boundary checking

### Snapshot Testing

- Location: `/xdr-generator/test/`
- Framework: Minitest (Ruby)
- Test fixtures in `/test/fixtures/xdrgen/`
- Expected output snapshots in `/test/snapshots/`
- CI workflow: `.github/workflows/xdr-generator-snapshot-test.yml`
- Update mode: `UPDATE_SNAPSHOTS=1 make xdr-generator-update-snapshots`

---

## Java SDK: Generation Details

### Generator (generator.rb, 761 lines)

- Uses ERB templates for utility classes (XdrDataInputStream, XdrDataOutputStream, XdrElement, XdrString, XdrUnsignedInteger, XdrUnsignedHyperInteger)
- Lombok annotations (@Data, @NoArgsConstructor, @AllArgsConstructor, @Builder)
- Depth limiting (DEFAULT_MAX_DEPTH = 200) to prevent stack overflow
- Size validation before memory allocation (DoS prevention)
- Nested unions generate as static inner classes
- Code coverage explicitly excludes `org.stellar.sdk.xdr/**`

### Helper Separation

- XDR classes: pure serialization in `org.stellar.sdk.xdr`
- SDK classes: builders, validators, helpers in `org.stellar.sdk`
- No hand-written code in the XDR package

---

## KMP SDK: Generation Details

### Generator (kotlin.rb, 1,027 lines)

- Typedefs: `@kotlin.jvm.JvmInline value class XxxXdr(val value: InnerType)`
- Enums: `enum class XxxXdr(val value: Int)`
- Structs: `data class XxxXdr(val field1: Type1, ...)`
- Unions: `sealed class XxxXdr` with data class subclasses per arm
- Uses `expect/actual` pattern for platform-specific XdrReader/XdrWriter
- Extensions in separate `XdrExtensions.kt` file

### Excluded XDR Files

- `Stellar-exporter.x` - batch export format
- `Stellar-internal.x` - core internal storage types
- `Stellar-overlay.x` - network protocol messages

---

## Current iOS SDK State

| Aspect | Value |
|--------|-------|
| XDR files | 107 manually maintained Swift files |
| Total size | ~652 KB |
| Location | `stellarsdk/responses/xdr/` |
| Infrastructure | `XDRCodable` protocol (builds on Swift `Codable`) |
| Code generation | None - everything is hand-written |

### Infrastructure Files

- `utils/xdrCodable/XDRCodable.swift` - Protocol definition
- `utils/xdrCodable/XDREncoder.swift` - Binary encoder
- `utils/xdrCodable/XDRDecoder.swift` - Binary decoder
- `utils/xdrCodable/XDRCodableExtensions.swift` - Array/optional helpers
- `utils/DataTypes.swift` - WrappedData32, WrappedData4, WrappedData12

### XDR Type Patterns Used

1. **Structs** - Swift `struct` with `XDRCodable, Sendable` conformance
2. **Enums (discriminants)** - Swift `enum` with `Int32` raw values
3. **Unions** - Swift `enum` with associated values
4. **Optionals** - Encoded as 0-or-1 element arrays
5. **Recursive types** - `indirect enum`
6. **Extension chains** - Union with `.void` case for forward compatibility

### The Core Problem

Helper/convenience methods are mixed directly into the XDR type files:

- Convenience initializers (e.g., `init(assetCode:issuer:)`)
- Computed properties (e.g., `var assetCode: String`)
- Signing methods (e.g., `sign(keyPair:network:)`)
- Envelope methods (e.g., `toEnvelopeXDR()`, `encodedEnvelope()`)
- Base64 conversion (e.g., `init(fromBase64:)`)

Example: `AssetXDR.swift` contains both pure XDR encode/decode AND business logic like asset code parsing and KeyPair-based initialization.

`TransactionXDR.swift` is the worst offender at 30K+ lines with signing, envelope creation, and other business logic deeply intertwined with XDR definitions.

---

## Implementation Plan

### Phase 1: Build Infrastructure

Create `tools/xdrgen-swift/` with:
- `Gemfile` - xdrgen dependency
- `generate.rb` - Entry point script
- `generator/generator.rb` - Custom Swift generator (~800-1000 lines Ruby)
- `generator/templates/` - ERB templates for infrastructure classes
- `Makefile` at repo root with `xdr-update`, `xdr-clean`, `xdr-generate` targets

### Phase 2: Write Swift Generator

The generator must handle Swift-specific patterns:
- `struct` for XDR structs, conforming to `XDRCodable, Sendable`
- `enum` with associated values for XDR unions
- `enum` with `Int32` raw values for XDR enums
- `indirect enum` for recursive types
- Optional encoding via the existing array-based pattern
- Fixed/variable array length validation
- `unkeyedContainer`-based Codable encoding (matching existing infrastructure)

### Phase 3: Extract Helper Methods

Audit all 107 files and move helpers to separate extension files:
- Create `xdr+Extensions/` directory for hand-maintained extensions
- Move convenience initializers, computed properties, signing methods
- Verify nothing breaks via unit test comparison

Estimated scope: ~40-50 files contain helpers needing extraction.

### Phase 4: Generate and Validate

1. Pin XDR commit hash in Makefile
2. Run generator to produce new files in `responses/xdr/`
3. XDR round-trip comparison tests (old manual vs. new generated)
4. Remove old hand-maintained XDR files

### Phase 5: Snapshot Testing

Add Ruby snapshot tests (following Python SDK pattern) to catch generator regressions.

---

## Effort and Risk Assessment

| Component | Effort | Risk |
|-----------|--------|------|
| Swift generator (Ruby) | Medium-high (~1000 lines Ruby) | Low - proven architecture from 3 existing generators |
| Helper extraction | High - audit 107 files, move to extensions | Medium - easy to miss a helper or break an import |
| Testing/validation | Medium - XDR round-trip comparison | Low |
| Build infrastructure | Low - Makefile + Docker, copy from Python/Java | Low |
| Snapshot tests | Low - follow Python pattern | Low |

### Biggest Risk

Phase 3 (helper extraction). `TransactionXDR.swift` alone is 30K+ lines with signing, envelope creation, and business logic intertwined with XDR definitions. Careful, incremental extraction with test coverage is essential.

### Biggest Payoff

Protocol updates go from "manually write hundreds of lines of boilerplate Swift" to "bump a commit hash and run a command."
