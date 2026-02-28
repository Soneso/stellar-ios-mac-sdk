# Maps generated typedef names to the types the SDK actually uses.
# Applied in type_string() when a typedef resolves to a non-primitive type.
#
# The generator's default behavior for typedefs is to produce a Swift name
# via name(resolved). These overrides replace that name with the type the
# hand-written SDK code expects.

TYPE_OVERRIDES = {
  "AccountIDXDR"                     => "PublicKey",
  "PoolIDXDR"                        => "WrappedData32",
  "DurationXDR"                      => "UInt64",
  "TimePointXDR"                     => "UInt64",
  "SequenceNumberXDR"                => "Int64",
  "ContractIDXDR"                    => "WrappedData32",
  # AssetCode is now mapped to AllowTrustOpAssetXDR via NAME_OVERRIDES
  "LiquidityPoolEntryXDRBodyXDR"     => "LiquidityPoolBodyXDR",
  "ContractEventType"                => "Int32",
  # SponsorshipDescriptor is typedef AccountID* (optional pointer).
  # The hand-written SponsorshipDescriptorXDR wrapper handles per-element
  # optional encode/decode internally, so arrays of it work with standard decode.
  "SponsorshipDescriptorXDR"          => "SponsorshipDescriptorXDR",
  # SCVec is typedef SCVal SCVec<> (variable-length array of SCVal).
  # Map to the raw array type so union arms use [SCValXDR] directly.
  "SCVecXDR"                          => "[SCValXDR]",
  # SCMap is typedef SCMapEntry SCMap<> (variable-length array of SCMapEntry).
  # Map to the raw array type so union arms use [SCMapEntryXDR] directly.
  "SCMapXDR"                          => "[SCMapEntryXDR]",
}.freeze

# Per-field type overrides. When the generator resolves a field's type to
# one value but the SDK expects a different type for that specific field.
#
# Format: "StructName" => { "fieldName" => "OverriddenType" }
FIELD_TYPE_OVERRIDES = {
  "OfferEntryXDR" => {
    "offerID" => "UInt64",
  },
  "LedgerKeyConfigSettingXDR" => {
    "configSettingID" => "Int32",
  },
  # SCMap is typedef SCMapEntry<>. The generated code resolves it as SCMapXDR
  # but the SDK uses [SCMapEntryXDR] directly.
  "SCContractInstanceXDR" => {
    "storage" => "[SCMapEntryXDR]",
  },
}.freeze

# Extension point fields that should be simplified to `let reserved: Int32 = 0`.
# These are struct fields whose XDR type is a void-only extension union.
# The generator detects these by checking the resolved type for a union with
# only a single void arm at discriminant 0.
#
# Format: "StructName" => ["fieldName", ...]
#
# When a field is in this map:
#   - Property: `public let reserved: Int32 = 0` (field name from FIELD_OVERRIDES)
#   - Init: field is omitted from init parameters
#   - Decode: `_ = try container.decode(Int32.self)` (value discarded)
#   - Encode: `try container.encode(reserved)` (always encodes 0)
EXTENSION_POINT_FIELDS = {
  "ClaimableBalanceEntryExtensionV1" => ["reserved"],
  "DataEntryXDR"            => ["reserved"],
  "LedgerEntryExtensionV1"  => ["reserved"],
  "OfferEntryXDR"           => ["reserved"],
  "TrustlineEntryExtensionV2" => ["ext"],
}.freeze

# Struct names that should use `let` instead of `var` for properties.
# This matches the immutability pattern of the original hand-written SDK types.
LET_TYPES = Set.new(%w[
  AccountEntryExtensionV1
  AllowTrustOperationXDR
  Alpha4XDR
  Alpha12XDR
  BeginSponsoringFutureReservesOpXDR
  BumpSequenceOperationXDR
  ChangeTrustOperationXDR
  ClaimantV0XDR
  ClaimClaimableBalanceOpXDR
  ClaimLiquidityAtomXDR
  ClaimOfferAtomV0XDR
  ClaimOfferAtomXDR
  ClaimableBalanceEntryXDR
  ClawbackClaimableBalanceOpXDR
  ClawbackOpXDR
  ConstantProductXDR
  ContractDataEntryXDR
  CreateAccountOperationXDR
  CreateClaimableBalanceOpXDR
  CreatePassiveOfferOperationXDR
  DataEntryXDR
  DecoratedSignatureXDR
  DiagnosticEventXDR
  Ed25519SignedPayload
  ExtendFootprintTTLOpXDR
  InflationPayoutXDR
  LedgerEntryChangesXDR
  LedgerEntryXDR
  LiabilitiesXDR
  LiquidityPoolConstantProductParametersXDR
  LiquidityPoolDepositOpXDR
  LiquidityPoolEntryXDR
  LiquidityPoolWithdrawOpXDR
  ManageDataOperationXDR
  ManageOfferOperationXDR
  OfferEntryXDR
  OperationMetaV2XDR
  OperationMetaXDR
  PathPaymentOperationXDR
  PaymentOperationXDR
  PreconditionsV2XDR
  PriceXDR
  SetOptionsOperationXDR
  SetTrustLineFlagsOpXDR
  SignerXDR
  SimplePaymentResultXDR
  TimeBoundsXDR
  TransactionEventXDR
  TrustlineEntryXDR
  TTLEntryXDR
  LedgerEntryExtensionV1
]).freeze

# Fields that need special property declarations (not standard `var`/`let`).
#
# Format: "StructName" => { "fieldName" => { key: value, ... } }
#   :visibility  - The full declaration prefix (e.g. "public private(set) var")
#   :default     - Default value expression (e.g. "Int64.max")
SPECIAL_FIELDS = {
  "ChangeTrustOperationXDR" => {
    "limit" => { visibility: "public private(set) var", default: "Int64.max" },
  },
}.freeze

# Init parameter name overrides. When the init parameter name differs from
# the property name.
#
# Format: "StructName" => { "propertyName" => "initParamName" }
INIT_PARAM_OVERRIDES = {
  "CreateAccountOperationXDR" => { "startingBalance" => "balance" },
}.freeze

# Init parameter order overrides. When the init parameter order differs from
# the XDR field order.
#
# Format: "StructName" => ["param1", "param2", ...]
# The array lists field names in the desired init parameter order.
INIT_PARAM_ORDER = {
  "SetTrustLineFlagsOpXDR" => %w[accountID asset setFlags clearFlags],
}.freeze

# Init parameter label overrides for typedef array wrappers.
# When the init parameter label differs from the field name.
#
# Format: "StructName" => "initParamLabel"
TYPEDEF_INIT_LABEL = {
  "LedgerEntryChangesXDR" => "LedgerEntryChanges",
}.freeze

# Additional types to add to SKIP_TYPES.
# These types have structural differences too complex for simple overrides.
ADDITIONAL_SKIP_TYPES = %w[
].freeze

# Types that should omit the explicit encode method.
# The original SDK relies on auto-synthesized Codable conformance for these.
# BumpSequenceOperationXDR and ChangeTrustOperationXDR have no explicit encode
# in the original, but they still work because XDRCodable can auto-synthesize.
# However, since we always emit encode for correctness, we just note this here.
OMIT_ENCODE_TYPES = Set.new(%w[
  BumpSequenceOperationXDR
  ChangeTrustOperationXDR
]).freeze
