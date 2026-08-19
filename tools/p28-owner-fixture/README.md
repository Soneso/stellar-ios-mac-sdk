# P28 owner fixture contract

Owner contract for the CAP-85 (Protocol 28) integration tests of the four Soneso
Stellar SDKs (iOS/macOS, Flutter, PHP, KMP). It holds executable tag entries:
`set_executable(tag, wasm_hash)` writes the persistent tag entry whose value is the
hash of an already uploaded wasm, and `get_executable(tag)` reads it back. Contracts
created from an external reference naming this owner run the wasm behind the tag.
The fixture carries no authorization on purpose; every test account may write tags.

This directory is replicated in each of the four SDK repos, and the built wasm is
committed to each repo's test resources as `p28_owner_fixture.wasm`. A rebuild must
update the source and the wasm in all four repos.

## Building

Requires the Rust toolchain with the `wasm32v1-none` target and stellar-cli 25.2.0
or newer (the soroban-sdk build script refuses a plain cargo build):

```
stellar contract build
```

The wasm lands in `target/wasm32v1-none/release/p28_owner_fixture.wasm`.

## Dependency pin

`soroban-sdk` is pinned to a revision of the rs-soroban-sdk pull request that adds
the CAP-85 guest API (`env.executable_refs()`), because no released soroban-sdk
carries it yet. The pinned revision builds a wasm the released protocol 28 host
accepts; verified end to end on futurenet 2026-08-19.

When rs-soroban-sdk v28 is released: switch the dependency in `Cargo.toml` to the
release, rebuild, and update this directory and the committed wasm in all four
repos. The host interface the contract calls is final, so only the Rust-side API
shape can differ.
