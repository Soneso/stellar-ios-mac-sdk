# XDR Code Generator

Generates Swift XDR types from Stellar's `.x` definition files using the [xdrgen](https://github.com/stellar/xdrgen) Ruby gem.

## Prerequisites

- Ruby 3.x
- Bundler (`gem install bundler`)

## Setup

```bash
cd xdr-generator
bundle install --path vendor/bundle
```

## Usage

### Generate XDR files

```bash
cd xdr-generator
bundle exec ruby generate.rb
```

Output goes to `stellarsdk/stellarsdk/responses/xdr/`. Files for types listed in `SKIP_TYPES` (hand-maintained SDK types) are not generated.

### Update XDR definitions

To update to a new version of the Stellar XDR spec:

1. Replace the `.x` files in `xdr/` with the new versions from [stellar/stellar-xdr](https://github.com/stellar/stellar-xdr)
2. Run the generator: `bundle exec ruby generate.rb`
3. Build and test: `swift build && swift test --filter stellarsdkUnitTests`
4. If new types introduce naming conflicts, update the override files (see below)

### Run tests

```bash
cd xdr-generator
bundle exec ruby test/generator_snapshot_test.rb
```

To update snapshots after intentional generator changes:

```bash
bundle exec ruby test/update_snapshots.rb
```

## Generator architecture

| File | Purpose |
|---|---|
| `generate.rb` | Entry point |
| `generator/generator.rb` | Core Swift renderer (structs, enums, unions, typedefs, constants) |
| `generator/name_overrides.rb` | Maps XDR type names to Swift type names |
| `generator/member_overrides.rb` | Maps enum case names and union arm names |
| `generator/field_overrides.rb` | Maps struct property names |
| `generator/type_overrides.rb` | Typedef resolution, extension point handling, mutability, additional SKIP_TYPES |

## SKIP_TYPES

Types in the `SKIP_TYPES` list are excluded from generation. These include:

- Types implemented as NSObject classes (TransactionXDR, OperationXDR, etc.)
- Types with SDK-specific convenience methods that can't be auto-generated
- Struct-with-constants types (OperationType, MemoType, etc.)
- Types with structural differences from the XDR spec (custom decode/encode logic)

The full list is in `generator/generator.rb` and `generator/type_overrides.rb`.
