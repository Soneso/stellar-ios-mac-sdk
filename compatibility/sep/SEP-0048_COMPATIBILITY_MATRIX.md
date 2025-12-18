# SEP-0048 (Contract Interface Specification) Compatibility Matrix

**Generated:** 2025-12-18

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

**Optional Fields:** 0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/soroban/SorobanContractParser.swift` (278 lines)
- `stellarsdk/stellarsdk/responses/xdr/ContractSpecXDR.swift` (835 lines)
- `stellarsdk/stellarsdk/soroban/contract/ContractSpec.swift` (589 lines)
- `stellarsdk/stellarsdk/service/SorobanServer.swift`
- `stellarsdk/stellarsdkTests/soroban/SorobanParserTest.swift` (742 lines)
- `stellarsdk/stellarsdkTests/soroban/ContractSpecTest.swift`

### Key Classes

- **`SorobanContractParser`**: Parses Soroban contract bytecode to extract Environment Meta, Contract Spec, and Contract Meta from Wasm custom sections. Main entry point for parsing contract specifications.
- **`SorobanContractInfo`**: Stores parsed contract information including environment interface version, spec entries, meta entries, and supported SEPs (via SEP-47 integration). Provides convenient categorized access to functions, UDT structs, UDT unions, UDT enums, UDT error enums, and events through dedicated properties (lines 145-270).
- **`SorobanContractParserError`**: Error enum for contract parsing failures
- **`ContractSpec`**: Utility class for working with contract specifications. Provides methods to convert native Swift values to XDR SCVal types based on spec type definitions, retrieve function specs, and work with user-defined types. Includes extraction methods for all entry types (lines 1-589).
- **`ContractSpecError`**: Error enum for contract spec operations with detailed error cases
- **`SCSpecEntryXDR`**: XDR type for contract specification entries (functions, structs, unions, enums, error enums, events)
- **`SCSpecTypeDefXDR`**: XDR type for type definitions
- **`SCSpecFunctionV0XDR`**: XDR type for function specifications
- **`SCSpecFunctionInputV0XDR`**: XDR type for function input parameters
- **`SCSpecUDTStructV0XDR`**: XDR type for struct specifications
- **`SCSpecUDTUnionV0XDR`**: XDR type for union specifications
- **`SCSpecUDTEnumV0XDR`**: XDR type for enum specifications
- **`SCSpecUDTErrorEnumV0XDR`**: XDR type for error enum specifications
- **`SCSpecEventV0XDR`**: XDR type for event specifications
- **`SCSpecTypeOptionXDR`**: XDR type for Option<T> type
- **`SCSpecTypeResultXDR`**: XDR type for Result<T, E> type
- **`SCSpecTypeVecXDR`**: XDR type for Vec<T> type
- **`SCSpecTypeMapXDR`**: XDR type for Map<K, V> type
- **`SCSpecTypeTupleXDR`**: XDR type for tuple types
- **`SCSpecTypeBytesNXDR`**: XDR type for fixed-length bytes
- **`SCSpecTypeUDTXDR`**: XDR type for user-defined types
- **`SCEnvMetaEntryXDR`**: XDR type for environment metadata entries
- **`SCMetaEntryXDR`**: XDR type for contract metadata entries
- **`SCMetaV0XDR`**: XDR type for contract metadata v0

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Entry Types | 100.0% | 100.0% | 6 | 6 |
| Parsing Support | 100.0% | 100.0% | 4 | 4 |
| Type System - Compound Types | 100.0% | 100.0% | 7 | 7 |
| Type System - Primitive Types | 100.0% | 100.0% | 6 | 6 |
| Wasm Custom Section | 100.0% | 100.0% | 4 | 4 |
| XDR Support | 100.0% | 100.0% | 4 | 4 |

## Detailed Field Comparison

### Entry Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enum_specs` | ✓ | ✅ | `SCSpecEntryXDR.enumV0` | Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0) |
| `error_enum_specs` | ✓ | ✅ | `SCSpecEntryXDR.errorEnumV0` | Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0) |
| `event_specs` | ✓ | ✅ | `SCSpecEntryXDR.eventV0` | Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0) |
| `function_specs` | ✓ | ✅ | `SCSpecEntryXDR.functionV0` | Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0) |
| `struct_specs` | ✓ | ✅ | `SCSpecEntryXDR.structV0` | Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0) |
| `union_specs` | ✓ | ✅ | `SCSpecEntryXDR.unionV0` | Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0) |

