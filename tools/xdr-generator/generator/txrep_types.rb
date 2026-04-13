# frozen_string_literal: true
require 'set'

# TxRep type registry.
#
# This file declares which XDR types participate in TxRep (human-readable
# transaction envelope) serialization. It is consumed by the xdr-generator
# to decide which generated Swift types receive toTxRep()/fromTxRep() methods
# and how fields of well-known types are formatted.
#
# Four artifacts are defined:
#
#   TXREP_XDR_NAMES
#     A frozen Set of raw canonical XDR type names (as written in the
#     .x files) reachable from the TransactionEnvelope / Transaction /
#     FeeBumpTransaction / DecoratedSignature roots. These are the names
#     BEFORE NAME_OVERRIDES / TYPE_OVERRIDES translation. Primitives
#     (int/uint/hyper/opaque/string) are intentionally excluded.
#
#   TxRepTypes.resolved_swift_names(generator)
#     Computes the Set of Swift type names that correspond to TXREP_XDR_NAMES
#     by running each entry through the generator's name() resolver. This
#     is the set the generator uses to decide whether to emit TxRep methods
#     on a given rendered struct/union/enum/typedef.
#
#   TxRepTypes.should_generate_txrep?(generator, swift_name)
#     Predicate called from render_enum / render_struct / render_union /
#     render_typedef. Returns true iff the given resolved Swift name is
#     in the TxRep set.
#
#   TXREP_COMPACT_TYPES
#     Hash mapping Swift type names -> { format:, parse: } -> fully-qualified
#     TxRepHelper method names used to serialize/parse the type as a single
#     compact string (e.g. PublicKey -> G... strkey). Fields of these types
#     emit a single TxRep line instead of nested struct expansion.
#
#     NOTE: ChangeTrustAssetXDR and TrustlineAssetXDR are intentionally NOT
#     listed here. Their native / credit_alphanum arms are compact via the
#     TxRepHelper.formatAsset helper, but their liquidityPoolShare arm is
#     expanded field-by-field. That split requires per-arm handling in the
#     union codegen (Phase 4), not a blanket compact entry.
#
#   UNION_ARM_FIELD_OVERRIDES
#     Nested Hash keyed by [union_xdr_name, arm_xdr_name] with value a
#     Hash of { struct_field_name => txrep_key_suffix }. Used by the
#     OperationBody (and any other union) codegen to remap the TxRep
#     key suffix when the canonical Swift field name differs from the
#     string used in the historical hand-written TxRep serializer.
#
#     Keys are XDR canonical names (not Swift resolved names) so the map
#     remains stable across NAME_OVERRIDES changes.

