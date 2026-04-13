# frozen_string_literal: true

# =============================================================================
# TxRepTestValues
#
# Swift value-expression fabrication for the TxRep roundtrip test generator.
# Given a type name (or AST declaration) and a recursion depth, returns a
# Swift literal expression the test file can paste directly into a let-binding.
#
# The generator's priority order:
#   1. Fallback table (SKIP_TYPES, recursive anchors, strkey-backed types)
#   2. Primitives, strings, Data/WrappedDataN, arrays
#   3. Type-registry lookup via the caller (recurse into struct/enum/union)
#
# Depth cap: MAX_DEPTH guards against recursive types such as SCValXDR that
# can reference themselves through .vec / .map arms.
# =============================================================================

module TxRepTestValues
  MAX_DEPTH = 5

  # -- Entry points ------------------------------------------------------------

  # Build a Swift expression for a fully-populated struct.
  # Returns nil if any non-optional field cannot be constructed.
  def self.struct_expr(driver, swift_name, struct_defn, depth)
    return fallback_value(swift_name, depth) if fallback_value(swift_name, depth)
    return nil if depth > MAX_DEPTH

    gen = driver.gen
    init_fields = []
    struct_defn.members.each do |m|
      field = gen.pub_resolve_field_name(swift_name, m.name)
      next if gen.pub_is_extension_point_field?(swift_name, field)
      type_str = gen.pub_resolve_field_type(swift_name, field, m)
      param = gen.pub_resolve_init_param_name(swift_name, field)

      is_opt = m.type.sub_type == :optional ||
               (m.declaration.type.respond_to?(:sub_type) &&
                gen.pub_typedef_is_optional?(m.declaration.type))
      decl = m.declaration

      expr = field_expr(driver, swift_name, field, type_str, decl, is_opt, depth)
      return nil unless expr
      init_fields << { param: param, expr: expr }
    end

    apply_init_param_order(swift_name, init_fields)
    args = init_fields.map { |f| "#{f[:param]}: #{f[:expr]}" }.join(', ')
    "#{swift_name}(#{args})"
  end

  # Apply INIT_PARAM_ORDER from type_overrides.rb so parameters are passed in
  # the exact order the hand-modified init expects.
  def self.apply_init_param_order(swift_name, init_fields)
    return unless defined?(::INIT_PARAM_ORDER) && ::INIT_PARAM_ORDER.key?(swift_name)
    order = ::INIT_PARAM_ORDER[swift_name]
    init_fields.sort_by! do |f|
      idx = order.index(f[:param])
      idx || (order.length + init_fields.index(f))
    end
  end

  # Build a Swift expression for a union enum-case value (one arm).
  # entry is the hash produced by build_union_case_entries.
  def self.union_case_expr(driver, swift_name, entry, depth)
    case_name = entry[:case_name]
    if entry[:decode_style] == :void
      ".#{case_name}"
    else
      payload_type = entry[:associated_type]
      # Optional payload: allow nil since TxRep methods handle ._present = false.
      if entry[:decode_style] == :optional
        # Strip trailing "?" if present so fabrication picks the non-optional
        # expression we can unwrap with Optional("...").
        base = payload_type.sub(/\?\z/, '')
        inner = type_expr(driver, base, depth + 1)
        return nil unless inner
        ".#{case_name}(#{inner})"
      else
        inner = type_expr(driver, payload_type, depth + 1)
        return nil unless inner
        ".#{case_name}(#{inner})"
      end
    end
  end

  # -- Field-level fabrication --------------------------------------------------

  def self.field_expr(driver, parent_name, field, type_str, decl, is_opt, depth)
    gen = driver.gen

    # Fixed-size opaque: produce WrappedDataN(Data(repeating:count:)) or raw Data.
    if decl.is_a?(Xdrgen::AST::Declarations::Opaque) && decl.fixed?
      size = opaque_size(decl).to_i
      if [4, 12, 16, 32].include?(size)
        return "WrappedData#{size}(Data(repeating: 0xAB, count: #{size}))"
      else
        return "Data(repeating: 0xAB, count: #{size})"
      end
    end

    # Variable-length opaque: plain Data.
    if decl.is_a?(Xdrgen::AST::Declarations::Opaque) && !decl.fixed?
      return 'Data([0x01, 0x02, 0x03])'
    end

    # String
    if decl.is_a?(Xdrgen::AST::Declarations::String)
      return '"test_string"'
    end

    # Array
    if decl.is_a?(Xdrgen::AST::Declarations::Array)
      inner_decl_type = decl.type
      element_base = strip_optional(type_str.sub(/\A\[(.*)\]\z/, '\\1'))
      if decl.fixed?
        count = gen.pub_resolve_size(decl).to_i
        inner = type_expr(driver, element_base, depth + 1)
        return nil unless inner
        elements = Array.new(count, inner).join(', ')
        return "[#{elements}]"
      else
        # For variable-length arrays, an empty array is always valid and is
        # the simplest way to avoid recursion explosions. TxRep still emits
        # a ".len: 0" line and fromTxRep correctly reconstructs the empty case.
        return '[]'
      end
    end

    # Optional field: produce nil if possible, otherwise fabricate.
    # For TxRep, optional fields with is_opt=true follow the `._present`
    # protocol; fromTxRep must handle both present and absent states. We
    # default to nil to keep the test surface small. The explicit type cast
    # avoids overload-resolution ambiguity when the parent type has a
    # deprecated alternate init (see OperationXDR's MuxedAccountXDR?/PublicKey?
    # pair).
    if is_opt
      return "#{strip_optional(type_str)}?.none"
    end

    # Non-optional simple types: delegate to type_expr.
    type_expr(driver, strip_optional(type_str), depth)
  end

  # Build a Swift expression for a pure Swift type string (no decl metadata).
  def self.type_expr(driver, type_str, depth)
    t = strip_optional(type_str.to_s.strip)

    # Array syntax
    if t =~ /\A\[(.+)\]\z/
      element = Regexp.last_match(1)
      inner = type_expr(driver, element, depth + 1)
      return inner ? '[]' : '[]'
    end

    # Primitives
    case t
    when 'Int32' then return '42'
    when 'UInt32' then return 'UInt32(42)'
    when 'Int64' then return 'Int64(1234567)'
    when 'UInt64' then return 'UInt64(1234567)'
    when 'Bool' then return 'true'
    when 'String' then return '"test_string"'
    when 'Float' then return 'Float(3.14)'
    when 'Double' then return 'Double(3.14)'
    when 'Data' then return 'Data([0x01, 0x02, 0x03])'
    when 'WrappedData4' then return 'WrappedData4(Data(repeating: 0xAB, count: 4))'
    when 'WrappedData12' then return 'WrappedData12(Data(repeating: 0xAB, count: 12))'
    when 'WrappedData16' then return 'WrappedData16(Data(repeating: 0xAB, count: 16))'
    when 'WrappedData32' then return 'WrappedData32(Data(repeating: 0xAB, count: 32))'
    end

    # Hand-written fallbacks (SKIP_TYPES, recursive anchors, strkey types)
    fb = fallback_value(t, depth)
    return fb if fb

    return nil if depth > MAX_DEPTH

    # Look up in registry
    info = driver.lookup(t)
    return nil unless info

    case info[:kind]
    when :enum
      first = info[:defn].members.first
      return nil unless first
      raw = first.name.to_s
      case_name = driver.gen.send(:swift_enum_case_name, info[:defn].name.to_s, raw, enum_defn: info[:defn])
      ".#{case_name}"
    when :struct
      struct_expr(driver, t, info[:defn], depth + 1)
    when :union
      union_any_arm_expr(driver, t, info[:defn], depth + 1)
    when :typedef
      typedef_expr(driver, t, info[:defn], depth + 1)
    end
  end

  def self.typedef_expr(driver, swift_name, typedef_defn, depth)
    # Typedefs that have a TYPE_OVERRIDE resolve to a primitive/wrapper.
    if defined?(::TYPE_OVERRIDES) && ::TYPE_OVERRIDES.key?(swift_name)
      return type_expr(driver, ::TYPE_OVERRIDES[swift_name], depth)
    end
    decl = typedef_defn.declaration
    gen = driver.gen
    case decl
    when Xdrgen::AST::Declarations::Opaque
      if decl.fixed?
        size = opaque_size(decl).to_i
        if [4, 12, 16, 32].include?(size)
          "WrappedData#{size}(Data(repeating: 0xAB, count: #{size}))"
        else
          "Data(repeating: 0xAB, count: #{size})"
        end
      else
        'Data([0x01, 0x02, 0x03])'
      end
    when Xdrgen::AST::Declarations::String
      '"test_string"'
    when Xdrgen::AST::Declarations::Array
      '[]'
    else
      inner = gen.pub_type_string(decl.type)
      inner_expr = type_expr(driver, inner, depth + 1)
      return nil unless inner_expr
      # Typedef wrappers are declared as `typealias`, so the value of the
      # typedef is the inner value - the wrapper name is transparent at the
      # construction site.
      inner_expr
    end
  end

  # Find any constructible arm of a union (prefer void, else first non-void).
  def self.union_any_arm_expr(driver, swift_name, union_defn, depth)
    return fallback_value(swift_name, depth) if fallback_value(swift_name, depth)
    return nil if depth > MAX_DEPTH
    disc_info = driver.gen.pub_resolve_discriminant_info(union_defn)
    entries = driver.gen.pub_build_union_case_entries(union_defn, swift_name, disc_info)

    # Prefer a void arm for minimal recursion.
    void_entry = entries.find { |e| e[:decode_style] == :void && !e[:is_default] }
    if void_entry
      return ".#{void_entry[:case_name]}"
    end

    entries.each do |e|
      next if e[:is_default]
      expr = union_case_expr(driver, swift_name, e, depth)
      return expr if expr
    end
    nil
  end

  # Resolve the literal byte-count of a fixed opaque declaration.
  # `decl.size` on a fixed opaque returns either an integer literal or an
  # AST::Identifier referencing a `const` definition. The constant path
  # requires a lookup we don't have here, so we ask resolved_size instead
  # when available and fall back to a string-parse otherwise.
  def self.opaque_size(decl)
    return decl.resolved_size if decl.respond_to?(:resolved_size) && decl.resolved_size
    size = decl.size
    return size.to_i if size.respond_to?(:to_i) && !size.is_a?(Xdrgen::AST::Identifier)
    # Identifier reference (e.g., "CONSTANT_NAME") - we can't resolve it here.
    # Fall back to 32 as a safe default since all TxRep fixed-opaque fields
    # in the current Stellar XDR are 32 bytes.
    32
  end

  def self.strip_optional(type_str)
    type_str.to_s.sub(/\?\z/, '')
  end

  # ---------------------------------------------------------------------------
  # Fallback value table
  # ---------------------------------------------------------------------------
  #
  # Hand-written Swift expressions for types where the registry-driven
  # recursion cannot produce a correct value. Covers three classes:
  #
  #   * SKIP_TYPES in generator.rb (hand-written SDK classes with custom
  #     constructors that the generator does not emit)
  #   * Recursive anchors (SCValXDR, ClaimPredicateXDR, SorobanAuthorized-
  #     InvocationXDR) where we pick a terminal leaf value to prevent
  #     infinite fabrication
  #   * Compact strkey types that need valid base32 content (PublicKey,
  #     MuxedAccountXDR, SignerKeyXDR) so that TxRep format/parse succeed
  #
  # Any entry here should be accompanied by a code comment explaining why
  # the value cannot come from the registry walker.
  FALLBACKS = {
    # --- SKIP_TYPES: hand-written classes, no generator-produced init ---
    'PublicKey' => lambda { |_d|
      'try PublicKey([UInt8](repeating: 0xAB, count: 32))'
    },
    'MuxedAccountXDR' => lambda { |_d|
      # Pick ed25519 arm - the med25519 arm cross-references a nested
      # struct that is itself a SKIP_TYPE and uses raw bytes.
      '.ed25519([UInt8](repeating: 0xAB, count: 32))'
    },
    'MuxedAccountMed25519XDR' => lambda { |_d|
      'MuxedAccountMed25519XDR(id: UInt64(1), sourceAccountEd25519: [UInt8](repeating: 0xAB, count: 32))'
    },

    # --- Compact asset types: TxRep formats these as "CODE:G..." strkey
    # strings via TxRepHelper.formatAllowTrustAsset / formatAsset. The
    # asset code bytes must be printable ASCII or the compact parser
    # rejects the roundtrip with invalidValue.
    'AllowTrustOpAssetXDR' => lambda { |_d|
      '.alphanum4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00])))'
    },
    'AssetCode4XDR' => lambda { |_d|
      'WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))'
    },
    'AssetCode12XDR' => lambda { |_d|
      'WrappedData12(Data([0x55, 0x53, 0x44, 0x43, 0x54, 0x4f, 0x4b, 0x45, 0x4e, 0x00, 0x00, 0x00]))'
    },
    # AssetXDR compact format needs the native / alphanum4 / alphanum12
    # arms to carry valid StrKey-encodable issuers. Default to the native
    # arm which has no payload and always round-trips cleanly.
    'AssetXDR' => lambda { |_d|
      '.native'
    },
    'ChangeTrustAssetXDR' => lambda { |_d|
      '.native'
    },
    'TrustlineAssetXDR' => lambda { |_d|
      '.native'
    },

    # --- Recursive anchors ---
    'SCValXDR' => lambda { |_d|
      # Terminal leaf: SCV_VOID carries no payload and cannot recurse.
      '.void'
    },
    'ClaimPredicateXDR' => lambda { |_d|
      '.claimPredicateUnconditional'
    },
    'SorobanAuthorizedInvocationXDR' => lambda { |_d|
      # Construct with a contract function and an empty subinvocations array.
      'SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: [])'
    },

    # --- SKIP_TYPES: TransactionXDR and envelopes ---
    'TransactionXDR' => lambda { |_d|
      'TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100))'
    },
    'TransactionV0XDR' => lambda { |_d|
      'TransactionV0XDR(sourceAccount: try! PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: [])'
    },
    'TransactionV1EnvelopeXDR' => lambda { |d|
      "TransactionV1EnvelopeXDR(tx: #{FALLBACKS['TransactionXDR'].call(d)}, signatures: [])"
    },
    'TransactionV0EnvelopeXDR' => lambda { |d|
      "TransactionV0EnvelopeXDR(tx: #{FALLBACKS['TransactionV0XDR'].call(d)}, signatures: [])"
    },
    'FeeBumpTransactionXDR' => lambda { |d|
      "FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(#{FALLBACKS['TransactionV1EnvelopeXDR'].call(d)}), fee: UInt64(2000))"
    },
    'FeeBumpTransactionEnvelopeXDR' => lambda { |d|
      "FeeBumpTransactionEnvelopeXDR(tx: #{FALLBACKS['FeeBumpTransactionXDR'].call(d)}, signatures: [])"
    },
    'TransactionEnvelopeXDR' => lambda { |d|
      ".v1(#{FALLBACKS['TransactionV1EnvelopeXDR'].call(d)})"
    },
    'FeeBumpTransactionXDRInnerTxXDR' => lambda { |d|
      ".v1(#{FALLBACKS['TransactionV1EnvelopeXDR'].call(d)})"
    },
  }.freeze

  def self.fallback_value(type_name, depth)
    fn = FALLBACKS[type_name]
    return nil unless fn
    fn.call(depth)
  end
end