### Parsing Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `extract_spec_entries` | ✓ | ✅ | `parseContractSpec` | Extract and decode all specification entries from Wasm bytecode |
| `parse_contract_bytecode` | ✓ | ✅ | `parseContractByteCode` | Parse contract specifications from Wasm bytecode (lines 19-48) |
| `parse_contract_meta` | ✓ | ✅ | `parseMeta` | Parse contract metadata key-value pairs (lines 98-131) |
| `parse_environment_meta` | ✓ | ✅ | `parseEnvironmentMeta` | Parse environment metadata for interface version (lines 50-64) |

### Type System - Compound Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `bytes_n_type` | ✓ | ✅ | `SCSpecTypeBytesNXDR` | Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N) |
| `map_type` | ✓ | ✅ | `SCSpecTypeMapXDR` | Support for Map<K, V> type (SC_SPEC_TYPE_MAP) |
| `option_type` | ✓ | ✅ | `SCSpecTypeOptionXDR` | Support for Option<T> type (SC_SPEC_TYPE_OPTION) |
| `result_type` | ✓ | ✅ | `SCSpecTypeResultXDR` | Support for Result<T, E> type (SC_SPEC_TYPE_RESULT) |
| `tuple_type` | ✓ | ✅ | `SCSpecTypeTupleXDR` | Support for tuple types (SC_SPEC_TYPE_TUPLE) |
| `user_defined_type` | ✓ | ✅ | `SCSpecTypeUDTXDR` | Support for user-defined types (SC_SPEC_TYPE_UDT) |
| `vector_type` | ✓ | ✅ | `SCSpecTypeVecXDR` | Support for Vec<T> type (SC_SPEC_TYPE_VEC) |

### Type System - Primitive Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `address_type` | ✓ | ✅ | `SCSpecTypeDefXDR.address` | Support for address type (SC_SPEC_TYPE_ADDRESS) |
| `boolean_type` | ✓ | ✅ | `SCSpecTypeDefXDR.bool` | Support for boolean type (SC_SPEC_TYPE_BOOL) |
| `bytes_string_symbol` | ✓ | ✅ | `SCSpecTypeDefXDR` | Support for bytes, string, and symbol types (.bytes, .string, .symbol) |
| `numeric_types` | ✓ | ✅ | `SCSpecTypeDefXDR` | Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256) |
| `timepoint_duration` | ✓ | ✅ | `SCSpecTypeDefXDR` | Support for timepoint and duration types (.timepoint, .duration) |
| `void_type` | ✓ | ✅ | `SCSpecTypeDefXDR.void` | Support for void type (SC_SPEC_TYPE_VOID) |

### Wasm Custom Section

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `contractenvmetav0_section` | ✓ | ✅ | `parseEnvironmentMeta` | Support for "contractenvmetav0" Wasm custom section for environment metadata |
| `contractmetav0_section` | ✓ | ✅ | `parseMeta` | Support for "contractmetav0" Wasm custom section for contract metadata |
| `contractspecv0_section` | ✓ | ✅ | `parseContractSpec` | Support for "contractspecv0" Wasm custom section (lines 66-96) |
| `xdr_binary_encoding` | ✓ | ✅ | `XDRDecoder` | Parse XDR binary encoded specification entries using XDRDecoder |

### XDR Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `decode_scenvmetaentry` | ✓ | ✅ | `SCEnvMetaEntryXDR` | Decode SCEnvMetaEntry XDR structures |
| `decode_scmetaentry` | ✓ | ✅ | `SCMetaEntryXDR` | Decode SCMetaEntry XDR structures |
| `decode_scspecentry` | ✓ | ✅ | `SCSpecEntryXDR` | Decode SCSpecEntry XDR structures |
| `decode_scspectypedef` | ✓ | ✅ | `SCSpecTypeDefXDR` | Decode SCSpecTypeDef XDR structures for type definitions |

## Implementation Details

### Parsing Contract Bytecode

The iOS SDK provides comprehensive bytecode parsing through the `SorobanContractParser` class:

```swift
import stellarsdk

// Parse contract bytecode
let contractBytes = FileManager.default.contents(atPath: "path/to/contract.wasm")
let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: contractBytes!)

// Access parsed data
let envVersion = contractInfo.envInterfaceVersion
let specEntries = contractInfo.specEntries  // Array of SCSpecEntryXDR
let metaEntries = contractInfo.metaEntries  // Dictionary<String, String>
let supportedSeps = contractInfo.supportedSeps  // SEP-47 integration

// Convenient categorized access (automatically populated)
let functions = contractInfo.funcs  // Array of SCSpecFunctionV0XDR
let structs = contractInfo.udtStructs  // Array of SCSpecUDTStructV0XDR
let unions = contractInfo.udtUnions  // Array of SCSpecUDTUnionV0XDR
let enums = contractInfo.udtEnums  // Array of SCSpecUDTEnumV0XDR
let errorEnums = contractInfo.udtErrorEnums  // Array of SCSpecUDTErrorEnumV0XDR
let events = contractInfo.events  // Array of SCSpecEventV0XDR
```

