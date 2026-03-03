# Maps XDR enum/union member names to current Swift case names.
# Only includes members where the mechanical SCREAMING_SNAKE -> camelCase conversion
# does not produce the current Swift name.
#
# Mechanical conversion algorithm:
#   1. Strip the common prefix (enum type prefix, e.g., MEMO_ for MemoType)
#   2. Lowercase first letter
#   3. CamelCase remaining words separated by underscores
#
# Example: MEMO_TEXT with prefix MEMO_ -> text -> "text"
#          SIGNER_KEY_TYPE_ED25519 with prefix SIGNER_KEY_TYPE_ -> ed25519 -> "ed25519"

MEMBER_OVERRIDES = {
  # ===========================================================================
  # ENUM CASE OVERRIDES
  # ===========================================================================

  # MemoType -- struct-with-constants; SDK prefixes all constants with MEMO_TYPE_
  "MemoType" => {
    "MEMO_NONE"   => "MEMO_TYPE_NONE",
    "MEMO_TEXT"   => "MEMO_TYPE_TEXT",
    "MEMO_ID"     => "MEMO_TYPE_ID",
    "MEMO_HASH"   => "MEMO_TYPE_HASH",
    "MEMO_RETURN" => "MEMO_TYPE_RETURN",
  },

  # OperationType -- non-mechanical names for some members
  "OperationType" => {
    "CREATE_ACCOUNT"              => "accountCreated",
    "PATH_PAYMENT_STRICT_RECEIVE" => "pathPayment",
    "EXTEND_FOOTPRINT_TTL"        => "extendFootprintTTL",
  },

  # SignerKeyType -- last member shortened
  "SignerKeyType" => {
    "SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD" => "signedPayload",
  },

  # ClaimPredicateType -- SDK keeps full "claimPredicate" prefix + abbreviated time names
  "ClaimPredicateType" => {
    "CLAIM_PREDICATE_UNCONDITIONAL"         => "claimPredicateUnconditional",
    "CLAIM_PREDICATE_AND"                   => "claimPredicateAnd",
    "CLAIM_PREDICATE_OR"                    => "claimPredicateOr",
    "CLAIM_PREDICATE_NOT"                   => "claimPredicateNot",
    "CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME"  => "claimPredicateBeforeAbsTime",
    "CLAIM_PREDICATE_BEFORE_RELATIVE_TIME"  => "claimPredicateBeforeRelTime",
  },

  # RevokeSponsorshipType -- SDK keeps full prefix, appends "Entry" to SIGNER
  "RevokeSponsorshipType" => {
    "REVOKE_SPONSORSHIP_LEDGER_ENTRY" => "revokeSponsorshipLedgerEntry",
    "REVOKE_SPONSORSHIP_SIGNER"       => "revokeSponsorshipSignerEntry",
  },

  # ClaimableBalanceIDType -- SDK keeps full name with "ID" capitalized
  "ClaimableBalanceIDType" => {
    "CLAIMABLE_BALANCE_ID_TYPE_V0" => "claimableBalanceIDTypeV0",
  },

  # ClaimantType -- SDK keeps full name
  "ClaimantType" => {
    "CLAIMANT_TYPE_V0" => "claimantTypeV0",
  },

  # SCErrorXDR (union) -- arm "contractCode" shortened to "contract"
  "SCErrorXDR" => {
    "contractCode" => "contract",
  },

  # ContractIDPreimageType -- mechanical prefix is too aggressive (strips FROM_)
  "ContractIDPreimageType" => {
    "CONTRACT_ID_PREIMAGE_FROM_ADDRESS" => "fromAddress",
    "CONTRACT_ID_PREIMAGE_FROM_ASSET"   => "fromAsset",
  },

  # LiquidityPoolType -- single-member enum, prefix detection fails
  "LiquidityPoolType" => {
    "LIQUIDITY_POOL_CONSTANT_PRODUCT" => "constantProduct",
  },

  # SCEnvMetaKind -- single-member enum, prefix detection fails
  "SCEnvMetaKind" => {
    "SC_ENV_META_KIND_INTERFACE_VERSION" => "interfaceVersion",
  },

  # SCMetaKind -- single-member enum, prefix detection fails
  "SCMetaKind" => {
    "SC_META_V0" => "v0",
  },

  # SCSpecEntryKind -- SDK strips "udt" prefix from case names
  "SCSpecEntryKind" => {
    "SC_SPEC_ENTRY_UDT_STRUCT_V0"     => "structV0",
    "SC_SPEC_ENTRY_UDT_UNION_V0"      => "unionV0",
    "SC_SPEC_ENTRY_UDT_ENUM_V0"       => "enumV0",
    "SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0" => "errorEnumV0",
    "SC_SPEC_ENTRY_EVENT_V0"          => "entryEventV0",
  },

  # LedgerEntryChangeType -- SDK keeps full prefix, "Restored" shortened to "Restore"
  "LedgerEntryChangeType" => {
    "LEDGER_ENTRY_CREATED"  => "ledgerEntryCreated",
    "LEDGER_ENTRY_UPDATED"  => "ledgerEntryUpdated",
    "LEDGER_ENTRY_REMOVED"  => "ledgerEntryRemoved",
    "LEDGER_ENTRY_STATE"    => "ledgerEntryState",
    "LEDGER_ENTRY_RESTORED" => "ledgerEntryRestore",
  },

  # TransactionEventStage -- SDK drops trailing 's' from afterAllTxs
  "TransactionEventStage" => {
    "TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS" => "afterAllTx",
  },

  # BinaryFuseFilterType -- Swift identifiers can't start with digits
  "BinaryFuseFilterType" => {
    "BINARY_FUSE_FILTER_8_BIT"  => "eightBit",
    "BINARY_FUSE_FILTER_16_BIT" => "sixteenBit",
    "BINARY_FUSE_FILTER_32_BIT" => "thirtyTwoBit",
  },

  # ===========================================================================
  # UNION ARM NAME OVERRIDES
  #
  # Map XDR union arm variable names (camelCased by xdrgen) to SDK case names.
  # ===========================================================================

  "AllowTrustOpAssetXDR" => {
    "assetCode4"  => "alphanum4",
    "assetCode12" => "alphanum12",
  },

  "ClaimPredicateXDR" => {
    "andPredicates" => "claimPredicateAnd",
    "orPredicates"  => "claimPredicateOr",
    "notPredicate"  => "claimPredicateNot",
    "absBefore"     => "claimPredicateBeforeAbsTime",
    "relBefore"     => "claimPredicateBeforeRelTime",
  },

  "PreconditionsXDR" => {
    "timeBounds" => "time",
  },

  "MemoXDR" => {
    "MEMO_TYPE_NONE" => "none",
    "retHash"        => "returnHash",
  },

  "AssetXDR" => {
    "alphaNum4"  => "alphanum4",
    "alphaNum12" => "alphanum12",
  },

  "SignerKeyXDR" => {
    "ed25519SignedPayload" => "signedPayload",
  },

  "ClaimantXDR" => {
    "v0" => "claimantTypeV0",
  },

  "ClaimableBalanceIDXDR" => {
    "v0" => "claimableBalanceIDTypeV0",
  },

  "LedgerKeyXDR" => {
    "trustLine" => "trustline",
  },

  "TransactionMetaXDR" => {
    "v1" => "transactionMetaV1",
    "v2" => "transactionMetaV2",
    "v3" => "transactionMetaV3",
    "v4" => "transactionMetaV4",
  },

  "HashIDPreimageXDR" => {
    "operationID" => "operationId",
    "revokeID"    => "revokeId",
  },

  "ChangeTrustAssetXDR" => {
    "alphaNum4"     => "alphanum4",
    "alphaNum12"    => "alphanum12",
    "liquidityPool" => "poolShare",
  },

  "TrustlineAssetXDR" => {
    "alphaNum4"       => "alphanum4",
    "alphaNum12"      => "alphanum12",
    "liquidityPoolID" => "poolShare",
  },

  "ContractExecutableXDR" => {
    "wasmHash"     => "wasm",
    "stellarAsset" => "token",
  },

  "HostFunctionXDR" => {
    "wasm" => "uploadContractWasm",
  },

  "RevokeSponsorshipOpXDR" => {
    "ledgerKey" => "revokeSponsorshipLedgerEntry",
    "signer"    => "revokeSponsorshipSignerEntry",
  },

  "TransactionExtXDR" => {
    "sorobanData" => "sorobanTransactionData",
  },

  "LedgerEntryDataXDR" => {
    "trustLine" => "trustline",
  },

  "SCAddressXDR" => {
    "accountId"  => "account",
    "contractId" => "contract",
  },

  "SCSpecEntryXDR" => {
    "udtStructV0"    => "structV0",
    "udtUnionV0"     => "unionV0",
    "udtEnumV0"      => "enumV0",
    "udtErrorEnumV0" => "errorEnumV0",
  },

  "SCSpecUDTUnionCaseV0XDR" => {
    "voidCase"  => "voidV0",
    "tupleCase" => "tupleV0",
  },

  # Extension union arm overrides (SDK uses full version names)
  "AccountEntryExtXDR" => {
    "v1" => "accountEntryExtensionV1",
  },

  "AccountEntryExtV1XDR" => {
    "v2" => "accountEntryExtensionV2",
  },

  "AccountEntryExtV2XDR" => {
    "v3" => "accountEntryExtensionV3",
  },

  "TrustlineEntryExtXDR" => {
    "v1" => "trustlineEntryExtensionV1",
  },

  "TrustlineEntryExtV1XDR" => {
    "v2" => "trustlineEntryExtensionV2",
  },

  "ClaimableBalanceEntryExtXDR" => {
    "v1" => "claimableBalanceEntryExtensionV1",
  },

  "LedgerEntryExtXDR" => {
    "v1" => "ledgerEntryExtensionV1",
  },

  "SCValXDR" => {
    "b"        => "bool",
    "str"      => "string",
    "sym"      => "symbol",
    "instance" => "contractInstance",
    "nonceKey" => "ledgerKeyNonce",
  },

  "OperationBodyXDR" => {
    "destination" => "accountMerge",
  },

}.freeze
