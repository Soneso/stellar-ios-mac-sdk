# frozen_string_literal: true

# Deterministic Swift value expressions for the SEP-0051 (XDR-JSON) test emitter.
#
# Given a type and a recursion depth, produces a Swift expression the emitted suite binds
# to a `let`. The same input always produces the same expression, so re-running the emitter
# on an unchanged .x set rewrites the suite byte for byte.
#
# The values are chosen to be inside the domain SEP-0051 accepts, which is narrower than the
# domain XDR accepts. A signed payload must carry at least one byte, an AssetCode12 must keep
# at least five after its trailing NULs are trimmed, and a strkey-rendered field must hold
# the exact byte count its version byte implies. A fixture outside any of those raises at
# conversion time, which would read as an emitter defect rather than as the deliberate
# rejection it is.
#
# Resolution order: the fallback table, then primitives and containers, then the type
# registry the caller owns.
module Sep51JsonTestValues
  MAX_DEPTH = 8

  # The fixture for a `string` position carried as raw bytes (see
  # BYTES_BACKED_STRING_FIELDS). 0xff begins no UTF-8 sequence, so the round
  # trip only passes when the bytes themselves survive the escape ladder.
  BYTES_BACKED_STRING_SAMPLE = 'Data([0x74, 0x61, 0x67, 0x00, 0xff, 0x10])'

  # -- Entry points -----------------------------------------------------------

  # A fully populated struct. Returns nil when a required field cannot be built.
  def self.struct_expr(driver, swift_name, struct_defn, depth)
    fallback = fallback_value(swift_name)
    return fallback if fallback
    return nil if depth > MAX_DEPTH

    gen = driver.gen
    arguments = []
    struct_defn.members.each do |member|
      field = gen.pub_resolve_field_name(swift_name, member.name)
      next if gen.pub_is_extension_point_field?(swift_name, field)

      if defined?(::BYTES_BACKED_STRING_FIELDS) &&
         ::BYTES_BACKED_STRING_FIELDS.dig(swift_name, member.name.to_s)
        label = gen.pub_resolve_init_param_name(swift_name, field).to_s.delete('`')
        arguments << { param: label, expr: BYTES_BACKED_STRING_SAMPLE }
        next
      end

      type_str = gen.pub_resolve_field_type(swift_name, field, member)
      optional = member.type.sub_type == :optional ||
                 (member.declaration.type.respond_to?(:sub_type) &&
                  gen.pub_typedef_is_optional?(member.declaration.type))

      expression = field_expr(driver, type_str, member.declaration, optional, depth)
      return nil unless expression

      # An argument label spelled like a keyword needs no backticks at a call site, and
      # carrying them over from the declaration is a compiler warning.
      label = gen.pub_resolve_init_param_name(swift_name, field).to_s.delete('`')
      arguments << { param: label, expr: expression }
    end

    apply_init_param_order(swift_name, arguments)
    "#{swift_name}(#{arguments.map { |a| "#{a[:param]}: #{a[:expr]}" }.join(', ')})"
  end

  # One union arm, as a Swift case expression.
  def self.union_case_expr(driver, entry, depth)
    return ".#{entry[:case_name]}" if entry[:decode_style] == :void
    return ".#{entry[:case_name]}(#{BYTES_BACKED_STRING_SAMPLE})" if entry[:bytes_backed]

    payload = type_expr(driver, strip_optional(entry[:associated_type]), depth + 1)
    return nil unless payload

    ".#{entry[:case_name]}(#{payload})"
  end

  # A typedef, whose Swift form is either an array wrapper struct or a transparent alias.
  def self.typedef_expr(driver, swift_name, typedef_defn, depth)
    fallback = fallback_value(swift_name)
    return fallback if fallback

    collapsed = ::TYPE_OVERRIDES[swift_name] if defined?(::TYPE_OVERRIDES)
    declaration = typedef_defn.declaration

    case declaration
    when Xdrgen::AST::Declarations::Array
      # An array typedef becomes a wrapper struct rather than a bare Swift array, so its
      # value is constructed through that wrapper even where reference sites collapse to
      # the element array.
      element = driver.gen.pub_type_string(declaration.type)
      elements = array_expr(driver, element, declaration, depth)
      return nil unless elements

      "#{swift_name}(#{typedef_init_label(driver, swift_name)}: #{elements})"
    when Xdrgen::AST::Declarations::Opaque
      opaque_expr(driver, declaration)
    when Xdrgen::AST::Declarations::String
      string_literal
    else
      return type_expr(driver, collapsed, depth) if collapsed

      # A transparent alias carries the value of the type it names.
      type_expr(driver, driver.gen.pub_type_string(declaration.type), depth + 1)
    end
  end

  # -- Declarations -----------------------------------------------------------

  def self.field_expr(driver, type_str, declaration, optional, depth)
    case declaration
    when Xdrgen::AST::Declarations::Opaque
      return opaque_expr(driver, declaration)
    when Xdrgen::AST::Declarations::String
      return string_literal
    when Xdrgen::AST::Declarations::Array
      element = strip_optional(type_str.sub(/\A\[(.*)\]\z/m, '\1'))
      return array_expr(driver, element, declaration, depth)
    end

    swift_type = strip_optional(type_str)

    # A type table entry can store an enumeration as its raw integer. SEP-0051 renders the
    # member name regardless, so the fixture has to be a value the enumeration declares; an
    # arbitrary integer is rejected, which is the behaviour rather than a defect.
    if %w[Int32 UInt32].include?(swift_type) && (enum_defn = enum_behind(declaration.type))
      member = enum_defn.members.first
      return "#{swift_type}(#{member.value})" if member
    end

    inner = type_expr(driver, swift_type, depth)

    # An optional exercises the value path where one can be built, and the null path
    # otherwise. Both are shapes SEP-0051 renders, so neither is a gap.
    return "#{swift_type}?.none" if optional && inner.nil?

    inner
  end

  # The enumeration a declaration names, where it names one. Resolution is a single hop, so
  # a typedef over an enumeration stays distinguishable from the enumeration itself.
  def self.enum_behind(type)
    return nil unless type.is_a?(Xdrgen::AST::Typespecs::Simple)

    resolved = type.resolved_type
    resolved.is_a?(Xdrgen::AST::Definitions::Enum) ? resolved : nil
  end

  # A variable-length array carries one element, so the element conversion is exercised; it
  # degrades to empty where the element cannot be built within the depth budget, which is
  # itself a shape SEP-0051 renders. A fixed-length array must carry exactly its declared
  # count or the value re-encodes to different bytes.
  def self.array_expr(driver, element_type, declaration, depth)
    element = type_expr(driver, element_type, depth + 1)

    unless declaration.fixed?
      return '[]' if element.nil?

      return "[#{element}]"
    end

    return nil if element.nil?

    count = driver.gen.pub_resolve_size(declaration).to_i
    "[#{Array.new(count, element).join(', ')}]"
  end

  def self.opaque_expr(_driver, declaration)
    unless declaration.fixed?
      return 'Data([0x01, 0x02, 0x03])'
    end

    size = opaque_size(declaration).to_i
    if [4, 12, 16, 32].include?(size)
      "WrappedData#{size}(#{byte_data(size)})"
    else
      byte_data(size)
    end
  end

  # -- Types ------------------------------------------------------------------

  def self.type_expr(driver, type_str, depth)
    type = strip_optional(type_str.to_s.strip)
    return nil if type.empty?

    if (match = type.match(/\A\[(.+)\]\z/m))
      element = type_expr(driver, match[1], depth + 1)
      return element.nil? ? '[]' : "[#{element}]"
    end

    primitive = PRIMITIVES[type]
    return primitive if primitive

    fallback = fallback_value(type)
    return fallback if fallback

    return nil if depth > MAX_DEPTH

    info = driver.lookup(type)
    return nil unless info

    case info[:kind]
    when :enum then enum_expr(driver, info[:defn])
    when :struct then struct_expr(driver, type, info[:defn], depth + 1)
    when :union then union_expr(driver, type, info[:defn], depth + 1)
    when :typedef then typedef_expr(driver, type, info[:defn], depth + 1)
    end
  end

  def self.enum_expr(driver, enum_defn)
    member = enum_defn.members.first
    return nil unless member

    ".#{driver.gen.pub_swift_enum_case_name(enum_defn.name.to_s, member.name.to_s, enum_defn)}"
  end

  # Any arm that can be built, preferring a void one so a recursive union terminates.
  def self.union_expr(driver, swift_name, union_defn, depth)
    fallback = fallback_value(swift_name)
    return fallback if fallback
    return nil if depth > MAX_DEPTH

    discriminant = driver.gen.pub_resolve_discriminant_info(union_defn)
    entries = driver.gen.pub_build_union_case_entries(union_defn, swift_name, discriminant)
                     .reject { |entry| entry[:is_default] }

    void_entry = entries.find { |entry| entry[:decode_style] == :void }
    return ".#{void_entry[:case_name]}" if void_entry

    entries.each do |entry|
      expression = union_case_expr(driver, entry, depth)
      return expression if expression
    end
    nil
  end

  # -- Leaves -----------------------------------------------------------------

  PRIMITIVES = {
    'Int32' => 'Int32(42)',
    'UInt32' => 'UInt32(42)',
    'Int64' => 'Int64(1234567)',
    'UInt64' => 'UInt64(1234567)',
    'Bool' => 'true',
    'String' => '"test_string"',
    'Float' => 'Float(3.14)',
    'Double' => 'Double(3.14)',
    'Data' => 'Data([0x01, 0x02, 0x03])',
    'WrappedData4' => 'WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))',
    'WrappedData12' => 'WrappedData12(Data([0x55, 0x53, 0x44, 0x43, 0x54, 0x4f, ' \
                       '0x4b, 0x45, 0x4e, 0x00, 0x00, 0x00]))',
    'WrappedData16' => 'WrappedData16(Data(repeating: 0xAB, count: 16))',
    'WrappedData32' => 'WrappedData32(Data(repeating: 0xAB, count: 32))'
  }.freeze

  def self.string_literal = '"test_string"'

  def self.byte_data(size) = "Data(repeating: 0xAB, count: #{size})"

  # Types the registry walker cannot build correctly, each for a stated reason.
  #
  # Three classes: the hand-written types the generator does not emit and whose initializers
  # it therefore cannot see; the recursive anchors, where a terminal value is what stops
  # fabrication; and the strkey-rendered types, whose SEP-0051 form constrains the bytes
  # beyond what XDR requires.
  FALLBACKS = {
    # Hand-written, so the generator has no initializer to read.
    'PublicKey' => 'try PublicKey([UInt8](repeating: 0xAB, count: 32))',
    'MuxedAccountXDR' => '.ed25519([UInt8](repeating: 0xAB, count: 32))',
    'MuxedAccountMed25519XDR' =>
      'MuxedAccountMed25519XDR(id: UInt64(1), sourceAccountEd25519: ' \
      '[UInt8](repeating: 0xAB, count: 32))',
    'TransactionXDR' =>
      'TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), ' \
      'seqNum: Int64(100), cond: .none, memo: .none, operations: [], ' \
      'maxOperationFee: UInt32(100))',
    'TransactionV0XDR' =>
      'TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ' \
      'seqNum: Int64(100), timeBounds: nil, memo: .none, operations: [])',
    'TransactionV1EnvelopeXDR' =>
      'TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: ' \
      '.ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, ' \
      'memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])',
    'TransactionV0EnvelopeXDR' =>
      'TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: ' \
      'try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), ' \
      'timeBounds: nil, memo: .none, operations: []), signatures: [])',
    'FeeBumpTransactionXDR' =>
      'FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), ' \
      'innerTx: .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: ' \
      '.ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, ' \
      'memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])), ' \
      'fee: UInt64(2000))',
    'FeeBumpTransactionEnvelopeXDR' =>
      'FeeBumpTransactionEnvelopeXDR(tx: FeeBumpTransactionXDR(sourceAccount: ' \
      '.ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(TransactionV1EnvelopeXDR(' \
      'tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), ' \
      'seqNum: Int64(100), cond: .none, memo: .none, operations: [], ' \
      'maxOperationFee: UInt32(100)), signatures: [])), fee: UInt64(2000)), signatures: [])',

    # Recursive anchors: a terminal arm is what makes fabrication finite.
    'SCValXDR' => '.void',
    'ClaimPredicateXDR' => '.claimPredicateUnconditional',
    'SorobanAuthorizedInvocationXDR' =>
      'SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(' \
      'contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), ' \
      'functionName: "fn", args: [])), subInvocations: [])'
  }.freeze

  def self.fallback_value(type_name) = FALLBACKS[type_name]

  # -- Shared -----------------------------------------------------------------

  def self.apply_init_param_order(swift_name, arguments)
    return unless defined?(::INIT_PARAM_ORDER) && ::INIT_PARAM_ORDER.key?(swift_name)

    order = ::INIT_PARAM_ORDER[swift_name]
    arguments.sort_by!.with_index do |argument, index|
      [order.index(argument[:param]) || (order.length + index), index]
    end
  end

  # `size` on a fixed opaque is either a literal or an identifier naming a const.
  def self.opaque_size(declaration)
    if declaration.respond_to?(:resolved_size) && declaration.resolved_size
      return declaration.resolved_size
    end

    size = declaration.size
    return size.to_i unless size.is_a?(Xdrgen::AST::Identifier)

    raise "SEP-0051 test emitter: cannot resolve the size of #{declaration.inspect}"
  end

  def self.strip_optional(type_str) = type_str.to_s.sub(/\?\z/, '')

  # The argument label an array typedef's wrapper takes, matching what the generator emits.
  def self.typedef_init_label(driver, typedef_name)
    field_name = driver.gen.pub_resolve_field_name(typedef_name, 'wrapped')
    return ::TYPEDEF_INIT_LABEL.fetch(typedef_name, field_name) if defined?(::TYPEDEF_INIT_LABEL)

    field_name
  end
end