### Working with Contract Specifications

The `ContractSpec` class provides utilities for working with parsed specifications:

```swift
import stellarsdk

// Create ContractSpec from parsed entries
let spec = ContractSpec(entries: contractInfo.specEntries)

// Get all functions
let functions = spec.funcs()

// Get all UDT structs
let structs = spec.udtStructs()

// Get all UDT unions
let unions = spec.udtUnions()

// Get all UDT enums
let enums = spec.udtEnums()

// Get all UDT error enums
let errorEnums = spec.udtErrorEnums()

// Get all events
let events = spec.events()

// Get specific function
let func = spec.getFunc(name: "transfer")

// Get specific event
let event = spec.getEvent(name: "Transfer")

// Find any entry by name (function, struct, union, enum, error enum, or event)
let entry = spec.findEntry(name: "DataKey")

// Convert native Swift arguments to XDR SCVal
let args = [
  "from": "GABC...",
  "to": "GDEF...",
  "amount": 1000
]
let xdrArgs = try spec.funcArgsToXdrSCValues(name: "transfer", args: args)
```

### Type System Support

The SDK provides complete XDR type system support with 26+ XDR classes covering:

- **Primitive types**: bool, u32, i32, u64, i64, u128, i128, u256, i256, address, bytes, string, symbol, void, timepoint, duration
- **Compound types**: vec, map, tuple, option, result, bytesN
- **User-defined types**: struct, union, enum, error enum
- **Special types**: function inputs, event parameters

### Native to XDR Conversion

The `ContractSpec` class includes production-ready type conversion:

```swift
// Supports all primitive types
try spec.nativeToXdrSCVal(val: true, ty: .bool)
try spec.nativeToXdrSCVal(val: 42, ty: .u32)
try spec.nativeToXdrSCVal(val: "Hello", ty: .string)

// Supports compound types
try spec.nativeToXdrSCVal(val: [1, 2, 3], ty: .vec(elementType))
try spec.nativeToXdrSCVal(val: ["key": "value"], ty: .map(keyType, valueType))

// Supports Data values for big integers
try spec.nativeToXdrSCVal(val: bigIntData, ty: .u128)
try spec.nativeToXdrSCVal(val: "999999999999999999", ty: .u256)

// Supports user-defined types
try spec.nativeToXdrSCVal(val: ["name": "Alice"], ty: .udt(structType))
```

## Integration with Other SEPs

### SEP-46 (Contract Meta)

SEP-48 builds on SEP-46 by parsing metadata from the `contractmetav0` custom section:

```swift
// Meta entries are automatically parsed
let metaEntries = contractInfo.metaEntries

// Example: Get contract version
let version = metaEntries["version"]
```

### SEP-47 (Contract Interface Discovery)

SEP-48 implementation includes full SEP-47 support for discovering which SEPs a contract implements:

```swift
// Supported SEPs are automatically extracted from meta entries
let supportedSeps = contractInfo.supportedSeps

// Example: Check if contract supports SEP-41
if supportedSeps.contains("41") {
  // Contract implements SEP-41 (Token Interface)
}
```

## Testing

The iOS SDK includes comprehensive tests for SEP-48 implementation in `stellarsdk/stellarsdkTests/soroban/SorobanParserTest.swift`:

- **Bytecode parsing tests** (`testParseTokenContract`): Validates complete parsing of Wasm contract bytecode, including all spec entries, meta entries, and environment metadata
- **SorobanContractInfo validation tests** (`testTokenContractValidation`): Validates the automatically populated categorized properties (funcs, udtStructs, udtUnions, udtEnums, udtErrorEnums, events) with comprehensive assertions on counts and content (lines 328-517)
- **ContractSpec method tests** (`testContractSpecMethods`): Validates all extraction methods including `funcs()`, `udtStructs()`, `udtUnions()`, `udtEnums()`, `udtErrorEnums()`, `events()`, `getFunc()`, `getEvent()`, and `findEntry()` with detailed validation of return types and content (lines 519-740)
- **SEP-47 integration tests** (`testSorobanContractInfoSupportedSepsParsing`): Validates parsing of supported SEPs from meta entries with edge cases (lines 288-326)
- **Type system conversion tests**: Tests conversion of native Swift values to XDR SCVal types across all primitive and compound types
- **Function argument conversion tests**: Validates `funcArgsToXdrSCValues()` method with real contract functions
- **User-defined type tests**: Tests struct, union, and enum conversions with proper field validation
- **Error handling tests**: Validates proper exception handling for invalid inputs

