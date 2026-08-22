# Maps generated struct field names to the current SDK property names.
#
# The generator derives field names mechanically from the XDR .x definitions
# using camelCase conversion. This map records cases where the SDK uses a
# different property name than the mechanical conversion produces.
#
# Format:
#   "SwiftTypeName" => {
#     "generatedFieldName" => "sdkFieldName",
#   }
#
# Categories of overrides:
#   1. Abbreviated XDR names expanded in SDK (e.g. destAsset -> destinationAsset)
#   2. XDR extension fields renamed to "reserved" in SDK
#   3. Casing differences (e.g. sponsoredID -> sponsoredId)
#   4. Semantic renames (e.g. line -> asset, contractID -> hash)
#   5. Underscore-separated XDR names that SDK uses camelCase for (hi_hi -> hiHi)
#   6. Typedef array wrapper field "wrapped" renamed in SDK

FIELD_OVERRIDES = {
  # --- Stellar-transaction.x ---

  # XDR: BeginSponsoringFutureReservesOp.sponsoredID
  # SDK uses lowercase "Id" instead of uppercase "ID"
  "BeginSponsoringFutureReservesOpXDR" => {
    "sponsoredID" => "sponsoredId",
  },

  # XDR: ChangeTrustOp.line (the asset to trust)
  # SDK renames "line" to "asset" for clarity
  "ChangeTrustOperationXDR" => {
    "line" => "asset",
  },

  # XDR: ClaimOfferAtomV0.offerID
  # SDK uses lowercase "Id"
  "ClaimOfferAtomV0XDR" => {
    "offerID" => "offerId",
  },

  # XDR: ClaimOfferAtom.sellerID, offerID
  # SDK uses lowercase "Id"
  "ClaimOfferAtomXDR" => {
    "sellerID" => "sellerId",
    "offerID" => "offerId",
  },

  # XDR: ClaimantV0.destination
  # SDK renames to "accountID"
  "ClaimantV0XDR" => {
    "destination" => "accountID",
  },

  # XDR: ClaimableBalanceEntryXDR.balanceID
  # SDK renames to "claimableBalanceID" for clarity
  "ClaimableBalanceEntryXDR" => {
    "balanceID" => "claimableBalanceID",
  },

  # XDR: ClaimableBalanceEntryExtensionV1.ext (extension point)
  # SDK renames extension fields to "reserved"
  "ClaimableBalanceEntryExtensionV1" => {
    "ext" => "reserved",
  },

  # XDR: ClawbackClaimableBalanceOp.balanceID
  # SDK renames to "claimableBalanceID" for clarity
  "ClawbackClaimableBalanceOpXDR" => {
    "balanceID" => "claimableBalanceID",
  },

  # XDR: ContractCostParams is a typedef for ContractCostParamEntry<>
  # Generator wraps in struct with "wrapped" field; SDK uses "entries"
  "ContractCostParamsXDR" => {
    "wrapped" => "entries",
  },

  # XDR: ContractEvent.contractID (optional Hash)
  # SDK renames to "hash"
  "ContractEventXDR" => {
    "contractID" => "hash",
  },

  # XDR: ContractExecutableExternalRef uses underscore-separated field names
  # SDK uses camelCase
  "ContractExecutableExternalRefXDR" => {
    "executable_owner" => "executableOwner",
  },

  # --- Stellar-ledger-entries.x ---

  # XDR: AccountEntryExtensionV1.ext (extension union)
  # SDK renames extension fields to "reserved"
  "AccountEntryExtensionV1" => {
    "ext" => "reserved",
  },

  # XDR: AccountEntryExtensionV2.ext (extension union)
  # SDK renames extension fields to "reserved"
  "AccountEntryExtensionV2" => {
    "ext" => "reserved",
  },

  # XDR: AccountEntry.seqNum
  # SDK uses "sequenceNumber" instead of "seqNum"
  "AccountEntryXDR" => {
    "seqNum" => "sequenceNumber",
  },

  # XDR: DataEntry.ext (extension union)
  # SDK renames extension fields to "reserved"
  "DataEntryXDR" => {
    "ext" => "reserved",
  },

  # XDR: InnerTransactionResultPair.transactionHash
  # SDK shortens to "hash"
  "InnerTransactionResultPair" => {
    "transactionHash" => "hash",
  },

  # XDR: TrustlineEntryXDR.ext (extension union)
  # SDK renames extension fields to "reserved"
  "TrustlineEntryXDR" => {
    "ext" => "reserved",
  },

  # XDR: Int256Parts uses underscore-separated field names (hi_hi, hi_lo, etc.)
  # SDK uses camelCase
  "Int256PartsXDR" => {
    "hi_hi" => "hiHi",
    "hi_lo" => "hiLo",
    "lo_hi" => "loHi",
    "lo_lo" => "loLo",
  },

  # XDR: LedgerEntryChanges is a typedef for LedgerEntryChange<>
  # Generator wraps in struct with "wrapped" field; SDK uses "ledgerEntryChanges"
  "LedgerEntryChangesXDR" => {
    "wrapped" => "ledgerEntryChanges",
  },

  # XDR: LedgerEntryExtensionV1.sponsoringID, ext
  # SDK uses "signerSponsoringID" and renames ext to "reserved"
  "LedgerEntryExtensionV1" => {
    "sponsoringID" => "signerSponsoringID",
    "ext" => "reserved",
  },

  # XDR: LedgerEntry.ext (extension union)
  # SDK renames to "reserved"
  "LedgerEntryXDR" => {
    "ext" => "reserved",
  },

  # XDR: OfferEntry.ext (extension union)
  # SDK renames to "reserved"
  "OfferEntryXDR" => {
    "ext" => "reserved",
  },

  # XDR: PathPaymentStrictReceiveOp.destAsset, destAmount
  # SDK expands abbreviated names
  "PathPaymentOperationXDR" => {
    "destAsset" => "destinationAsset",
    "destAmount" => "destinationAmount",
  },

  # XDR: PreconditionsV2.minSeqNum
  # SDK renames to "sequenceNumber"
  "PreconditionsV2XDR" => {
    "minSeqNum" => "sequenceNumber",
  },

  # XDR: SCMetaV0.val
  # SDK uses "value" instead of "val"
  "SCMetaV0XDR" => {
    "val" => "value",
  },

  # XDR: SetOptionsOp.inflationDest
  # SDK expands to "inflationDestination"
  "SetOptionsOperationXDR" => {
    "inflationDest" => "inflationDestination",
  },

  # XDR: SetTrustLineFlagsOp.trustor
  # SDK renames to "accountID"
  "SetTrustLineFlagsOpXDR" => {
    "trustor" => "accountID",
  },

  # XDR: UInt256Parts uses underscore-separated field names
  # SDK uses camelCase
  "UInt256PartsXDR" => {
    "hi_hi" => "hiHi",
    "hi_lo" => "hiLo",
    "lo_hi" => "loHi",
    "lo_lo" => "loLo",
  },
}.freeze

# XDR `string` positions the SDK carries as raw bytes rather than as Swift text.
#
# An XDR `string` holds arbitrary bytes. A struct field or union arm listed here
# is emitted as `Data` and keeps the `string` wire form -- a length prefix, the
# bytes, and padding to a multiple of four -- so its encoding is unchanged.
# Beside it the generator emits the named accessor, which reads the bytes as
# UTF-8 for a caller that wants text, plus a String-taking convenience (an
# initializer on a struct, a static factory on a union) that encodes UTF-8 once.
# TxRep and XDR-JSON apply their escape ladders to the bytes directly, so a
# value that spells text keeps the rendering its String form would produce.
#
# Format:
#   "SwiftTypeName" => { "xdrFieldName" => "utf8AccessorName" }
#
# The xdrFieldName is the name from the .x file, before any FIELD_OVERRIDES
# renaming.

BYTES_BACKED_STRING_FIELDS = {
  "ContractExecutableExternalRefXDR" => { "tag" => "tagString" },
  "SCValXDR" => { "executable_tag" => "executableTagString" },
}.freeze
