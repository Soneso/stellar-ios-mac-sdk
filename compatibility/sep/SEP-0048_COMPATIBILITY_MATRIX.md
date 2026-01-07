# SEP-0048 (Contract Interface Specification) Compatibility Matrix

**Generated:** 2026-01-07

**SDK Version:** 3.4.2

**SEP Version:** 1.1.0

**SEP Status:** Active

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0048.md

## SEP Summary

A standard for contracts to self-describe their exported interface.

## Overall Coverage

**Total Coverage:** 100.0% (31/31 fields)

- ✅ **Implemented:** 31/31
- ❌ **Not Implemented:** 0/31

**Required Fields:** 100.0% (31/31)

**Optional Fields:** 100.0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/soroban/SorobanContractParser.swift`
- `stellarsdk/stellarsdk/responses/xdr/ContractSpecXDR.swift`
- `stellarsdk/stellarsdk/soroban/contract/ContractSpec.swift`

### Key Classes

- **`SorobanContractParser`**: Parses Soroban contract bytecode to extract Environment Meta, Contract Spec, and Contract Meta from Wasm custom sections
- **`SorobanContractInfo`**: Stores parsed contract information including envInterfaceVersion, specEntries, metaEntries, and categorized access via funcs, udtStructs, udtUnions, udtEnums, udtErrorEnums, events properties
- **`SorobanContractParserError`**: Error enum for contract parsing failures (invalidByteCode, environmentMetaNotFound, specEntriesNotFound)
- **`ContractSpec`**: Utility class for working with contract specifications (funcs(), udtStructs(), udtUnions(), udtEnums(), udtErrorEnums(), events(), getFunc(), getEvent(), findEntry(), nativeToXdrSCVal())
- **`ContractSpecError`**: Error enum for contract spec operations
- **`SCSpecEntryXDR`**: XDR type for contract specification entries (functionV0, structV0, unionV0, enumV0, errorEnumV0, eventV0)
- **`SCSpecTypeDefXDR`**: XDR type for type definitions supporting all primitive and compound types
- **`SCSpecFunctionV0XDR`**: XDR type for function specifications with name, inputs, and outputs
- **`SCSpecUDTStructV0XDR`**: XDR type for user-defined struct specifications
- **`SCSpecUDTUnionV0XDR`**: XDR type for user-defined union specifications
- **`SCSpecUDTEnumV0XDR`**: XDR type for user-defined enum specifications
- **`SCSpecUDTErrorEnumV0XDR`**: XDR type for user-defined error enum specifications
- **`SCSpecEventV0XDR`**: XDR type for event specifications

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Wasm Custom Sections | 100.0% | 100.0% | 4 | 4 |
| Entry Types | 100.0% | 100.0% | 6 | 6 |
| Type System - Primitive Types | 100.0% | 100.0% | 6 | 6 |
| Type System - Compound Types | 100.0% | 100.0% | 7 | 7 |
| Parsing Support | 100.0% | 100.0% | 4 | 4 |
| XDR Support | 100.0% | 100.0% | 4 | 4 |

## Detailed Field Comparison

### Wasm Custom Sections

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `contractspecv0_section` | ✓ | ✅ | `parseContractSpec` | Support for "contractspecv0" Wasm custom section for contract specifications |
| `contractenvmetav0_section` | ✓ | ✅ | `parseEnvironmentMeta` | Support for "contractenvmetav0" Wasm custom section for environment metadata |
| `contractmetav0_section` | ✓ | ✅ | `parseMeta` | Support for "contractmetav0" Wasm custom section for contract metadata |
| `xdr_binary_encoding` | ✓ | ✅ | `XDRDecoder` | Parse XDR binary encoded specification entries |

### Entry Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `function_specs` | ✓ | ✅ | `SCSpecFunctionV0XDR` | Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0) |
| `struct_specs` | ✓ | ✅ | `SCSpecUDTStructV0XDR` | Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0) |
| `union_specs` | ✓ | ✅ | `SCSpecUDTUnionV0XDR` | Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0) |
| `enum_specs` | ✓ | ✅ | `SCSpecUDTEnumV0XDR` | Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0) |
| `error_enum_specs` | ✓ | ✅ | `SCSpecUDTErrorEnumV0XDR` | Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0) |
| `event_specs` | ✓ | ✅ | `SCSpecEventV0XDR` | Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0) |

### Type System - Primitive Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `numeric_types` | ✓ | ✅ | `SCSpecType` | Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256) |
| `boolean_type` | ✓ | ✅ | `SCSpecType.bool` | Support for boolean type (SC_SPEC_TYPE_BOOL) |
| `void_type` | ✓ | ✅ | `SCSpecType.void` | Support for void type (SC_SPEC_TYPE_VOID) |
| `bytes_string_symbol` | ✓ | ✅ | `SCSpecType` | Support for bytes, string, and symbol types |
| `address_type` | ✓ | ✅ | `SCSpecType.address` | Support for address type (SC_SPEC_TYPE_ADDRESS) |
| `timepoint_duration` | ✓ | ✅ | `SCSpecType` | Support for timepoint and duration types |

### Type System - Compound Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `option_type` | ✓ | ✅ | `SCSpecTypeOptionXDR` | Support for Option<T> type (SC_SPEC_TYPE_OPTION) |
| `result_type` | ✓ | ✅ | `SCSpecTypeResultXDR` | Support for Result<T, E> type (SC_SPEC_TYPE_RESULT) |
| `vector_type` | ✓ | ✅ | `SCSpecTypeVecXDR` | Support for Vec<T> type (SC_SPEC_TYPE_VEC) |
| `map_type` | ✓ | ✅ | `SCSpecTypeMapXDR` | Support for Map<K, V> type (SC_SPEC_TYPE_MAP) |
| `tuple_type` | ✓ | ✅ | `SCSpecTypeTupleXDR` | Support for tuple types (SC_SPEC_TYPE_TUPLE) |
| `bytes_n_type` | ✓ | ✅ | `SCSpecTypeBytesNXDR` | Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N) |
| `user_defined_type` | ✓ | ✅ | `SCSpecTypeUDTXDR` | Support for user-defined types (SC_SPEC_TYPE_UDT) |

### Parsing Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `parse_contract_bytecode` | ✓ | ✅ | `parseContractByteCode` | Parse contract specifications from Wasm bytecode |
| `parse_environment_meta` | ✓ | ✅ | `parseEnvironmentMeta` | Parse environment metadata for interface version |
| `parse_contract_meta` | ✓ | ✅ | `parseMeta` | Parse contract metadata key-value pairs |
| `extract_spec_entries` | ✓ | ✅ | `parseContractSpec` | Extract and decode all specification entries from Wasm bytecode |

### XDR Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `decode_scspecentry` | ✓ | ✅ | `SCSpecEntryXDR` | Decode SCSpecEntry XDR structures |
| `decode_scspectypedef` | ✓ | ✅ | `SCSpecTypeDefXDR` | Decode SCSpecTypeDef XDR structures for type definitions |
| `decode_scenvmetaentry` | ✓ | ✅ | `SCEnvMetaEntryXDR` | Decode SCEnvMetaEntry XDR structures |
| `decode_scmetaentry` | ✓ | ✅ | `SCMetaEntryXDR` | Decode SCMetaEntry XDR structures |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional