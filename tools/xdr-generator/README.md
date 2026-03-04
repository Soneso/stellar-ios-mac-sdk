# XDR Code Generator

Generates Swift XDR types from Stellar's `.x` definition files using the [xdrgen](https://github.com/stellar/xdrgen) Ruby gem.

## Prerequisites

- Ruby 3.x
- Bundler (`gem install bundler`)
- Docker (for Makefile targets)

## Setup

```bash
cd tools/xdr-generator
bundle install --path vendor/bundle
```

## Usage

### Generate XDR files

From the repo root using the Makefile:

```bash
make xdr-generate         # fetch .x files and generate Swift types
make xdr-update           # clean generated files, then regenerate
make xdr-clean-generated  # remove only generated Swift files
make xdr-clean-all        # remove generated Swift files and .x definitions
```

Or run the generator directly:

```bash
cd tools/xdr-generator
bundle exec ruby generate.rb
```

Output goes to `stellarsdk/stellarsdk/responses/xdr/`. Types listed in `SKIP_TYPES` (hand-maintained) are not generated.

### Update to a new XDR spec version

1. Update `XDR_COMMIT` in the repo-root `Makefile` to the new [stellar/stellar-xdr](https://github.com/stellar/stellar-xdr) commit
2. Run `make xdr-update`
3. Build and test: `swift build && swift test --filter stellarsdkUnitTests`
4. If new types introduce naming conflicts, update the override files (see below)

### Run tests

```bash
make xdr-generator-test                # run snapshot tests via Docker
make xdr-generator-update-snapshots    # update snapshots after intentional changes
```

Or directly:

```bash
cd tools/xdr-generator
bundle exec ruby test/generator_snapshot_test.rb
bundle exec ruby test/update_snapshots.rb
bundle exec ruby test/validate_generated_types.rb
```

## Generator architecture

| File | Purpose |
|---|---|
| `generate.rb` | Entry point |
| `generator/generator.rb` | Core Swift renderer (structs, enums, unions, typedefs, constants) |
| `generator/name_overrides.rb` | Maps XDR type names to Swift type names |
| `generator/member_overrides.rb` | Maps enum case names and union arm names |
| `generator/field_overrides.rb` | Maps struct property names |
| `generator/type_overrides.rb` | Typedef resolution, extension point handling, mutability |
| `test/generator_snapshot_test.rb` | Snapshot tests comparing generated output to expected files |
| `test/update_snapshots.rb` | Regenerates snapshot files after intentional generator changes |
| `test/validate_generated_types.rb` | Validates generated files against XDR definitions |

## SKIP_TYPES

Types in the `SKIP_TYPES` list are excluded from generation. These include:

- Envelope classes with NSLock-guarded signatures (TransactionV0EnvelopeXDR, TransactionV1EnvelopeXDR, FeeBumpTransactionEnvelopeXDR)
- Transaction types with stored properties not in the XDR wire format (TransactionXDR, TransactionV0XDR, FeeBumpTransactionXDR)
- Types with `[UInt8]` fields where the generator would produce `WrappedData32` (MuxedAccountXDR, MuxedAccountMed25519XDR)
- Types defined outside `responses/xdr/` (PublicKey, OperationType)

The full list is in `generator/generator.rb` and `generator/type_overrides.rb`.