## Code Examples

### Example 1: Parse and Inspect Contract

```swift
import stellarsdk

// Parse contract
let wasmBytes = FileManager.default.contents(atPath: "path/to/contract.wasm")
let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: wasmBytes!)

print("Environment Version: \(contractInfo.envInterfaceVersion)")
print("Supported SEPs: \(contractInfo.supportedSeps.joined(separator: ", "))")

// Direct access to categorized entries (automatically populated)
print("Functions: \(contractInfo.funcs.count)")
print("Structs: \(contractInfo.udtStructs.count)")
print("Unions: \(contractInfo.udtUnions.count)")
print("Enums: \(contractInfo.udtEnums.count)")
print("Error Enums: \(contractInfo.udtErrorEnums.count)")
print("Events: \(contractInfo.events.count)")

// Iterate through functions using convenient property
for func in contractInfo.funcs {
  print("Function: \(func.name)")
  for input in func.inputs {
    print("  Input: \(input.name)")
  }
}

// Or use ContractSpec for additional utilities
let spec = ContractSpec(entries: contractInfo.specEntries)
let structs = spec.udtStructs()

for structItem in structs {
  print("Struct: \(structItem.name)")
  for field in structItem.fields {
    print("  Field: \(field.name)")
  }
}
```

### Example 2: Convert Arguments for Contract Call

```swift
import stellarsdk

// Load contract spec
let spec = ContractSpec(entries: contractInfo.specEntries)

// Define native Swift arguments
let args = [
  "token": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
  "amount": 5000,
  "recipient": "GABC123..."
]

// Convert to XDR for contract invocation
let xdrArgs = try spec.funcArgsToXdrSCValues(name: "transfer", args: args)

// Use in contract invocation
// ... invoke contract with xdrArgs
```

### Example 3: Work with User-Defined Types

```swift
import stellarsdk

// Get struct definitions
for entry in spec.entries {
  switch entry {
  case .structV0(let udtStruct):
    print("Struct: \(udtStruct.name)")
    for field in udtStruct.fields {
      print("  Field: \(field.name)")
    }
  default:
    break
  }
}

// Convert struct to XDR
let structData = [
  "name": "Alice",
  "age": 30,
  "active": true
]

// Find the UDT type definition
if let entry = spec.findEntry(name: "User") {
  let typeDef = SCSpecTypeDefXDR.udt(SCSpecTypeUDTXDR(name: "User"))
  let xdrStruct = try spec.nativeToXdrSCVal(val: structData, ty: typeDef)
}
```

### Example 4: Query Events

```swift
import stellarsdk

// Get all events
let events = spec.events()

// Find specific event
if let transferEvent = spec.getEvent(name: "Transfer") {
  print("Event: \(transferEvent.name)")
  print("Prefix Topics: \(transferEvent.prefixTopics)")

  for param in transferEvent.params {
    print("Parameter: \(param.name)")
    print("  Type: \(param.type)")
  }
}
```

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Additional Features

The iOS SDK implementation includes production-ready features beyond the SEP-48 specification:

### SorobanContractInfo Properties
- **Convenient Access**: Direct properties for categorized spec entries - `funcs`, `udtStructs`, `udtUnions`, `udtEnums`, `udtErrorEnums`, `events` (lines 157-179)
- **SEP-47 Integration**: Automatic parsing of supported SEPs from meta entries via `supportedSeps` property (lines 153-209)
- **Type Safety**: All properties return strongly-typed Swift arrays of specific XDR types

### ContractSpec Helper Methods
- **Function Query**: `funcs()`, `getFunc(name:)` - Query contract functions (lines 27-57)
- **Event Query**: `events()`, `getEvent(name:)` - Query contract events (lines 59-91)
- **UDT Query**: `udtStructs()`, `udtUnions()`, `udtEnums()`, `udtErrorEnums()` - Query user-defined types (lines 93-159)
- **Universal Search**: `findEntry(name:)` - Find any entry by name across all types (lines 161-194)
- **Argument Conversion**: `funcArgsToXdrSCValues(name:args:)` - Convert native Swift values to XDR for contract invocation (lines 196-219)
- **Type Conversion**: `nativeToXdrSCVal(val:ty:)` - Comprehensive type conversion from Swift to XDR (lines 221-577)
- **Error Handling**: `ContractSpecError` enum with detailed error cases (lines 580-588)

