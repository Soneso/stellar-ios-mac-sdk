# Postponed XDR type migrations

Types that remain hand-written due to API-breaking field type changes or SDK-only code that the generator cannot produce.

## MuxedAccountXDR and MuxedAccountMed25519XDR

**Files:**
- `stellarsdk/stellarsdk/responses/xdr/MuxedAccountXDR.swift`
- `stellarsdk/stellarsdk/responses/xdr/MuxedAccountMed25519XDR.swift`

**Problem:** Both types use `[UInt8]` for `uint256` fields (`ed25519`, `sourceAccountEd25519`). The generator produces `WrappedData32` for `uint256`. Switching to `WrappedData32` breaks ~25 call sites across the SDK and tests:

- ~15 construction sites pass `publicKey.bytes` (`[UInt8]`) directly. A convenience overload can bridge these without changes.
- ~10 pattern-match sites destructure `case .ed25519(let bytes)` expecting `[UInt8]`. These would get `WrappedData32` instead and need updating.
- ~15 field-access sites read `.sourceAccountEd25519` as `[UInt8]`. A stored property cannot be shadowed by a computed property in an extension, so these need updating.

Construction is solvable with helper overloads. Pattern matching and field access are not, so those ~25 sites must be changed manually.

**SDK-only code that must stay hand-written regardless:**
- `MuxedAccountMed25519XDRInverted` struct (field decode/encode order is reversed for M-address encoding)
- `toMuxedAccountMed25519XDRInverted()` / `toMuxedAccountMed25519XDR()` conversion methods
- Computed properties: `ed25519AccountId`, `accountId`, `id` on MuxedAccountXDR
- Computed property: `accountId` on MuxedAccountMed25519XDR

**Resolution:** Either update all ~25 call sites to use `WrappedData32`, or add generator support for custom field type overrides (e.g. a MEMBER_TYPE_OVERRIDE that emits `[UInt8]` instead of `WrappedData32` with appropriate conversion in decode/encode).