module TxRepTypes
  # ---------------------------------------------------------------------------
  # 1. XDR canonical names reachable from the transaction envelope graph.
  # ---------------------------------------------------------------------------
  #
  # Traced from TransactionEnvelope / Transaction / FeeBumpTransaction /
  # DecoratedSignature. Cross-checked against the iOS .x files in ../xdr/.
  # Primitive typedefs (int32/uint32/int64/uint64/TimePoint/Duration/Hash/
  # uint256/Signature/SignatureHint/DataValue/string32/string64/PoolID/
  # SequenceNumber) are excluded: they resolve to Swift scalars or wrapped
  # data types that don't receive toTxRep methods.
  TXREP_XDR_NAMES = Set[
    # --- roots ---
    'TransactionEnvelope',
    'TransactionV1Envelope',
    'TransactionV0Envelope',
    'FeeBumpTransactionEnvelope',
    'Transaction',
    'TransactionV0',
    'FeeBumpTransaction',
    'DecoratedSignature',

    # --- Transaction extension / fee-bump inner tx unions ---
    'TransactionExt',
    'TransactionV0Ext',
    'FeeBumpTransactionExt',
    'FeeBumpTransactionInnerTx',

    # --- accounts / keys ---
    'PublicKey',
    'MuxedAccount',
    'MuxedEd25519Account',
    'SignerKey',
    'SignerKeyType',
    'CryptoKeyType',
    'PublicKeyType',
    'Signer',

    # --- memo / preconditions / bounds ---
    'Memo',
    'MemoType',
    'Preconditions',
    'PreconditionType',
    'PreconditionsV2',
    'TimeBounds',
    'LedgerBounds',

    # --- operations ---
    'Operation',
    'OperationBody',
    'OperationType',
    'CreateAccountOp',
    'PaymentOp',
    'PathPaymentStrictReceiveOp',
    'PathPaymentStrictSendOp',
    'ManageSellOfferOp',
    'ManageBuyOfferOp',
    'CreatePassiveSellOfferOp',
    'SetOptionsOp',
    'ChangeTrustOp',
    'AllowTrustOp',
    'AllowTrustOpAsset',
    'ManageDataOp',
    'BumpSequenceOp',
    'CreateClaimableBalanceOp',
    'ClaimClaimableBalanceOp',
    'BeginSponsoringFutureReservesOp',
    'RevokeSponsorshipOp',
    'RevokeSponsorshipType',
    'RevokeSponsorshipSigner',
    # The XDR arm struct is anonymous-nested inside RevokeSponsorshipOp; the
    # qualified AST name used by TxRepTypes.resolved_swift_names is therefore
    # RevokeSponsorshipOpSigner. NAME_OVERRIDES collapses both onto
    # RevokeSponsorshipSignerXDR, but TxRep dispatch has to match one of the
    # AST-visible names before overrides are applied.
    'RevokeSponsorshipOpSigner',
    'ClawbackOp',
    'ClawbackClaimableBalanceOp',
    'SetTrustLineFlagsOp',
    'LiquidityPoolDepositOp',
    'LiquidityPoolWithdrawOp',
    'InvokeHostFunctionOp',
    'ExtendFootprintTTLOp',
    'RestoreFootprintOp',

    # --- assets / trust ---
    'Asset',
    'AssetType',
    'AlphaNum4',
    'AlphaNum12',
    'ChangeTrustAsset',
    'TrustLineAsset',
    'LiquidityPoolParameters',
    'LiquidityPoolType',
    'LiquidityPoolConstantProductParameters',

    # --- claimable balance / claimant / predicate ---
    'ClaimableBalanceID',
    'ClaimableBalanceIDType',
    'Claimant',
    'ClaimantType',
    'ClaimantV0',
    'ClaimPredicate',
    'ClaimPredicateType',

    # --- price ---
    'Price',

    # --- ledger keys (used inside RevokeSponsorshipOp) ---
    'LedgerKey',
    'LedgerEntryType',
    'LedgerKeyAccount',
    'LedgerKeyTrustLine',
    'LedgerKeyOffer',
    'LedgerKeyData',
    'LedgerKeyClaimableBalance',
    'LedgerKeyLiquidityPool',
    'LedgerKeyContractData',
    'LedgerKeyContractCode',
    'LedgerKeyConfigSetting',
    'LedgerKeyTtl',

    # --- soroban (invoke host function) ---
    'HostFunction',
    'HostFunctionType',
    'InvokeContractArgs',
    'CreateContractArgs',
    'CreateContractArgsV2',
    'ContractIDPreimage',
    'ContractIDPreimageType',
    'ContractIDPreimageFromAddress',
    'ContractExecutable',
    'ContractExecutableType',
    'ContractDataDurability',
    'SorobanAuthorizationEntry',
    'SorobanCredentials',
    'SorobanCredentialsType',
    'SorobanAddressCredentials',
    'SorobanAuthorizedInvocation',
    'SorobanAuthorizedFunction',
    'SorobanAuthorizedFunctionType',
    'SorobanTransactionData',
    'SorobanTransactionDataExt',
    'SorobanResources',
    'SorobanResourcesExtV0',
    'LedgerFootprint',
    'ConfigSettingID',

    # --- contract values (used inside InvokeContractArgs etc.) ---
    'SCVal',
    'SCValType',
    'SCAddress',
    'SCAddressType',
    'SCContractInstance',
    'SCNonceKey',
    'SCMapEntry',
    'SCError',
    'SCErrorType',
    'SCErrorCode',
    'Int128Parts',
    'UInt128Parts',
    'Int256Parts',
    'UInt256Parts',

    # --- extension points / envelope discriminators ---
    'ExtensionPoint',
    'EnvelopeType',

    # --- signed payload (nested inside SignerKey) ---
    'SignerKeyEd25519SignedPayload',
  ].freeze

  # ---------------------------------------------------------------------------
  # 2. TxRep helper bindings for types serialized as a single compact string.
  # ---------------------------------------------------------------------------
  #
  # Keyed by the RESOLVED Swift type name (after NAME_OVERRIDES / TYPE_OVERRIDES).
  TXREP_COMPACT_TYPES = {
    'PublicKey'            => { format: 'TxRepHelper.formatAccountId',       parse: 'TxRepHelper.parseAccountId'       },
    'AllowTrustOpAssetXDR' => { format: 'TxRepHelper.formatAllowTrustAsset', parse: 'TxRepHelper.parseAllowTrustAsset' },
    'AssetXDR'             => { format: 'TxRepHelper.formatAsset',           parse: 'TxRepHelper.parseAsset'           },
    'MuxedAccountXDR'      => { format: 'TxRepHelper.formatMuxedAccount',    parse: 'TxRepHelper.parseMuxedAccount'    },
    'SignerKeyXDR'         => { format: 'TxRepHelper.formatSignerKey',       parse: 'TxRepHelper.parseSignerKey'       },
  }.freeze

  # ---------------------------------------------------------------------------
  # 3. Per-union-arm field name overrides.
  # ---------------------------------------------------------------------------
  #
  # Keyed by [union_xdr_name, arm_xdr_name] -> { swift_field_name => txrep_key_suffix }.
  #
  # Audit of stellarsdk/stellarsdk/txrep/TxRep.swift identified these TxRep
  # key suffixes that differ from the corresponding Swift struct field names:
  #
  #   ManageBuyOfferOp.amount       -> "buyAmount"         (TxRep.swift:2562, TxRepOperationsTestCase.swift:208)
  #   PathPaymentStrictSendOp.sendMax                 -> "sendAmount"   (TxRep.swift:2540)
  #   PathPaymentStrictSendOp.destinationAsset        -> "destAsset"    (TxRep.swift:2542)
  #   PathPaymentStrictSendOp.destinationAmount       -> "destMin"      (TxRep.swift:2543)
  #   PathPaymentStrictReceiveOp.destinationAsset     -> "destAsset"    (TxRep.swift:2529)
  #   PathPaymentStrictReceiveOp.destinationAmount    -> "destAmount"   (TxRep.swift:2530)
  #   SetTrustLineFlagsOp.accountID                   -> "trustor"      (TxRep.swift:2750)
  #   BeginSponsoringFutureReservesOp.sponsoredId     -> "sponsoredID"  (TxRep.swift:2705)
  UNION_ARM_FIELD_OVERRIDES = {
    ['OperationBody', 'manageBuyOfferOp']              => { 'amount'            => 'buyAmount'   },
    ['OperationBody', 'pathPaymentStrictSendOp']       => {
      'sendMax'           => 'sendAmount',
      'destinationAsset'  => 'destAsset',
      'destinationAmount' => 'destMin',
    },
    ['OperationBody', 'pathPaymentStrictReceiveOp']    => {
      'destinationAsset'  => 'destAsset',
      'destinationAmount' => 'destAmount',
    },
    ['OperationBody', 'setTrustLineFlagsOp']           => { 'accountID'   => 'trustor'    },
    ['OperationBody', 'beginSponsoringFutureReservesOp'] => { 'sponsoredId' => 'sponsoredID' },
  }.freeze

  # ---------------------------------------------------------------------------
  # 5. Unions whose TxRep methods are hand-written (skip generator).
  # ---------------------------------------------------------------------------
  #
  # TransactionEnvelopeXDR needs a flattened `tx.sourceAccount` layout that
  # the generic union codegen cannot produce (it would emit `tx.v1.tx...`).
  # Phase 6 delivers hand-written implementations in
  # stellarsdk/stellarsdk/txrep/extensions/. The generator emits NO extension
  # block for these types — the hand-written files provide the conformances.
  TXREP_UNION_SKIP = Set[
    'TransactionEnvelopeXDR',
    # FeeBumpTransactionXDRInnerTxXDR transitively references
    # TransactionV1EnvelopeXDR (a SKIP_TYPES hand-written struct) in its
    # only non-void arm, so it too needs hand-written TxRep wiring delivered
    # alongside the TransactionEnvelopeXDR work in Phase 6.
    'FeeBumpTransactionXDRInnerTxXDR',
    # ChangeTrustAssetXDR and TrustlineAssetXDR use compact single-line format
    # for native/alphanum4/alphanum12 arms (via TxRepHelper.formatChangeTrustAsset
    # / parseTrustlineAsset) but expanded format for poolShare. The generic union
    # codegen cannot produce this per-arm split, so hand-written extensions
    # supply the TxRep methods for these types.
    'ChangeTrustAssetXDR',
    'TrustlineAssetXDR',
    # TransactionExtXDR uses a flattened SEP-0011 key layout: ext.v + sorobanData.*
    # at the transaction prefix level (NOT ext.sorobanData.*). The generic union
    # codegen would produce the wrong prefix. The hand-written emitTransactionExt /
    # parseTransactionExt helpers in TransactionXDR+TxRep.swift own this logic.
    'TransactionExtXDR',
  ].freeze

  # ---------------------------------------------------------------------------
  # 6. Liquidity pool ID fields that accept both hex-64 and L-address StrKey.
  # ---------------------------------------------------------------------------
  #
  # When parsing TxRep, these [swift_struct_name, swift_field_name] pairs must
  # use TxRepHelper.requireLiquidityPoolId instead of TxRepHelper.requireWrappedData32
  # so that both raw 64-char hex and L-address StrKey inputs are accepted.
  # The OUTPUT (toTxRep) always remains hex — only the parse path changes.
  TXREP_LIQUIDITY_POOL_ID_FIELDS = Set[
    ['LedgerKeyLiquidityPoolXDR', 'liquidityPoolID'],
    ['SCAddressXDR',              'liquidityPoolId'],
  ].freeze

  # ---------------------------------------------------------------------------
  # 4. Runtime resolution helpers.
  # ---------------------------------------------------------------------------

  # Walks the generator's AST, looking up each XDR canonical name in
  # TXREP_XDR_NAMES, and returns a frozen Set of the corresponding resolved
  # Swift type names (as produced by generator.name()). Entries that cannot
  # be resolved (because the .x file omits the type or it has been renamed
  # out of existence) are silently skipped.
  def self.resolved_swift_names(generator)
    if defined?(@resolved_swift_names) && @resolved_swift_names &&
       defined?(@resolved_swift_names_generator) && @resolved_swift_names_generator.equal?(generator)
      return @resolved_swift_names
    end

    names = Set.new
    collect_definitions(generator.instance_variable_get(:@top)).each do |defn|
      next unless defn.respond_to?(:name)

      # Match on either the bare XDR name or the raw qualified XDR name
      # (parent chain concatenated without NAME_OVERRIDES). The latter is
      # required for nested anonymous unions such as SorobanTransactionData.ext
      # which is registered as 'SorobanTransactionDataExt' in TXREP_XDR_NAMES.
      bare = defn.name.to_s
      qualified =
        begin
          generator.send(:raw_xdr_qualified_name, defn)
        rescue StandardError
          nil
        end

      in_set = TXREP_XDR_NAMES.include?(bare) ||
               (qualified && TXREP_XDR_NAMES.include?(qualified))
      next unless in_set

      begin
        names << generator.send(:name, defn)
      rescue StandardError
        # If name resolution fails for a given defn (e.g. primitive typedef),
        # skip it quietly; TxRep dispatch will not target it anyway.
      end
    end

    @resolved_swift_names_generator = generator
    @resolved_swift_names = names.freeze
  end

  # Predicate for render_enum / render_struct / render_union / render_typedef.
  def self.should_generate_txrep?(generator, swift_name)
    resolved_swift_names(generator).include?(swift_name)
  end

  # Recursively collects every definition node (struct/union/enum/typedef)
  # from the parsed AST, including those declared inside namespaces and
  # nested inside parent definitions.
  def self.collect_definitions(node, acc = [])
    return acc if node.nil?

    if node.respond_to?(:definitions)
      node.definitions.each do |defn|
        acc << defn
        collect_nested(defn, acc)
      end
    end

    if node.respond_to?(:namespaces)
      node.namespaces.each { |ns| collect_definitions(ns, acc) }
    end

    acc
  end

  def self.collect_nested(defn, acc)
    return unless defn.respond_to?(:nested_definitions)
    defn.nested_definitions.each do |nested|
      acc << nested
      collect_nested(nested, acc)
    end
  end

  private_class_method :collect_definitions, :collect_nested
end