### Type Conversion Support
- Native Swift types to XDR: Int, String, Bool, Data, Array, Dictionary
- Struct handling: Named fields (dictionary) and positional fields (array)
- Union handling: Void and tuple variants with proper validation
- Enum validation: Value checking against specification
- Complex nested type support

### Documentation
- Comprehensive documentation in `docs/soroban.md` (lines 1214-1262)
- Example code for parsing contract bytecode
- Type conversion examples
- Integration with SorobanServer for contract deployment and invocation

### Testing
- **SorobanParserTest.swift**: Comprehensive tests for parsing contract bytecode (742 lines)
- **ContractSpecTest.swift**: Tests for contract spec operations (21,220 bytes)
- Coverage of all entry types and type conversions
- Error handling validation
- SEP-47 integration testing

## Recommendations

✅ The SDK has full compatibility with SEP-48!

### Strengths
1. **Complete XDR Support**: All 26 XDR types from ContractSpecXDR.swift are fully implemented
2. **Production-Ready**: 589 lines of helper code in ContractSpec.swift for practical usage
3. **Type Safety**: Strong Swift typing with comprehensive error handling
4. **Convenient Access**: SorobanContractInfo provides direct categorized access to all spec entry types through dedicated properties
5. **Comprehensive Extraction**: ContractSpec offers methods for extracting all entry types - functions, structs, unions, enums, error enums, and events
6. **SEP-47 Integration**: Automatic parsing and exposure of supported SEPs through `supportedSeps` property
7. **Well-Tested**: Comprehensive test coverage with 742 lines of tests including validation of all new categorized properties and extraction methods
8. **Well-Documented**: Extensive documentation with code examples for all major features

### Best Practices
- The implementation follows the Stellar SDK best practices
- Uses native Swift idioms and patterns
- Provides clear error messages for debugging
- Includes comprehensive test coverage with specific test cases for:
  - Token contract validation (`testTokenContractValidation`)
  - ContractSpec method validation (`testContractSpecMethods`)
  - SEP-47 integration (`testSorobanContractInfoSupportedSepsParsing`)
- All categorized properties are automatically populated during initialization
- Type-safe access to all spec entry types

### Recent Enhancements (2025-10-16)

The following features were added to enhance the SEP-48 implementation:

#### SorobanContractInfo Properties (lines 157-179 in SorobanContractParser.swift)
- `funcs: [SCSpecFunctionV0XDR]` - Contract functions
- `udtStructs: [SCSpecUDTStructV0XDR]` - User-defined type structs
- `udtUnions: [SCSpecUDTUnionV0XDR]` - User-defined type unions
- `udtEnums: [SCSpecUDTEnumV0XDR]` - User-defined type enums
- `udtErrorEnums: [SCSpecUDTErrorEnumV0XDR]` - User-defined type error enums
- `events: [SCSpecEventV0XDR]` - Event specifications

#### ContractSpec Methods (ContractSpec.swift)
- `funcs() -> [SCSpecFunctionV0XDR]` - Get all functions (lines 27-40)
- `udtStructs() -> [SCSpecUDTStructV0XDR]` - Get all UDT structs (lines 93-108)
- `udtUnions() -> [SCSpecUDTUnionV0XDR]` - Get all UDT unions (lines 110-125)
- `udtEnums() -> [SCSpecUDTEnumV0XDR]` - Get all UDT enums (lines 127-142)
- `udtErrorEnums() -> [SCSpecUDTErrorEnumV0XDR]` - Get all UDT error enums (lines 144-159)
- `events() -> [SCSpecEventV0XDR]` - Get all events (lines 59-74)
- `getEvent(name:) -> SCSpecEventV0XDR?` - Get specific event by name (lines 76-91)

#### Test Coverage
- `testTokenContractValidation()` - Validates SorobanContractInfo categorized properties (lines 328-517)
- `testContractSpecMethods()` - Validates all ContractSpec extraction methods (lines 519-740)
- Both tests use a real Soroban token contract (soroban_token_contract.wasm) with:
  - 13 functions
  - 3 UDT structs
  - 1 UDT union
  - 0 UDT enums
  - 0 UDT error enums
  - 8 events

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

---

**Report Generated:** 2025-12-18

**SDK Version:** 3.4.1

**Analysis Tool:** SEP Compatibility Matrix Generator v2.0
