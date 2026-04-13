# Swift XDR code generator for the iOS/macOS Stellar SDK.
#
# This generator is invoked by xdrgen and produces Swift structs, enums,
# and typedefs that conform to XDRCodable and Sendable.
#
# Usage:
#   ruby generate.rb
#
# The generated files are placed into stellarsdk/stellarsdk/responses/xdr/.

require 'set'
require 'xdrgen'
require_relative 'name_overrides'
require_relative 'member_overrides'
require_relative 'field_overrides'
require_relative 'type_overrides'
require_relative 'txrep_types'

AST = Xdrgen::AST

class Generator < Xdrgen::Generators::Base
  MAX_SIZE = (2**32) - 1

  # Swift reserved words that must be backtick-escaped when used as identifiers.
  SWIFT_RESERVED_WORDS = %w[
    associatedtype class deinit enum extension fileprivate func import init
    inout internal let open operator private precedencegroup protocol public
    rethrows static struct subscript typealias var
    break case catch continue default defer do else fallthrough for guard if
    in repeat return switch throw try where while
    Any catch false is nil rethrows self Self super throw throws true try
    as dynamicType
  ].freeze

  # Types that the generator must NOT produce. These are either hand-maintained
  # in the SDK, implemented as NSObject classes, contain SDK-specific convenience
  # methods, or are custom types with no direct .x file counterpart.
  SKIP_TYPES = %w[
    PublicKey
    MuxedAccountMed25519XDRInverted
    TransactionV0EnvelopeXDR
    TransactionV1EnvelopeXDR
    FeeBumpTransactionEnvelopeXDR
    TransactionXDR
    TransactionV0XDR
    FeeBumpTransactionXDR
    MuxedAccountXDR
    MuxedAccountMed25519XDR
  ].freeze

  # ---------------------------------------------------------------------------
  # Entry point -- called by xdrgen after parsing all .x files.
  # ---------------------------------------------------------------------------

  def generate
    @constants = []
    @generated_files = Set.new
    render_definitions(@top)
    render_constants_file
  end

  private

  # ---------------------------------------------------------------------------
  # Definition traversal
  # ---------------------------------------------------------------------------

  def render_definitions(node)
    node.definitions.each { |defn| render_definition(defn) }
    node.namespaces.each { |ns| render_definitions(ns) }
  end

  def render_nested_definitions(defn)
    return unless defn.respond_to?(:nested_definitions)
    defn.nested_definitions.each { |nested| render_definition(nested) }
  end

  def render_definition(defn)
    render_nested_definitions(defn)

    # Resolve the Swift type name and check the skip list.
    defn_name = name(defn)
    return if SKIP_TYPES.include?(defn_name)

    # Avoid generating the same file twice (e.g. when two XDR types map to
    # the same Swift name via NAME_OVERRIDES).
    file_key = defn_name
    unless defn.is_a?(AST::Definitions::Const)
      return if @generated_files.include?(file_key)
      @generated_files.add(file_key)
    end

    case defn
    when AST::Definitions::Struct
      render_struct(defn)
    when AST::Definitions::Enum
      render_enum(defn)
    when AST::Definitions::Union
      render_union(defn)
    when AST::Definitions::Typedef
      render_typedef(defn)
    when AST::Definitions::Const
      render_const(defn)
    end
  end

  # ---------------------------------------------------------------------------
  # Struct renderer
  # ---------------------------------------------------------------------------

  def render_struct(struct)
    struct_name = name(struct)
    out = @output.open("#{struct_name}.swift")
    render_file_header(out, struct_name)

    use_let = LET_TYPES.include?(struct_name)

    out.puts "public struct #{struct_name}: XDRCodable, Sendable {"
    out.indent do
      # -- Properties --
      struct.members.each do |m|
        field = resolve_field_name(struct_name, m.name)
        type_str = resolve_field_type(struct_name, field, m)

        if is_extension_point_field?(struct_name, field)
          out.puts "public let #{field}: Int32 = 0"
        elsif SPECIAL_FIELDS.key?(struct_name) && SPECIAL_FIELDS[struct_name].key?(field)
          spec = SPECIAL_FIELDS[struct_name][field]
          out.puts "#{spec[:visibility]} #{field}: #{type_str} = #{spec[:default]}"
        else
          keyword = use_let ? "let" : "var"
          out.puts "public #{keyword} #{field}: #{type_str}"
        end
      end
      out.break

      # -- Memberwise init --
      render_struct_init(out, struct, struct_name)
      out.break

      # -- init(from decoder:) --
      render_struct_decode(out, struct, struct_name)
      out.break

      # -- encode(to encoder:) --
      render_struct_encode(out, struct, struct_name)
    end
    out.puts "}"

    if TxRepTypes.should_generate_txrep?(self, struct_name)
      render_struct_txrep_methods(out, struct, struct_name)
    end

    out.close
  end

  # Emit the public memberwise initializer.
  def render_struct_init(out, struct, struct_name)
    # Build list of (field, param_label, type_str) for non-extension-point fields.
    init_fields = []
    struct.members.each do |m|
      field = resolve_field_name(struct_name, m.name)
      next if is_extension_point_field?(struct_name, field)
      type_str = resolve_field_type(struct_name, field, m)
      param_label = resolve_init_param_name(struct_name, field)
      init_fields << { field: field, param: param_label, type: type_str, member: m }
    end

    # Apply parameter order override if present.
    if INIT_PARAM_ORDER.key?(struct_name)
      order = INIT_PARAM_ORDER[struct_name]
      init_fields.sort_by! { |f| order.index(f[:field]) || 999 }
    end

    # Build parameter strings.
    params = init_fields.map do |f|
      is_opt = f[:member].type.sub_type == :optional || typedef_is_optional?(f[:member].declaration.type)
      # For arrays of optional elements (e.g. [PublicKey?]), the array itself
      # is not optional -- only the elements are. Don't add `= nil` default.
      is_array = f[:member].declaration.is_a?(AST::Declarations::Array)
      if is_opt && !is_array
        "#{f[:param]}: #{f[:type]} = nil"
      else
        "#{f[:param]}: #{f[:type]}"
      end
    end

    if params.length <= 2
      out.puts "public init(#{params.join(', ')}) {"
    else
      out.puts "public init("
      out.indent do
        params.each_with_index do |p, i|
          out.puts i < params.length - 1 ? "#{p}," : p
        end
      end
      out.puts ") {"
    end

    out.indent do
      init_fields.each do |f|
        out.puts "self.#{f[:field]} = #{f[:param]}"
      end
    end
    out.puts "}"
  end

  # Emit init(from decoder:) for a struct.
  def render_struct_decode(out, struct, struct_name)
    out.puts "public init(from decoder: Decoder) throws {"
    out.indent do
      # Check whether any field actually reads from the container directly.
      # Variable-length arrays use decodeArray(dec: decoder) which bypasses
      # the container, so if ALL fields are variable-length arrays the
      # container variable would be unused.
      needs_container = struct.members.any? do |m|
        field = resolve_field_name(struct_name, m.name)
        if is_extension_point_field?(struct_name, field)
          true
        else
          decl = m.declaration
          !(decl.is_a?(AST::Declarations::Array) && !decl.fixed?)
        end
      end
      if needs_container
        out.puts "var container = try decoder.unkeyedContainer()"
      end
      struct.members.each do |m|
        field = resolve_field_name(struct_name, m.name)
        if is_extension_point_field?(struct_name, field)
          out.puts "_ = try container.decode(Int32.self)"
        else
          render_decode_field(out, field, m, struct_name)
        end
      end
    end
    out.puts "}"
  end

  # Emit a single field decode statement.
  def render_decode_field(out, field, member, struct_name = nil)
    decl = member.declaration
    is_optional = member.type.sub_type == :optional
    # Also detect optional typedefs (e.g. SponsorshipDescriptor = AccountID*).
    # When a typedef wraps an optional type, the field-level sub_type is not
    # :optional, but the underlying encoding IS optional.
    unless is_optional
      is_optional = typedef_is_optional?(decl.type)
    end
    base = type_string(decl.type)

    # Apply per-field type override if present.
    if struct_name && FIELD_TYPE_OVERRIDES.key?(struct_name) &&
       FIELD_TYPE_OVERRIDES[struct_name].key?(field)
      base = FIELD_TYPE_OVERRIDES[struct_name][field]
    end

    case decl
    when AST::Declarations::Array
      if decl.fixed?
        # Fixed-length array: decode N elements in a loop.
        size = resolve_size(decl)
        inner_type = base
        out.puts "#{field} = try (0..<#{size}).map { _ in try container.decode(#{inner_type}.self) }"
      elsif is_optional
        # Variable-length array of optional elements (e.g. SponsorshipDescriptor[]):
        # each element has its own UInt32 present flag + value.
        out.puts "#{field} = try decodeArrayOfOptional(type: #{base}.self, dec: decoder)"
      else
        # Variable-length array: use decodeArray helper.
        out.puts "#{field} = try decodeArray(type: #{base}.self, dec: decoder)"
      end
    when AST::Declarations::Opaque
      if decl.fixed?
        # Fixed opaque -- type_string already returns WrappedDataN or Data.
        out.puts "#{field} = try container.decode(#{base}.self)"
      else
        # Variable opaque -- Data.
        out.puts "#{field} = try container.decode(#{base}.self)"
      end
    else
      if is_optional
        # Optional: XDR optional uses explicit flag + value pattern.
        out.puts "let #{field}Present = try container.decode(Int32.self)"
        out.puts "if #{field}Present != 0 {"
        out.indent do
          # When the override type is an array (e.g. [SCMapEntryXDR]),
          # use decodeArray to read the count prefix correctly.
          if base =~ /^\[(.+)\]$/
            inner = $1
            out.puts "#{field} = try decodeArray(type: #{inner}.self, dec: decoder)"
          else
            out.puts "#{field} = try container.decode(#{base}.self)"
          end
        end
        out.puts "} else {"
        out.indent do
          out.puts "#{field} = nil"
        end
        out.puts "}"
      else
        out.puts "#{field} = try container.decode(#{base}.self)"
      end
    end
  end

  # Emit encode(to encoder:) for a struct.
  def render_struct_encode(out, struct, struct_name)
    out.puts "public func encode(to encoder: Encoder) throws {"
    out.indent do
      out.puts "var container = encoder.unkeyedContainer()"
      struct.members.each do |m|
        field = resolve_field_name(struct_name, m.name)
        render_encode_field(out, field, m)
      end
    end
    out.puts "}"
  end

  # Emit a single field encode statement.
  def render_encode_field(out, field, member)
    decl = member.declaration
    is_optional = member.type.sub_type == :optional
    unless is_optional
      is_optional = typedef_is_optional?(decl.type)
    end

    case decl
    when AST::Declarations::Array
      if decl.fixed?
        # Fixed-length array: encode each element individually.
        out.puts "for element in #{field} { try container.encode(element) }"
      elsif is_optional
        # Variable-length array of optional elements (e.g. SponsorshipDescriptor[]):
        # each element has its own UInt32 present flag + value.
        out.puts "try encodeArrayOfOptional(#{field}, enc: encoder)"
      else
        # Variable-length array: the Array XDREncodable extension handles the count prefix.
        out.puts "try container.encode(#{field})"
      end
    else
      if is_optional
        # Optional fields must be encoded explicitly: the XDREncoder's generic
        # Optional path calls xdrEncode on the unwrapped value, which bypasses
        # the array count prefix when the underlying type is an array.
        out.puts "if let val = #{field} {"
        out.indent do
          out.puts "try container.encode(Int32(1))"
          out.puts "try container.encode(val)"
        end
        out.puts "} else {"
        out.indent do
          out.puts "try container.encode(Int32(0))"
        end
        out.puts "}"
      else
        out.puts "try container.encode(#{field})"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Enum renderer
  # ---------------------------------------------------------------------------

  def render_enum(enum_defn)
    enum_name = name(enum_defn)
    xdr_name = enum_defn.name.camelize
    out = @output.open("#{enum_name}.swift")
    render_file_header(out, enum_name)

    # Normalize member names to SCREAMING_SNAKE for consistent prefix detection.
    # XDR member names come in various formats: SCREAMING_SNAKE, CamelCase, or
    # mixed (e.g., opINNER). Normalizing via underscore().upcase() gives us a
    # consistent representation.
    raw_names = enum_defn.members.map { |m| m.name.to_s }
    normalized_names = raw_names.map { |n| n.underscore.upcase }
    prefix = detect_common_prefix(normalized_names)

    # Collected (raw_xdr_name, swift_case_name, rawValue) tuples — reused below
    # by render_enum_txrep_methods so the TxRep switch can emit the original
    # XDR SCREAMING_SNAKE constants in enumName() while referencing the
    # post-override Swift case names in the switch patterns.
    txrep_members = []

    out.puts "public enum #{enum_name}: Int32, XDRCodable, Equatable, Sendable {"
    out.indent do
      enum_defn.members.each_with_index do |m, idx|
        raw_member_name = raw_names[idx]
        normalized = normalized_names[idx]

        # Check for explicit override first.
        if MEMBER_OVERRIDES.key?(xdr_name) && MEMBER_OVERRIDES[xdr_name].key?(raw_member_name)
          case_name = MEMBER_OVERRIDES[xdr_name][raw_member_name]
        else
          # Strip common prefix from the normalized name, then convert to camelCase.
          stripped = prefix.empty? ? normalized : normalized.sub(/\A#{Regexp.escape(prefix)}/, "")
          stripped = normalized if stripped.empty?
          case_name = mechanical_camel_case(stripped)
        end

        safe_case = swift_safe_name(case_name)
        out.puts "case #{safe_case} = #{m.value}"
        txrep_members << { raw: raw_member_name, swift_case: safe_case, value: m.value }
      end
    end
    out.puts "}"

    if TxRepTypes.should_generate_txrep?(self, enum_name)
      render_enum_txrep_methods(out, enum_name, txrep_members)
    end

    out.close
  end

  # ---------------------------------------------------------------------------
  # TxRep: Enum toTxRep / fromTxRep / enumName / fromTxRepName
  # ---------------------------------------------------------------------------
  #
  # Emits four methods on an existing Swift enum declaration via an extension.
  # The generated methods participate in the SEP-0011 TxRep serialization
  # pipeline:
  #
  #   enumName()        -> original XDR SCREAMING_SNAKE constant name string
  #   fromTxRepName()   -> enum value parsed from that string (throws)
  #   toTxRep()         -> appends a "prefix: NAME" line to the output buffer
  #   fromTxRep()       -> looks up the prefix in a decoded TxRep map (throws)
  #
  # Unknown rawValues serialize as "EnumType#<rawValue>" (handled via a default
  # branch in enumName()) and parse back symmetrically in fromTxRepName().
  # Because all known cases are listed explicitly in the switch below, Swift's
  # exhaustiveness check is satisfied without a catch-all on self; the
  # default is therefore only added where the rawValue is unrecognizable,
  # which for a closed Int32-backed enum cannot happen at the Swift level.
  # The format is still honored by fromTxRepName() so that TxRep output from
  # other implementations remains round-trippable.
  def render_enum_txrep_methods(out, enum_name, members)
    out.break
    out.puts "extension #{enum_name} {"
    out.indent do
      # -- enumName() --
      out.puts "public func enumName() -> String {"
      out.indent do
        out.puts "switch self {"
        members.each do |m|
          out.puts "case .#{m[:swift_case]}: return \"#{m[:raw]}\""
        end
        out.puts "}"
      end
      out.puts "}"
      out.break

      # -- fromTxRepName(_:) --
      out.puts "public static func fromTxRepName(_ name: String) throws -> #{enum_name} {"
      out.indent do
        out.puts "switch name {"
        members.each do |m|
          out.puts "case \"#{m[:raw]}\": return .#{m[:swift_case]}"
        end
        out.puts "default:"
        out.indent do
          out.puts "let prefix = \"#{enum_name}#\""
          out.puts "if name.hasPrefix(prefix), let v = Int32(name.dropFirst(prefix.count)), let parsed = #{enum_name}(rawValue: v) {"
          out.indent do
            out.puts "return parsed"
          end
          out.puts "}"
          out.puts "throw TxRepError.invalidValue(key: name)"
        end
        out.puts "}"
      end
      out.puts "}"
      out.break

      # -- toTxRep(prefix:lines:) --
      #
      # Marked `throws` (even though an enum can't actually fail) to match
      # the struct/union toTxRep signature so call sites can delegate via
      # `try` without special-casing enum arms.
      out.puts "public func toTxRep(prefix: String, lines: inout [String]) throws {"
      out.indent do
        out.puts "lines.append(\"\\(prefix): \\(enumName())\")"
      end
      out.puts "}"
      out.break

      # -- fromTxRep(_:prefix:) --
      out.puts "public static func fromTxRep(_ map: [String: String], prefix: String) throws -> #{enum_name} {"
      out.indent do
        out.puts "guard let raw = TxRepHelper.getValue(map, prefix) else {"
        out.indent do
          out.puts "throw TxRepError.missingValue(key: prefix)"
        end
        out.puts "}"
        out.puts "return try fromTxRepName(raw)"
      end
      out.puts "}"
    end
    out.puts "}"
  end

  # ---------------------------------------------------------------------------
  # TxRep: Struct toTxRep / fromTxRep
  # ---------------------------------------------------------------------------
  #
  # Emits toTxRep(prefix:lines:) and fromTxRep(_:prefix:) on a generated struct
  # via a Swift extension block appended after the struct's primary declaration.
  # Each non-extension-point field is dispatched to the appropriate helper based
  # on a classification produced by +txrep_field_kind+:
  #
  #   :primitive     - Int32/UInt32/Int64/UInt64/Bool (raw interpolation)
  #   :string        - String (TxRepHelper.escapeString / .unescapeString)
  #   :opaque        - Data / WrappedDataN (TxRepHelper.bytesToHex / .hexToBytes)
  #   :wrapped_data  - WrappedDataN / typealias thereof (.wrapped accessor)
  #   :compact       - Types in TXREP_COMPACT_TYPES (single-line formatter)
  #   :named         - Nested XDR type (delegate to its own .toTxRep / .fromTxRep)
  #   :array         - [T] (emit .len + indexed loop)
  #
  # The Swift property accessor (self.fieldName) always uses the SDK field name
  # while the TxRep key string uses the raw XDR field name obtained via
  # +txrep_field_name+. Extension-point fields (those simplified to a constant
  # `reserved: Int32 = 0`) are skipped entirely -- they carry no payload.
  def render_struct_txrep_methods(out, struct, struct_name)
    entries = []
    struct.members.each do |m|
      field = resolve_field_name(struct_name, m.name)
      next if is_extension_point_field?(struct_name, field)

      type_str = resolve_field_type(struct_name, field, m)
      xdr_name = txrep_field_name(struct_name, field)
      kind = txrep_field_kind(m, type_str)
      entries << {
        field: field,
        xdr_name: xdr_name,
        type_str: type_str,
        kind: kind,
        member: m,
        struct_name: struct_name,
      }
    end

    out.break
    out.puts "extension #{struct_name} {"
    out.indent do
      out.puts "public func toTxRep(prefix: String, lines: inout [String]) throws {"
      out.indent do
        if entries.empty?
          out.puts "// No TxRep-serializable fields."
          out.puts "_ = prefix"
          out.puts "_ = lines"
        end
        entries.each do |e|
          txrep_emit_struct_field(out, e)
        end
      end
      out.puts "}"
      out.break

      out.puts "public static func fromTxRep(_ map: [String: String], prefix: String) throws -> #{struct_name} {"
      out.indent do
        if entries.empty?
          out.puts "_ = map"
          out.puts "_ = prefix"
          out.puts "return #{struct_name}()"
        else
          entries.each do |e|
            txrep_parse_struct_field(out, e)
          end
          # Build the call using the init parameter labels (which may differ
          # from the field name because of INIT_PARAM_OVERRIDES) in the same
          # order render_struct_init uses so we honor INIT_PARAM_ORDER.
          init_fields = entries.map do |e|
            {
              field: e[:field],
              param: resolve_init_param_name(struct_name, e[:field]),
            }
          end
          if INIT_PARAM_ORDER.key?(struct_name)
            order = INIT_PARAM_ORDER[struct_name]
            init_fields.sort_by! { |f| order.index(f[:field]) || 999 }
          end
          args = init_fields.map { |f| "#{f[:param]}: #{f[:field]}" }.join(", ")
          out.puts "return #{struct_name}(#{args})"
        end
      end
      out.puts "}"
    end
    out.puts "}"
  end

  # Classify a struct member for TxRep dispatch. Returns a Hash with at least
  # :style and additional keys that describe how to emit / parse the field.
  #
  # Styles:
  #   :primitive     :name => "Int32" | "UInt32" | "Int64" | "UInt64" | "Bool"
  #   :string
  #   :opaque        :is_data => true  (variable opaque, Data)
  #                  :wrapped_type => "WrappedData32" | nil
  #   :compact       :format, :parse  (TxRepHelper call names)
  #   :named         :name => Swift type name
  #   :array         :element => <child kind hash>, :fixed => Bool, :size => int|string
  #
  # The top-level :is_optional flag covers both field-level optionality
  # (XDR `T*`) and typedef-wrapped optionals.
  def txrep_field_kind(member, type_str)
    decl = member.declaration
    is_optional = member.type.sub_type == :optional || typedef_is_optional?(decl.type)

    # FIELD_TYPE_OVERRIDES may rewrite a typedef-backed field to a literal
    # Swift array type (e.g. SCContractInstanceXDR.storage becomes
    # [SCMapEntryXDR] even though the underlying AST decl is a typedef).
    # Detect this by inspecting the override-aware type_str first.
    overridden_inner = type_str.sub(/\?\z/, '')
    if overridden_inner =~ /\A\[(.+)\]\z/
      element_str = $1
      if element_str.end_with?("?")
        raise "TxRep: arrays of optional elements are not supported (found in field #{member.name})"
      end
      return {
        style: :array,
        element: classify_scalar(element_str),
        fixed: false,
        size: nil,
        is_optional: is_optional,
      }
    end

    # Arrays: element type string is the unwrapped Swift base.
    if decl.is_a?(AST::Declarations::Array)
      # [T] for normal arrays, [T?] for arrays of optional elements.
      # type_str already has the array brackets; strip them to get the element.
      element_str = type_str.sub(/\A\[(.*)\]\z/, '\1')
      # Remove trailing ? for optional element case -- TxRep does not use the
      # present marker for array elements; null elements are not supported
      # anywhere in the transaction envelope TxRep surface. Fail loudly if
      # encountered so the generator contract stays honest.
      if element_str.end_with?("?")
        raise "TxRep: arrays of optional elements are not supported (found in field #{member.name})"
      end
      return {
        style: :array,
        element: classify_scalar(element_str),
        fixed: decl.fixed?,
        size: decl.fixed? ? resolve_size(decl) : nil,
        is_optional: is_optional,
      }
    end

    # Fixed / variable opaque declared directly on the field (not via typedef).
    if decl.is_a?(AST::Declarations::Opaque)
      return {
        style: :opaque,
        is_data: !decl.fixed?,
        wrapped_type: (decl.fixed? && [4, 12, 16, 32].include?(decl.size.to_i)) ? "WrappedData#{decl.size.to_i}" : nil,
        is_optional: is_optional,
      }
    end

    # Typedef that ultimately wraps an opaque declaration (e.g. DataValueXDR
    # -> Data, AssetCode4XDR -> WrappedData4, HashXDR -> WrappedData32).
    if decl.type.is_a?(AST::Typespecs::Simple)
      resolved = decl.type.resolved_type
      if resolved.is_a?(AST::Definitions::Typedef)
        td_decl = resolved.declaration
        if td_decl.is_a?(AST::Declarations::Opaque)
          fixed = td_decl.fixed?
          size = fixed ? td_decl.size.to_i : nil
          wrapped_type = (fixed && [4, 12, 16, 32].include?(size)) ? "WrappedData#{size}" : nil
          return {
            style: :opaque,
            is_data: !fixed,
            wrapped_type: wrapped_type,
            is_optional: is_optional,
          }
        end
      end
    end

    # Scalar dispatch (primitives, compact types, named XDR types, String).
    kind = classify_scalar(type_str.sub(/\?\z/, ''))
    kind[:is_optional] = is_optional
    kind
  end

  # Classify a bare Swift type name (no `?`, no `[...]`) for TxRep dispatch.
  # Returns a Hash with :style plus type-specific metadata.
  def classify_scalar(base)
    # Strip any trailing ? just in case a caller forgot.
    base = base.sub(/\?\z/, '')

    if TXREP_COMPACT_TYPES.key?(base)
      return {
        style: :compact,
        name: base,
        format: TXREP_COMPACT_TYPES[base][:format],
        parse: TXREP_COMPACT_TYPES[base][:parse],
      }
    end

    case base
    when "Int32", "UInt32", "Int64", "UInt64", "Bool"
      return { style: :primitive, name: base }
    when "String"
      return { style: :string }
    when "Data"
      return { style: :opaque, is_data: true, wrapped_type: nil }
    when /\AWrappedData(\d+)\z/
      return { style: :opaque, is_data: false, wrapped_type: base }
    else
      return { style: :named, name: base }
    end
  end

  # Direct access to TXREP_COMPACT_TYPES via the module constant. Needed
  # because +classify_scalar+ is called from both the struct and (future)
  # union TxRep renderers.
  TXREP_COMPACT_TYPES = TxRepTypes::TXREP_COMPACT_TYPES
  UNION_ARM_FIELD_OVERRIDES = TxRepTypes::UNION_ARM_FIELD_OVERRIDES

  # Emit Swift code that appends one field's TxRep line(s) to `lines`.
  def txrep_emit_struct_field(out, entry)
    field = entry[:field]
    xdr_name = entry[:xdr_name]
    kind = entry[:kind]
    accessor = "self.#{field}"

    if kind[:is_optional]
      out.puts "if let val = #{accessor} {"
      out.indent do
        out.puts "lines.append(\"\\(prefix).#{xdr_name}._present: true\")"
        # Inside the optional block the field prefix is a plain string literal
        # interpolating the outer prefix plus the xdr name.
        txrep_emit_value(out, kind, "val", "\\(prefix).#{xdr_name}")
      end
      out.puts "} else {"
      out.indent do
        out.puts "lines.append(\"\\(prefix).#{xdr_name}._present: false\")"
      end
      out.puts "}"
      return
    end

    txrep_emit_value(out, kind, accessor, "\\(prefix).#{xdr_name}")
  end

  # Emit Swift code for a value whose kind is `kind`, accessed via `accessor`,
  # under the TxRep prefix fragment `prefix_frag` (a Swift string literal
  # fragment suitable for embedding inside `"..."`, e.g. `\(prefix).foo`).
  def txrep_emit_value(out, kind, accessor, prefix_frag)
    case kind[:style]
    when :primitive
      out.puts "lines.append(\"#{prefix_frag}: \\(#{accessor})\")"
    when :string
      out.puts "lines.append(\"#{prefix_frag}: \\(TxRepHelper.escapeString(#{accessor}))\")"
    when :opaque
      if kind[:wrapped_type]
        out.puts "lines.append(\"#{prefix_frag}: \\(TxRepHelper.bytesToHex(#{accessor}.wrapped))\")"
      else
        out.puts "lines.append(\"#{prefix_frag}: \\(TxRepHelper.bytesToHex(#{accessor}))\")"
      end
    when :compact
      # Several format helpers (formatMuxedAccount, formatSignerKey, ...)
      # throw on malformed input; mark all compact calls `try` uniformly so
      # the struct toTxRep signature can be declared `throws`.
      out.puts "lines.append(\"#{prefix_frag}: \\(try #{kind[:format]}(#{accessor}))\")"
    when :named
      out.puts "try #{accessor}.toTxRep(prefix: \"#{prefix_frag}\", lines: &lines)"
    when :array
      # Emit .len (only for variable-length arrays) then loop.
      if !kind[:fixed]
        out.puts "lines.append(\"#{prefix_frag}.len: \\(#{accessor}.count)\")"
      end
      out.puts "for (i, item) in #{accessor}.enumerated() {"
      out.indent do
        elem_prefix = "#{prefix_frag}[\\(i)]"
        txrep_emit_value(out, kind[:element], "item", elem_prefix)
      end
      out.puts "}"
    else
      raise "unhandled txrep style: #{kind[:style].inspect}"
    end
  end

  # Emit Swift code that parses one field from the map and declares a local
  # variable named `field` holding the value. This keeps the parse site
  # symmetric with txrep_emit_struct_field and lets +render_struct_txrep_methods+
  # build the final init call by listing the locals in INIT_PARAM_ORDER.
  def txrep_parse_struct_field(out, entry)
    field = entry[:field]
    xdr_name = entry[:xdr_name]
    kind = entry[:kind]
    type_str = entry[:type_str]

    prefix_lit = "\"\\(prefix).#{xdr_name}\""

    if kind[:is_optional]
      inner_type = type_str.sub(/\?\z/, '')
      out.puts "let #{field}: #{inner_type}?"
      out.puts "if TxRepHelper.getValue(map, \"\\(prefix).#{xdr_name}._present\") == \"true\" {"
      out.indent do
        if kind[:style] == :array
          # Expand the array parse inline so the result can be assigned to
          # the optional local. Uses the same loop shape as the non-optional
          # path but declares a tmp var then assigns.
          tmp = "#{field}Tmp"
          element_type = inner_type.sub(/\A\[(.*)\]\z/, '\1')
          out.puts "let #{tmp}Len = try TxRepHelper.parseInt(TxRepHelper.getValue(map, \"\\(prefix).#{xdr_name}.len\") ?? \"0\")"
          out.puts "var #{tmp} = [#{element_type}]()"
          out.puts "for i in 0..<Int(#{tmp}Len) {"
          out.indent do
            elem_prefix = "\"\\(prefix).#{xdr_name}[\\(i)]\""
            out.puts "let item: #{element_type} = #{txrep_parse_expr(kind[:element], elem_prefix)}"
            out.puts "#{tmp}.append(item)"
          end
          out.puts "}"
          out.puts "#{field} = #{tmp}"
        else
          out.puts "#{field} = #{txrep_parse_expr(kind, prefix_lit)}"
        end
      end
      out.puts "} else {"
      out.indent do
        out.puts "#{field} = nil"
      end
      out.puts "}"
      return
    end

    if kind[:style] == :array
      txrep_parse_array_field(out, field, kind, xdr_name, type_str)
      return
    end

    # Required non-optional scalar fields: use require* helpers for opaque,
    # compact, and string styles so that a missing key throws missingValue and
    # an invalid value throws invalidValue with the field key (not the raw value).
    req = %i[opaque compact string].include?(kind[:style])

    # Special case: liquidity pool ID fields accept both 64-char hex AND L-address
    # StrKey input. Override the generated parse expression for these specific fields.
    struct_name = entry[:struct_name]
    if TxRepTypes::TXREP_LIQUIDITY_POOL_ID_FIELDS.include?([struct_name, field])
      out.puts "let #{field}: #{type_str} = try TxRepHelper.requireLiquidityPoolId(map, \"\\(prefix).#{xdr_name}\")"
      return
    end

    out.puts "let #{field}: #{type_str} = #{txrep_parse_expr(kind, prefix_lit, required: req)}"
  end

  # Emit Swift code that parses a (possibly nested) array field, declaring
  # `field` as the result. Array element optionality is rejected upstream.
  def txrep_parse_array_field(out, field, kind, xdr_name, type_str)
    element = kind[:element]
    # Element Swift type -- extract from type_str, which is "[T]".
    element_type = type_str.sub(/\A\[(.*)\]\z/, '\1')

    if kind[:fixed]
      out.puts "var #{field} = [#{element_type}]()"
      out.puts "for i in 0..<#{kind[:size]} {"
    else
      out.puts "let #{field}Len = try TxRepHelper.parseInt(TxRepHelper.getValue(map, \"\\(prefix).#{xdr_name}.len\") ?? \"0\")"
      out.puts "var #{field} = [#{element_type}]()"
      out.puts "for i in 0..<Int(#{field}Len) {"
    end
    out.indent do
      elem_prefix = "\"\\(prefix).#{xdr_name}[\\(i)]\""
      out.puts "let item: #{element_type} = #{txrep_parse_expr(element, elem_prefix)}"
      out.puts "#{field}.append(item)"
    end
    out.puts "}"
  end

  # Map from compact-type parse method -> require method on TxRepHelper.
  # When required: true, the generator emits a require* call that throws
  # missingValue when the key is absent and invalidValue (with the field key,
  # not the raw value) when the conversion fails.
  COMPACT_PARSE_TO_REQUIRE = {
    'TxRepHelper.parseAccountId'       => 'TxRepHelper.requireAccountId',
    'TxRepHelper.parseAllowTrustAsset' => 'TxRepHelper.requireAllowTrustAsset',
    'TxRepHelper.parseAsset'           => 'TxRepHelper.requireAsset',
    'TxRepHelper.parseMuxedAccount'    => 'TxRepHelper.requireMuxedAccount',
    'TxRepHelper.parseSignerKey'       => 'TxRepHelper.requireSignerKey',
  }.freeze

  # Return a Swift expression string that parses a single scalar (non-array)
  # value of the given kind from the map at the given prefix expression.
  #
  # When required is true, opaque and compact types use the TxRepHelper.require*
  # family of helpers that throw TxRepError.missingValue when the key is absent
  # and TxRepError.invalidValue (keyed on the field name, not the raw value)
  # when the conversion fails.  This matches the behaviour expected by the error-
  # handling regression tests.  Primitive types always use the ?? default form
  # because there is no way to distinguish "explicitly set to 0" from "absent".
  def txrep_parse_expr(kind, prefix_expr, required: false)
    case kind[:style]
    when :primitive
      case kind[:name]
      when "Int32"
        "try TxRepHelper.parseInt(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"0\")"
      when "UInt32"
        "UInt32(try TxRepHelper.parseUInt64(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"0\"))"
      when "Int64"
        "try TxRepHelper.parseInt64(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"0\")"
      when "UInt64"
        "try TxRepHelper.parseUInt64(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"0\")"
      when "Bool"
        "(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"false\") == \"true\""
      end
    when :string
      if required
        "try TxRepHelper.requireString(map, #{prefix_expr})"
      else
        "try TxRepHelper.unescapeString(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"\")"
      end
    when :opaque
      if required
        if kind[:wrapped_type]
          "try TxRepHelper.require#{kind[:wrapped_type]}(map, #{prefix_expr})"
        else
          "try TxRepHelper.requireHex(map, #{prefix_expr})"
        end
      else
        if kind[:wrapped_type]
          "#{kind[:wrapped_type]}(try TxRepHelper.hexToBytes(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"\"))"
        else
          "try TxRepHelper.hexToBytes(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"\")"
        end
      end
    when :compact
      if required
        req_method = COMPACT_PARSE_TO_REQUIRE[kind[:parse]]
        if req_method
          "try #{req_method}(map, #{prefix_expr})"
        else
          # Fallback: unknown compact type — use old pattern.
          "try #{kind[:parse]}(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"\")"
        end
      else
        "try #{kind[:parse]}(TxRepHelper.getValue(map, #{prefix_expr}) ?? \"\")"
      end
    when :named
      "try #{kind[:name]}.fromTxRep(map, prefix: #{prefix_expr})"
    else
      raise "unhandled txrep parse style: #{kind[:style].inspect}"
    end
  end

  # ---------------------------------------------------------------------------
  # Union renderer
  # ---------------------------------------------------------------------------

  # Types that require `indirect enum` because they reference themselves
  # recursively in their arm types.
  INDIRECT_UNION_TYPES = %w[ClaimPredicateXDR SCSpecTypeDefXDR SCValXDR].freeze

  def render_union(union)
    union_name = name(union)
    out = @output.open("#{union_name}.swift")
    render_file_header(out, union_name)

    # Determine the discriminant information.
    disc_info = resolve_discriminant_info(union)

    # Build the list of (swift_case_name, associated_type_or_nil, disc_expression) tuples.
    # Each tuple corresponds to one Swift enum case.
    case_entries = build_union_case_entries(union, union_name, disc_info)

    indirect = INDIRECT_UNION_TYPES.include?(union_name) ? "indirect " : ""
    out.puts "public #{indirect}enum #{union_name}: XDRCodable, Sendable {"

    out.indent do
      # -- Enum cases --
      case_entries.each do |entry|
        if entry[:associated_type]
          out.puts "case #{swift_safe_name(entry[:case_name])}(#{entry[:associated_type]})"
        else
          out.puts "case #{swift_safe_name(entry[:case_name])}"
        end
      end
      out.break

      # -- init(from decoder:) --
      render_union_decode(out, union_name, case_entries, disc_info)
      out.break

      # -- type() -> Int32 --
      render_union_type_func(out, case_entries, disc_info)
      out.break

      # -- encode(to encoder:) --
      render_union_encode(out, case_entries)
    end
    out.puts "}"

    # Phase 6: TxRep methods for TXREP_UNION_SKIP types are hand-written in
    # stellarsdk/stellarsdk/txrep/extensions/. The generator emits nothing for
    # those types so there is no duplicate-extension conflict.
    if TxRepTypes.should_generate_txrep?(self, union_name)
      unless TxRepTypes::TXREP_UNION_SKIP.include?(union_name)
        render_union_txrep_methods(out, union_name, case_entries, disc_info)
      end
    end

    out.close
  end

  # ---------------------------------------------------------------------------
  # TxRep: Union toTxRep / fromTxRep
  # ---------------------------------------------------------------------------
  #
  # Emits toTxRep(prefix:lines:) and fromTxRep(_:prefix:) on a generated
  # union (Swift enum with associated values) via a trailing extension block.
  #
  # The discriminant line is written as "prefix.<field>: <RAW_NAME>" where
  #   <field>    is the XDR discriminant field name (type, v, code, kind...)
  #   <RAW_NAME> is the original XDR constant (SCREAMING_SNAKE) the other
  #              SEP-0011 implementations use.
  #
  # Each arm then:
  #   - void        emits nothing after the discriminant
  #   - named       delegates to the inner type's toTxRep, using the XDR arm
  #                 name as the key suffix (NOT the Swift case name, which may
  #                 have been rewritten via MEMBER_OVERRIDES)
  #   - scalar      emits a single compact line via txrep_emit_value
  #   - array       emits .len + indexed loop via the shared helper
  #   - optional    emits ._present + value
  #
  # Per-arm field overrides (UNION_ARM_FIELD_OVERRIDES, keyed by [union_xdr_name,
  # arm_xdr_name]) suppress the delegating call and inline-emit the nested
  # struct's fields so that TxRep keys differ from the canonical XDR field
  # names. This is the only way to honor the historical hand-written TxRep
  # surface (see ManageBuyOfferOp.amount -> buyAmount, etc.) without polluting
  # the struct's own TxRep method.
  def render_union_txrep_methods(out, union_name, case_entries, disc_info)
    disc_field = disc_info[:field_name]
    union_xdr_name = raw_xdr_name_for_union(union_name, disc_info)

    out.break
    out.puts "extension #{union_name} {"
    out.indent do
      # -- toTxRep(prefix:lines:) ---------------------------------------
      out.puts "public func toTxRep(prefix: String, lines: inout [String]) throws {"
      out.indent do
        out.puts "switch self {"
        case_entries.each do |entry|
          render_union_txrep_to_case(out, entry, disc_field, union_xdr_name)
        end
        out.puts "}"
      end
      out.puts "}"
      out.break

      # -- fromTxRep(_:prefix:) -----------------------------------------
      out.puts "public static func fromTxRep(_ map: [String: String], prefix: String) throws -> #{union_name} {"
      out.indent do
        out.puts "let discKey = \"\\(prefix).#{disc_field}\""
        out.puts "guard let discName = TxRepHelper.getValue(map, discKey) else {"
        out.indent do
          out.puts "throw TxRepError.missingValue(key: discKey)"
        end
        out.puts "}"
        out.puts "switch discName {"
        case_entries.each do |entry|
          render_union_txrep_from_case(out, entry, union_name, union_xdr_name)
        end
        out.puts "default:"
        out.indent do
          out.puts "throw TxRepError.invalidValue(key: discKey)"
        end
        out.puts "}"
      end
      out.puts "}"
    end
    out.puts "}"
  end

  # Best-effort: the XDR-side name of the union, used to look up entries in
  # UNION_ARM_FIELD_OVERRIDES. For nested unions (OperationBody) this is the
  # canonical parent-chain name. Since Phase 4 only has overrides on
  # OperationBody, a simple name-stripping reversal is sufficient.
  def raw_xdr_name_for_union(union_name, _disc_info)
    # The Swift name always has "XDR" appended via NAME_OVERRIDES. Strip it.
    union_name.sub(/XDR\z/, "")
  end

  # Emit one `case .name...:` block for toTxRep.
  def render_union_txrep_to_case(out, entry, disc_field, union_xdr_name)
    swift_case = swift_safe_name(entry[:case_name])
    raw_disc = entry[:raw_disc_names].first

    if entry[:decode_style] == :void
      out.puts "case .#{swift_case}:"
      out.indent do
        out.puts "lines.append(\"\\(prefix).#{disc_field}: #{raw_disc}\")"
      end
      return
    end

    out.puts "case .#{swift_case}(let val):"
    out.indent do
      out.puts "lines.append(\"\\(prefix).#{disc_field}: #{raw_disc}\")"

      xdr_arm = entry[:xdr_arm_name]
      overrides = UNION_ARM_FIELD_OVERRIDES[[union_xdr_name, xdr_arm]]

      if overrides && entry[:decode_style] == :simple
        # Inline-emit the nested struct's fields, honoring the per-arm
        # field-name override. Skip the pristine struct toTxRep call.
        emit_union_arm_with_overrides(out, entry, xdr_arm, overrides)
      elsif entry[:decode_style] == :optional
        kind = union_arm_txrep_kind(entry)
        out.puts "if let inner = val {"
        out.indent do
          out.puts "lines.append(\"\\(prefix).#{xdr_arm}._present: true\")"
          txrep_emit_value(out, kind, "inner", "\\(prefix).#{xdr_arm}")
        end
        out.puts "} else {"
        out.indent do
          out.puts "lines.append(\"\\(prefix).#{xdr_arm}._present: false\")"
        end
        out.puts "}"
      else
        kind = union_arm_txrep_kind(entry)
        txrep_emit_value(out, kind, "val", "\\(prefix).#{xdr_arm}")
      end
    end
  end

  # Emit one `case "CONST":` block for fromTxRep.
  def render_union_txrep_from_case(out, entry, union_name, union_xdr_name)
    swift_case = swift_safe_name(entry[:case_name])

    entry[:raw_disc_names].each do |raw|
      out.puts "case \"#{raw}\":"
    end
    if entry[:decode_style] == :void
      out.indent do
        out.puts "return .#{swift_case}"
      end
      return
    end

    out.indent do
      xdr_arm = entry[:xdr_arm_name]
      overrides = UNION_ARM_FIELD_OVERRIDES[[union_xdr_name, xdr_arm]]

      if overrides && entry[:decode_style] == :simple
        parse_union_arm_with_overrides(out, entry, xdr_arm, overrides, swift_case)
      else
        kind = union_arm_txrep_kind(entry)
        prefix_expr = "\"\\(prefix).#{xdr_arm}\""

        if entry[:decode_style] == :array
          element_type = entry[:decode_type]
          out.puts "let valLen = try TxRepHelper.parseInt(TxRepHelper.getValue(map, \"\\(prefix).#{xdr_arm}.len\") ?? \"0\")"
          out.puts "var val = [#{element_type}]()"
          out.puts "for i in 0..<Int(valLen) {"
          out.indent do
            elem_prefix = "\"\\(prefix).#{xdr_arm}[\\(i)]\""
            out.puts "let item: #{element_type} = #{txrep_parse_expr(kind[:element], elem_prefix)}"
            out.puts "val.append(item)"
          end
          out.puts "}"
          out.puts "return .#{swift_case}(val)"
        elsif entry[:decode_style] == :optional
          inner_type = entry[:decode_type]
          out.puts "if TxRepHelper.getValue(map, \"\\(prefix).#{xdr_arm}._present\") == \"true\" {"
          out.indent do
            if kind[:style] == :array
              element_type = inner_type.sub(/\A\[(.*)\]\z/, '\1')
              out.puts "let valLen = try TxRepHelper.parseInt(TxRepHelper.getValue(map, \"\\(prefix).#{xdr_arm}.len\") ?? \"0\")"
              out.puts "var val = [#{element_type}]()"
              out.puts "for i in 0..<Int(valLen) {"
              out.indent do
                elem_prefix = "\"\\(prefix).#{xdr_arm}[\\(i)]\""
                out.puts "let item: #{element_type} = #{txrep_parse_expr(kind[:element], elem_prefix)}"
                out.puts "val.append(item)"
              end
              out.puts "}"
              out.puts "return .#{swift_case}(val)"
            else
              out.puts "let val: #{inner_type} = #{txrep_parse_expr(kind, prefix_expr)}"
              out.puts "return .#{swift_case}(val)"
            end
          end
          out.puts "} else {"
          out.indent do
            out.puts "return .#{swift_case}(nil)"
          end
          out.puts "}"
        else
          # Special case: liquidity pool ID union arms accept both 64-char hex AND
          # L-address StrKey input. Override for these specific [union, arm] pairs.
          if TxRepTypes::TXREP_LIQUIDITY_POOL_ID_FIELDS.include?([union_name, xdr_arm])
            out.puts "let val: WrappedData32 = try TxRepHelper.requireLiquidityPoolId(map, #{prefix_expr})"
            out.puts "return .#{swift_case}(val)"
          else
            # Union arm required scalar: use require* helpers for opaque/compact/string.
            arm_req = %i[opaque compact string].include?(kind[:style])
            out.puts "let val = #{txrep_parse_expr(kind, prefix_expr, required: arm_req)}"
            out.puts "return .#{swift_case}(val)"
          end
        end
      end
    end
  end

  # Classify a union arm's associated type for TxRep emission. Mirrors
  # txrep_field_kind but works off the arm metadata already gathered in
  # build_union_case_entries.
  def union_arm_txrep_kind(entry)
    arm = entry[:arm_ast]
    decl = arm.declaration
    base_kind =
      case entry[:decode_style]
      when :simple
        classify_arm_scalar(decl, entry[:decode_type])
      when :array
        {
          style: :array,
          element: classify_arm_scalar(decl, entry[:decode_type]),
          fixed: decl.is_a?(AST::Declarations::Array) && decl.fixed?,
          size: nil,
        }
      when :optional
        # Optional union arms decode via the explicit _present flag. Return
        # the inner kind; callers wrap it in the if/else themselves.
        classify_arm_scalar(decl, entry[:decode_type])
      else
        raise "union_arm_txrep_kind: unexpected decode_style #{entry[:decode_style].inspect}"
      end
    base_kind
  end

  # Classify an arm declaration's innermost scalar type, honoring the same
  # typedef-to-opaque chase that txrep_field_kind performs for struct members.
  # Falls back to classify_scalar for non-opaque leaf types.
  def classify_arm_scalar(decl, swift_type)
    # Direct opaque arm (rare): declared as `opaque foo[N]` inside a union.
    if decl.is_a?(AST::Declarations::Opaque)
      return {
        style: :opaque,
        is_data: !decl.fixed?,
        wrapped_type: (decl.fixed? && [4, 12, 16, 32].include?(decl.size.to_i)) ? "WrappedData#{decl.size.to_i}" : nil,
      }
    end

    # Typedef resolution: HashXDR -> WrappedData32, DataValueXDR -> Data, etc.
    tspec =
      case decl
      when AST::Declarations::Array, AST::Declarations::Optional
        decl.type
      else
        decl.respond_to?(:type) ? decl.type : nil
      end

    if tspec.is_a?(AST::Typespecs::Simple) && tspec.respond_to?(:resolved_type)
      resolved = tspec.resolved_type
      if resolved.is_a?(AST::Definitions::Typedef)
        td_decl = resolved.declaration
        if td_decl.is_a?(AST::Declarations::Opaque)
          fixed = td_decl.fixed?
          size = fixed ? td_decl.size.to_i : nil
          wrapped_type = (fixed && [4, 12, 16, 32].include?(size)) ? "WrappedData#{size}" : nil
          return {
            style: :opaque,
            is_data: !fixed,
            wrapped_type: wrapped_type,
          }
        end
      end
    end

    # Typedef-wrapped array arms (e.g. SCVec = SCVal<>): the resolved Swift
    # type is [T] even though the arm declaration is a single Typespec::Simple.
    # Detect by inspecting the rendered swift_type directly; the element type
    # string is whatever sits between the brackets.
    if swift_type =~ /\A\[(.+)\]\z/
      element_str = $1
      return {
        style: :array,
        element: classify_scalar(element_str),
        fixed: false,
        size: nil,
      }
    end

    classify_scalar(swift_type)
  end

  # Inline-emit the struct's fields for a union arm that has UNION_ARM_FIELD
  # overrides. The nested struct is reachable via the arm AST's decl type.
  # Some arms share a Swift type with a sibling (e.g., ManageBuyOfferOp and
  # ManageSellOfferOp both collapse to ManageOfferOperationXDR via
  # NAME_OVERRIDES); walk the AST for the struct whose name() resolves to the
  # same Swift name as the arm's decode type so the inline emission honors
  # the rendered struct's field names rather than the per-arm struct's.
  def emit_union_arm_with_overrides(out, entry, xdr_arm, overrides)
    struct_defn = find_struct_defn_for_swift_name(entry[:decode_type]) ||
                  resolve_union_arm_struct_defn(entry[:arm_ast])
    struct_name = name(struct_defn)

    struct_defn.members.each do |m|
      field = resolve_field_name(struct_name, m.name)
      next if is_extension_point_field?(struct_name, field)

      type_str = resolve_field_type(struct_name, field, m)
      kind = txrep_field_kind(m, type_str)

      # Resolve the TxRep key suffix: start from the struct-level XDR field
      # name, then apply the per-arm override if one is present.
      key_suffix = txrep_field_name(struct_name, field)
      if overrides.key?(key_suffix)
        key_suffix = overrides[key_suffix]
      elsif overrides.key?(field)
        key_suffix = overrides[field]
      end

      # Reuse txrep_emit_struct_field logic but with a synthetic xdr_name.
      accessor = "val.#{field}"
      if kind[:is_optional]
        out.puts "if let inner = #{accessor} {"
        out.indent do
          out.puts "lines.append(\"\\(prefix).#{xdr_arm}.#{key_suffix}._present: true\")"
          txrep_emit_value(out, kind, "inner", "\\(prefix).#{xdr_arm}.#{key_suffix}")
        end
        out.puts "} else {"
        out.indent do
          out.puts "lines.append(\"\\(prefix).#{xdr_arm}.#{key_suffix}._present: false\")"
        end
        out.puts "}"
      else
        txrep_emit_value(out, kind, accessor, "\\(prefix).#{xdr_arm}.#{key_suffix}")
      end
    end
  end

  # Symmetric parse for per-arm-override arms. Builds locals for each field
  # then constructs the nested struct via its generated initializer.
  def parse_union_arm_with_overrides(out, entry, xdr_arm, overrides, swift_case)
    struct_defn = find_struct_defn_for_swift_name(entry[:decode_type]) ||
                  resolve_union_arm_struct_defn(entry[:arm_ast])
    struct_name = name(struct_defn)

    fields_info = []
    struct_defn.members.each do |m|
      field = resolve_field_name(struct_name, m.name)
      next if is_extension_point_field?(struct_name, field)
      type_str = resolve_field_type(struct_name, field, m)
      kind = txrep_field_kind(m, type_str)

      key_suffix = txrep_field_name(struct_name, field)
      if overrides.key?(key_suffix)
        key_suffix = overrides[key_suffix]
      elsif overrides.key?(field)
        key_suffix = overrides[field]
      end

      fields_info << { field: field, key_suffix: key_suffix, kind: kind, type_str: type_str }
    end

    fields_info.each do |f|
      field = f[:field]
      kind = f[:kind]
      type_str = f[:type_str]
      key_suffix = f[:key_suffix]
      prefix_lit = "\"\\(prefix).#{xdr_arm}.#{key_suffix}\""

      if kind[:is_optional]
        inner_type = type_str.sub(/\?\z/, '')
        out.puts "let #{field}: #{inner_type}?"
        out.puts "if TxRepHelper.getValue(map, \"\\(prefix).#{xdr_arm}.#{key_suffix}._present\") == \"true\" {"
        out.indent do
          out.puts "#{field} = #{txrep_parse_expr(kind, prefix_lit)}"
        end
        out.puts "} else {"
        out.indent do
          out.puts "#{field} = nil"
        end
        out.puts "}"
      elsif kind[:style] == :array
        element_type = type_str.sub(/\A\[(.*)\]\z/, '\1')
        out.puts "let #{field}Len = try TxRepHelper.parseInt(TxRepHelper.getValue(map, \"\\(prefix).#{xdr_arm}.#{key_suffix}.len\") ?? \"0\")"
        out.puts "var #{field} = [#{element_type}]()"
        out.puts "for i in 0..<Int(#{field}Len) {"
        out.indent do
          elem_prefix = "\"\\(prefix).#{xdr_arm}.#{key_suffix}[\\(i)]\""
          out.puts "let item: #{element_type} = #{txrep_parse_expr(kind[:element], elem_prefix)}"
          out.puts "#{field}.append(item)"
        end
        out.puts "}"
      else
        # Required non-optional scalar: use require* helpers for opaque, compact, and
        # string styles so that a missing key throws missingValue(key: <fieldKey>) and
        # an invalid value throws invalidValue(key: <fieldKey>) — not invalidValue(key: "").
        req = %i[opaque compact string].include?(kind[:style])
        out.puts "let #{field}: #{type_str} = #{txrep_parse_expr(kind, prefix_lit, required: req)}"
      end
    end

    # Build the init call mirroring render_struct_txrep_methods.
    init_fields = fields_info.map do |f|
      {
        field: f[:field],
        param: resolve_init_param_name(struct_name, f[:field]),
      }
    end
    if INIT_PARAM_ORDER.key?(struct_name)
      order = INIT_PARAM_ORDER[struct_name]
      init_fields.sort_by! { |g| order.index(g[:field]) || 999 }
    end
    args = init_fields.map { |g| "#{g[:param]}: #{g[:field]}" }.join(", ")
    out.puts "let val = #{struct_name}(#{args})"
    out.puts "return .#{swift_case}(val)"
  end

  # Walk the top-level AST and return the first struct definition whose
  # resolved Swift name matches +swift_name+. Used by the per-arm override
  # codegen to locate the rendered struct (which may be a NAME_OVERRIDES
  # collapse target shared by multiple XDR structs) rather than the arm's
  # per-arm XDR struct.
  def find_struct_defn_for_swift_name(swift_name)
    @struct_defn_by_swift_name_cache ||= begin
      cache = {}
      walk_definitions(@top) do |defn|
        next unless defn.is_a?(AST::Definitions::Struct)
        begin
          resolved = name(defn)
        rescue StandardError
          next
        end
        cache[resolved] ||= defn
      end
      cache
    end
    @struct_defn_by_swift_name_cache[swift_name]
  end

  def walk_definitions(node, &block)
    return if node.nil?
    if node.respond_to?(:definitions)
      node.definitions.each do |defn|
        yield defn
        walk_nested(defn, &block)
      end
    end
    if node.respond_to?(:namespaces)
      node.namespaces.each { |ns| walk_definitions(ns, &block) }
    end
  end

  def walk_nested(defn, &block)
    return unless defn.respond_to?(:nested_definitions)
    defn.nested_definitions.each do |nested|
      yield nested
      walk_nested(nested, &block)
    end
  end

  # Given a non-void union arm AST, return the Struct (or Union) AST defn
  # the arm's type references. Handles typedef indirection.
  def resolve_union_arm_struct_defn(arm)
    decl = arm.declaration
    tspec = decl.type
    resolved = tspec.respond_to?(:resolved_type) ? tspec.resolved_type : nil
    # Typedef -> chase to the underlying struct.
    while resolved.is_a?(AST::Definitions::Typedef)
      inner = resolved.declaration
      return resolved unless inner.type.respond_to?(:resolved_type)
      resolved = inner.type.resolved_type
    end
    resolved
  end

  # Temporary extension used for Phase 6-skipped unions (TransactionEnvelopeXDR).
  # Resolve discriminant metadata: whether it's an enum, a SKIP_TYPES
  # struct-with-constants, or a plain integer.
  #
  # Returns a hash with:
  #   :kind        - :enum, :skip_type_struct, or :int
  #   :swift_name  - The Swift type name for the discriminant type (or nil for :int)
  #   :xdr_name    - The XDR canonical name (for looking up MEMBER_OVERRIDES)
  #   :field_name  - The XDR discriminant field name (e.g., "type", "v", "code", "kind")
  def resolve_discriminant_info(union)
    dtype = union.discriminant.type
    disc_field_name = union.discriminant.name.to_s

    if dtype.respond_to?(:resolved_type)
      resolved = dtype.resolved_type
      if resolved.is_a?(AST::Definitions::Enum)
        xdr_name = resolved.name.camelize
        swift_name = name(resolved)

        if SKIP_TYPES.include?(swift_name)
          return { kind: :skip_type_struct, swift_name: swift_name, xdr_name: xdr_name, enum_defn: resolved, field_name: disc_field_name }
        else
          return { kind: :enum, swift_name: swift_name, xdr_name: xdr_name, enum_defn: resolved, field_name: disc_field_name }
        end
      end
    end

    # Integer discriminant (e.g., `int v` for extension unions).
    { kind: :int, swift_name: nil, xdr_name: nil, enum_defn: nil, field_name: disc_field_name }
  end

  # Reverse lookup: given an SDK Swift field name, return the original XDR
  # field name as defined in the .x file. Used by TxRep rendering where
  # the XDR canonical name is required for key generation.
  def txrep_field_name(struct_name, swift_field_name)
    overrides = FIELD_OVERRIDES[struct_name]
    return swift_field_name unless overrides
    overrides.each do |xdr_name, sdk_name|
      return xdr_name if sdk_name == swift_field_name
    end
    swift_field_name
  end

  # Build an array of case entry hashes for the union.
  #
  # Each entry has:
  #   :case_name       - The Swift enum case name (String)
  #   :associated_type - The Swift type string for the associated value, or nil for void
  #   :disc_expressions - Array of discriminant match expressions for decode switch
  #   :disc_return      - The expression to return from the type() method
  #   :decode_style    - :simple, :array, :optional, :void
  #   :decode_type     - The Swift type to decode (for non-void arms)
  def build_union_case_entries(union, union_name, disc_info)
    entries = []
    seen_case_names = Set.new

    union.normal_arms.each do |arm|
      # The raw XDR arm variable name (pre-override), used by TxRep key
      # generation. Void arms carry no payload so this is nil for them.
      xdr_arm_name = arm.void? ? nil : arm.name.to_s

      if arm.void?
        # For void arms with multiple cases, each case becomes its own Swift enum case.
        arm.cases.each do |c|
          case_name = swift_case_name_for_discriminant_value(c.value, disc_info)
          # Apply union-level arm name override if present (e.g. MemoXDR "MEMO_TYPE_NONE" => "none").
          if MEMBER_OVERRIDES.key?(union_name) && MEMBER_OVERRIDES[union_name].key?(case_name)
            case_name = MEMBER_OVERRIDES[union_name][case_name]
          end
          next if seen_case_names.include?(case_name)
          seen_case_names.add(case_name)

          entries << {
            case_name: case_name,
            associated_type: nil,
            disc_expressions: [disc_match_expression(c.value, disc_info)],
            disc_return: disc_return_expression(c.value, disc_info),
            decode_style: :void,
            decode_type: nil,
            xdr_arm_name: nil,
            raw_disc_names: [txrep_raw_disc_name(c.value, disc_info)],
            arm_ast: arm,
          }
        end
      else
        # Determine the associated type and decode style (shared by all cases in this arm).
        assoc_type, decode_style = resolve_arm_type(arm)
        decode_type = resolve_arm_decode_type(arm)

        if arm.cases.length > 1
          # Multi-case non-void arm (fallthrough): expand into separate Swift enum cases
          # to preserve each discriminant. Case names derived from discriminant values.
          arm.cases.each do |c|
            case_name = swift_case_name_for_discriminant_value(c.value, disc_info)
            if MEMBER_OVERRIDES.key?(union_name) && MEMBER_OVERRIDES[union_name].key?(case_name)
              case_name = MEMBER_OVERRIDES[union_name][case_name]
            end
            next if seen_case_names.include?(case_name)
            seen_case_names.add(case_name)

            entries << {
              case_name: case_name,
              associated_type: assoc_type,
              disc_expressions: [disc_match_expression(c.value, disc_info)],
              disc_return: disc_return_expression(c.value, disc_info),
              decode_style: decode_style,
              decode_type: decode_type,
              xdr_arm_name: xdr_arm_name,
              raw_disc_names: [txrep_raw_disc_name(c.value, disc_info)],
              arm_ast: arm,
            }
          end
        else
          # Single-case non-void arm: use the XDR arm variable name as the Swift case name.
          case_name = swift_safe_name(arm.name.to_s.camelize(:lower))
          # Apply union-level arm name override if present.
          if MEMBER_OVERRIDES.key?(union_name) && MEMBER_OVERRIDES[union_name].key?(case_name)
            case_name = MEMBER_OVERRIDES[union_name][case_name]
          end
          next if seen_case_names.include?(case_name)
          seen_case_names.add(case_name)

          entries << {
            case_name: case_name,
            associated_type: assoc_type,
            disc_expressions: arm.cases.map { |c| disc_match_expression(c.value, disc_info) },
            disc_return: disc_return_expression(arm.cases.first.value, disc_info),
            decode_style: decode_style,
            decode_type: decode_type,
            xdr_arm_name: xdr_arm_name,
            raw_disc_names: arm.cases.map { |c| txrep_raw_disc_name(c.value, disc_info) },
            arm_ast: arm,
          }
        end
      end
    end

    # Handle default arm if present (none in current Stellar XDR, but support it).
    if union.default_arm.present?
      da = union.default_arm
      if da.void?
        entries << {
          case_name: "default_",
          associated_type: nil,
          disc_expressions: [:default],
          disc_return: "0", # placeholder
          decode_style: :void,
          decode_type: nil,
          is_default: true,
        }
      else
        assoc_type, decode_style = resolve_arm_type(da)
        entries << {
          case_name: swift_safe_name(da.name.to_s.camelize(:lower)),
          associated_type: assoc_type,
          disc_expressions: [:default],
          disc_return: "0", # placeholder
          decode_style: decode_style,
          decode_type: resolve_arm_decode_type(da),
          is_default: true,
        }
      end
    end

    entries
  end

  # Produce the original XDR constant name (SCREAMING_SNAKE, as written in
  # the .x file) for a discriminant value. Used by the union TxRep renderer
  # so the emitted string matches other SEP-0011 implementations regardless
  # of local Swift case-name rewrites.
  def txrep_raw_disc_name(value, disc_info)
    if value.is_a?(AST::Identifier)
      value.name.to_s
    else
      # Integer literal discriminant (only occurs on extension unions whose
      # field name is typically `v`). Use the integer as a stringified token.
      value.value.to_s
    end
  end

  # Produce the Swift case name for a discriminant value (used for void arms).
  def swift_case_name_for_discriminant_value(value, disc_info)
    if value.is_a?(AST::Identifier)
      xdr_name = disc_info[:xdr_name]
      swift_enum_case_name(xdr_name, value.name, enum_defn: disc_info[:enum_defn])
    else
      # Integer literal -- for void arms with int discriminant,
      # use "void" for case 0 (extension pattern).
      int_val = value.value.to_i
      int_val == 0 ? "void" : "v#{int_val}"
    end
  end

  # Produce the discriminant match expression for a `case` in the decode switch.
  def disc_match_expression(value, disc_info)
    if value.is_a?(AST::Identifier)
      case disc_info[:kind]
      when :skip_type_struct
        # Struct-with-constants: MemoType.MEMO_TYPE_NONE
        member_name = value.name
        xdr_name = disc_info[:xdr_name]
        if MEMBER_OVERRIDES.key?(xdr_name) && MEMBER_OVERRIDES[xdr_name].key?(member_name)
          constant = MEMBER_OVERRIDES[xdr_name][member_name]
        else
          constant = member_name
        end
        "#{disc_info[:swift_name]}.#{constant}"
      when :enum
        # Swift enum: EnumType.caseName.rawValue
        case_name = swift_enum_case_name(disc_info[:xdr_name], value.name, enum_defn: disc_info[:enum_defn])
        "#{disc_info[:swift_name]}.#{swift_safe_name(case_name)}.rawValue"
      end
    else
      # Integer literal
      value.value.to_s
    end
  end

  # Produce the discriminant return expression for the type() method.
  def disc_return_expression(value, disc_info)
    # Same as match expression for all discriminant kinds.
    disc_match_expression(value, disc_info)
  end

  # Determine the Swift associated type string and decode style for a non-void arm.
  def resolve_arm_type(arm)
    decl = arm.declaration

    case decl
    when AST::Declarations::Array
      base = type_string(decl.type)
      ["[#{base}]", :array]
    when AST::Declarations::Optional
      base = type_string(decl.type)
      ["#{base}?", :optional]
    when AST::Declarations::String
      ["String", :simple]
    when AST::Declarations::Opaque
      base = type_string(decl.type)
      [base, :simple]
    else
      base = type_string(decl.type)
      [base, :simple]
    end
  end

  # Determine the base decode type for a non-void arm.
  def resolve_arm_decode_type(arm)
    decl = arm.declaration

    case decl
    when AST::Declarations::Array
      type_string(decl.type)
    when AST::Declarations::Optional
      type_string(decl.type)
    when AST::Declarations::String
      "String"
    when AST::Declarations::Opaque
      type_string(decl.type)
    else
      type_string(decl.type)
    end
  end

  # ---------------------------------------------------------------------------
  # Union: init(from decoder:)
  # ---------------------------------------------------------------------------

  def render_union_decode(out, union_name, case_entries, disc_info)
    out.puts "public init(from decoder: Decoder) throws {"
    out.indent do
      out.puts "var container = try decoder.unkeyedContainer()"
      out.puts "let discriminant = try container.decode(Int32.self)"
      out.break
      out.puts "switch discriminant {"

      has_default_entry = case_entries.any? { |e| e[:is_default] }

      case_entries.each do |entry|
        if entry[:is_default]
          out.puts "default:"
        else
          # In Swift, multiple case patterns must be comma-separated on one line.
          out.puts "case #{entry[:disc_expressions].join(", ")}:"
        end
        out.indent do
          render_union_decode_arm(out, entry)
        end
      end

      # If no explicit default arm, add a throwing default.
      unless has_default_entry
        out.puts "default:"
        out.indent do
          out.puts "throw StellarSDKError.xdrDecodingError(message: \"Unknown #{union_name} discriminant: \\(discriminant)\")"
        end
      end

      out.puts "}"
    end
    out.puts "}"
  end

  def render_union_decode_arm(out, entry)
    case_name = swift_safe_name(entry[:case_name])
    case entry[:decode_style]
    when :void
      out.puts "self = .#{case_name}"
    when :array
      out.puts "let val = try decodeArray(type: #{entry[:decode_type]}.self, dec: decoder)"
      out.puts "self = .#{case_name}(val)"
    when :optional
      # Optional union arm: use explicit flag pattern instead of decodeArray(...).first
      # which fails for types without explicit init(from:) (e.g. WrappedData32, Data).
      out.puts "let #{case_name}Present = try container.decode(Int32.self)"
      out.puts "if #{case_name}Present != 0 {"
      out.indent do
        out.puts "self = .#{case_name}(try container.decode(#{entry[:decode_type]}.self))"
      end
      out.puts "} else {"
      out.indent do
        out.puts "self = .#{case_name}(nil)"
      end
      out.puts "}"
    when :simple
      out.puts "let val = try container.decode(#{entry[:decode_type]}.self)"
      out.puts "self = .#{case_name}(val)"
    end
  end

  # ---------------------------------------------------------------------------
  # Union: type() -> Int32
  # ---------------------------------------------------------------------------

  def render_union_type_func(out, case_entries, disc_info)
    out.puts "public func type() -> Int32 {"
    out.indent do
      out.puts "switch self {"
      case_entries.each do |entry|
        next if entry[:is_default]
        case_name = swift_safe_name(entry[:case_name])
        out.puts "case .#{case_name}: return #{entry[:disc_return]}"
      end
      out.puts "}"
    end
    out.puts "}"
  end

  # ---------------------------------------------------------------------------
  # Union: encode(to encoder:)
  # ---------------------------------------------------------------------------

  def render_union_encode(out, case_entries)
    out.puts "public func encode(to encoder: Encoder) throws {"
    out.indent do
      out.puts "var container = encoder.unkeyedContainer()"
      out.puts "try container.encode(type())"
      out.break
      out.puts "switch self {"

      case_entries.each do |entry|
        case_name = swift_safe_name(entry[:case_name])
        if entry[:decode_style] == :void
          out.puts "case .#{case_name}:"
          out.indent do
            out.puts "break"
          end
        elsif entry[:decode_style] == :optional
          # Optional union arm: encode explicit presence flag before the value.
          # The XDR encoder's default optional handling doesn't work for optional
          # arrays because [Any] pattern matching takes precedence over isOptional.
          out.puts "case .#{case_name}(let val):"
          out.indent do
            out.puts "if let val = val {"
            out.indent do
              out.puts "try container.encode(Int32(1))"
              out.puts "try container.encode(val)"
            end
            out.puts "} else {"
            out.indent do
              out.puts "try container.encode(Int32(0))"
            end
            out.puts "}"
          end
        else
          out.puts "case .#{case_name}(let val):"
          out.indent do
            out.puts "try container.encode(val)"
          end
        end
      end

      out.puts "}"
    end
    out.puts "}"
  end

  # ---------------------------------------------------------------------------
  # Typedef renderer
  # ---------------------------------------------------------------------------

  def render_typedef(typedef)
    typedef_name = name(typedef)
    out = @output.open("#{typedef_name}.swift")
    render_file_header(out, typedef_name)

    decl = typedef.declaration

    case decl
    when AST::Declarations::Array
      # Array typedef: wrap in a struct for XDRCodable conformance.
      base = type_string(decl.type)
      render_typedef_array_wrapper(out, typedef_name, base, decl)
    when AST::Declarations::Opaque
      # Opaque typedef: map to typealias for the appropriate data type.
      target = type_string(decl.type)
      out.puts "public typealias #{typedef_name} = #{target}"
    when AST::Declarations::String
      out.puts "public typealias #{typedef_name} = String"
    else
      # Simple typedef: emit a typealias.
      target = type_string(decl.type)
      if decl.type.sub_type == :optional
        out.puts "public typealias #{typedef_name} = #{target}?"
      else
        out.puts "public typealias #{typedef_name} = #{target}"
      end
    end

    out.close
  end

  # Emit a struct wrapper for an array typedef, providing XDRCodable conformance.
  def render_typedef_array_wrapper(out, typedef_name, element_type, decl)
    # Check FIELD_OVERRIDES to see if the default "wrapped" field name
    # should be renamed (e.g. ContractCostParamsXDR -> entries).
    field_name = resolve_field_name(typedef_name, "wrapped")

    # Check if the init parameter label differs from the field name.
    init_label = TYPEDEF_INIT_LABEL.key?(typedef_name) ? TYPEDEF_INIT_LABEL[typedef_name] : field_name

    use_let = LET_TYPES.include?(typedef_name)
    keyword = use_let ? "let" : "var"

    out.puts "public struct #{typedef_name}: XDRCodable, Sendable {"
    out.indent do
      out.puts "public #{keyword} #{field_name}: [#{element_type}]"
      out.break

      out.puts "public init(#{init_label}: [#{element_type}]) {"
      out.indent do
        out.puts "self.#{field_name} = #{init_label}"
      end
      out.puts "}"
      out.break

      # Decode
      out.puts "public init(from decoder: Decoder) throws {"
      out.indent do
        if decl.fixed?
          size = resolve_size(decl)
          out.puts "var container = try decoder.unkeyedContainer()"
          out.puts "#{field_name} = try (0..<#{size}).map { _ in try container.decode(#{element_type}.self) }"
        else
          out.puts "#{field_name} = try decodeArray(type: #{element_type}.self, dec: decoder)"
        end
      end
      out.puts "}"
      out.break

      # Encode
      out.puts "public func encode(to encoder: Encoder) throws {"
      out.indent do
        out.puts "var container = encoder.unkeyedContainer()"
        if decl.fixed?
          out.puts "for element in #{field_name} { try container.encode(element) }"
        else
          out.puts "try container.encode(#{field_name})"
        end
      end
      out.puts "}"
    end
    out.puts "}"
  end

  # ---------------------------------------------------------------------------
  # Const renderer
  # ---------------------------------------------------------------------------

  def render_const(const)
    @constants ||= []
    @constants << [const.name, const_value(const.value)]
  end

  # Write all accumulated constants to XDRConstants.swift.
  # Called from the generate entry point after all definitions are processed.
  def render_constants_file
    return if @constants.nil? || @constants.empty?
    out = @output.open("XDRConstants.swift")
    render_file_header(out, "XDRConstants")
    @constants.sort_by { |name, _| name }.each do |cname, cvalue|
      out.puts "public let #{cname}: Int32 = #{cvalue}"
    end
    out.close
  end

  # ---------------------------------------------------------------------------
  # File header
  # ---------------------------------------------------------------------------

  def render_file_header(out, type_name)
    out.puts <<~HEADER
      // This file was automatically generated by xdrgen.
      // DO NOT EDIT or your changes may be overwritten.

      import Foundation
    HEADER
    out.break
  end

  # ---------------------------------------------------------------------------
  # XDR-to-Swift type mapping
  # ---------------------------------------------------------------------------

  def type_string(type)
    case type
    when AST::Typespecs::Bool
      "Bool"
    when AST::Typespecs::Int
      "Int32"
    when AST::Typespecs::UnsignedInt
      "UInt32"
    when AST::Typespecs::Hyper
      "Int64"
    when AST::Typespecs::UnsignedHyper
      "UInt64"
    when AST::Typespecs::Float
      "Float"
    when AST::Typespecs::Double
      "Double"
    when AST::Typespecs::Quadruple
      raise "quadruple not supported in Swift"
    when AST::Typespecs::String
      "String"
    when AST::Typespecs::Opaque
      if type.fixed? && [4, 12, 16, 32].include?(type.size.to_i)
        "WrappedData#{type.size.to_i}"
      else
        "Data"
      end
    when AST::Typespecs::Simple
      # If the simple type resolves to a typedef whose underlying type is a
      # primitive, return the primitive Swift type directly. This handles
      # the standard XDR typedefs: int32, uint32, int64, uint64, etc.
      resolved = type.resolved_type
      if resolved.is_a?(AST::Definitions::Typedef)
        underlying = resolved.declaration.type
        if is_base_type?(underlying)
          return type_string(underlying)
        end
        # Optional typedefs (e.g. typedef AccountID* SponsorshipDescriptor):
        # resolve through to the base type so callers get e.g. "PublicKey"
        # rather than the typedef wrapper name. The optional wrapping ("?")
        # is added separately by swift_type_string / typedef_is_optional?.
        if underlying.sub_type == :optional
          return type_string(underlying)
        end
      end
      resolved_name = name(resolved)
      # Apply TYPE_OVERRIDES for typedef names that the SDK expects as
      # different types (e.g., AccountIDXDR -> PublicKey).
      if TYPE_OVERRIDES.key?(resolved_name)
        return TYPE_OVERRIDES[resolved_name]
      end
      resolved_name
    when AST::Definitions::Base
      name(type)
    when AST::Concerns::NestedDefinition
      name(type)
    else
      raise "Unknown type reference: #{type.class.name}"
    end
  end

  # Determine the full Swift type string for a declaration, including
  # optional wrapping and array brackets.
  def swift_type_string(decl)
    base = type_string(decl.type)
    is_opt = decl.type.sub_type == :optional || typedef_is_optional?(decl.type)

    case decl
    when AST::Declarations::Array
      if is_opt
        "[#{base}?]"
      else
        "[#{base}]"
      end
    else
      if is_opt
        "#{base}?"
      else
        base
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Name resolution
  # ---------------------------------------------------------------------------

  # Resolve the Swift name for a type, applying NAME_OVERRIDES when present.
  def name(named)
    # Build the raw XDR name (without applying overrides to the parent) for
    # looking up NAME_OVERRIDES. This ensures nested types use the canonical
    # XDR hierarchy (e.g., "HashIDPreimageContractID") rather than the
    # resolved Swift parent name (e.g., "HashIDPreimageXDRContractID").
    raw_xdr_name = raw_xdr_qualified_name(named)

    # Check overrides with the raw XDR name first.
    if NAME_OVERRIDES.key?(raw_xdr_name)
      return NAME_OVERRIDES[raw_xdr_name]
    end

    # Check overrides without parent (bare type name).
    xdr_name = named.name.camelize
    if NAME_OVERRIDES.key?(xdr_name)
      return NAME_OVERRIDES[xdr_name]
    end

    # Default: build the full name using the resolved parent Swift name
    # and append "XDR" suffix.
    if named.is_a?(AST::Concerns::NestedDefinition)
      parent = name(named.parent_defn)
      "#{parent}#{xdr_name}XDR"
    else
      "#{xdr_name}XDR"
    end
  end

  # Build the raw XDR qualified name for a type by concatenating the
  # camelized names of its parent chain without applying NAME_OVERRIDES.
  # E.g., for ContractID nested inside HashIDPreimage, this returns
  # "HashIDPreimageContractID" (not "HashIDPreimageXDRContractID").
  def raw_xdr_qualified_name(named)
    xdr_name = named.name.camelize
    if named.is_a?(AST::Concerns::NestedDefinition)
      parent_raw = raw_xdr_qualified_name(named.parent_defn)
      "#{parent_raw}#{xdr_name}"
    else
      xdr_name
    end
  end

  # ---------------------------------------------------------------------------
  # Identifier safety
  # ---------------------------------------------------------------------------

  # Escape a Swift identifier with backticks if it is a reserved word.
  # Map of leading digits to their English word equivalents.
  DIGIT_WORDS = {
    "0" => "zero", "1" => "one", "2" => "two", "3" => "three",
    "4" => "four", "5" => "five", "6" => "six", "7" => "seven",
    "8" => "eight", "9" => "nine"
  }.freeze

  def swift_safe_name(identifier)
    identifier = identifier.to_s
    return "`#{identifier}`" if SWIFT_RESERVED_WORDS.include?(identifier)
    # Swift identifiers cannot start with a digit; replace leading digit with
    # its English word and capitalise the next character to preserve camelCase.
    if identifier =~ /\A(\d)(.*)/
      word = DIGIT_WORDS[$1]
      rest = $2
      # Capitalise the first letter of the remainder so "8Bit" becomes "eightBit".
      rest = rest.sub(/\A(.)/) { $1.upcase } unless rest.empty?
      identifier = "#{word}#{rest}"
    end
    identifier
  end

  # Resolve the field name for a struct property, applying FIELD_OVERRIDES
  # when present, otherwise falling back to swift_safe_name.
  def resolve_field_name(struct_name, xdr_field_name)
    field = swift_safe_name(xdr_field_name)
    if FIELD_OVERRIDES.key?(struct_name) && FIELD_OVERRIDES[struct_name].key?(field)
      FIELD_OVERRIDES[struct_name][field]
    else
      field
    end
  end

  # Convert an XDR SCREAMING_SNAKE_CASE enum member name to the Swift camelCase
  # case name, applying MEMBER_OVERRIDES when present.
  #
  # Algorithm:
  #   1. Look up the (type_name, member_name) pair in MEMBER_OVERRIDES.
  #   2. If not found, strip the common prefix and apply mechanical conversion:
  #      a. Determine the common prefix shared by all members of the enum.
  #      b. Strip that prefix from the member name.
  #      c. Convert the remainder to camelCase.
  #      d. Lowercase the first character.
  #
  # The +enum_name+ is the XDR canonical name (before NAME_OVERRIDES), and
  # +member_name+ is the raw XDR member identifier (SCREAMING_SNAKE).
  def swift_enum_case_name(enum_name, member_name, enum_defn: nil)
    # Check overrides.
    if MEMBER_OVERRIDES.key?(enum_name)
      overrides = MEMBER_OVERRIDES[enum_name]
      return overrides[member_name] if overrides.key?(member_name)
    end

    # If an enum definition is available, compute prefix stripping
    # to match the same logic used in render_enum.
    if enum_defn
      raw_names = enum_defn.members.map { |m| m.name.to_s }
      normalized_names = raw_names.map { |n| n.underscore.upcase }
      prefix = detect_common_prefix(normalized_names)
      normalized_member = member_name.to_s.underscore.upcase
      stripped = prefix.empty? ? normalized_member : normalized_member.sub(/\A#{Regexp.escape(prefix)}/, "")
      stripped = normalized_member if stripped.empty?
      return mechanical_camel_case(stripped)
    end

    # Fallback: mechanical conversion without prefix stripping.
    mechanical_camel_case(member_name)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Convert an XDR enum member name to Swift camelCase.
  #
  # Handles two formats:
  #   - SCREAMING_SNAKE_CASE (older XDR files): split on "_", join as camelCase.
  #   - CamelCase (newer XDR files): lowercase the first character.
  def mechanical_camel_case(input)
    str = input.to_s
    parts = str.split("_")

    if parts.length == 1
      # Single segment -- either a single ALL_CAPS word or CamelCase.
      # If the string has mixed case (e.g., "WasmInsnExec"), just lowercase
      # the first character. If it's all uppercase (e.g., "ACCOUNT"), downcase entirely.
      if str =~ /\A[A-Z][a-z]/
        # CamelCase input: lowercase the first character only.
        return str[0].downcase + str[1..]
      else
        # Single all-caps word.
        return str.downcase
      end
    end

    first = parts.first.downcase
    rest = parts[1..].map(&:capitalize)
    "#{first}#{rest.join}"
  end

  # Detect the longest common prefix among a list of SCREAMING_SNAKE member names.
  # Returns the prefix including the trailing underscore, or empty string if
  # no common prefix is found.
  def detect_common_prefix(member_names)
    return "" if member_names.empty?

    # Split each name into underscore-separated segments.
    split_names = member_names.map { |n| n.split("_") }
    first_segments = split_names.first

    prefix_segments = []
    first_segments.each_with_index do |seg, i|
      break unless split_names.all? { |parts| parts.length > i && parts[i] == seg }
      prefix_segments << seg
    end

    return "" if prefix_segments.empty?
    "#{prefix_segments.join("_")}_"
  end

  # Resolve the array/opaque size for a fixed-size declaration.
  # Returns the integer size or the constant name string.
  def resolve_size(decl)
    _, size = decl.type.array_size
    size
  end

  # Check whether the given AST typespec is a primitive / base type
  # (as opposed to a user-defined struct/enum/union/typedef).
  def is_base_type?(type)
    case type
    when AST::Typespecs::Bool,
         AST::Typespecs::Double,
         AST::Typespecs::Float,
         AST::Typespecs::Hyper,
         AST::Typespecs::Int,
         AST::Typespecs::String,
         AST::Typespecs::UnsignedHyper,
         AST::Typespecs::UnsignedInt
      true
    else
      false
    end
  end

  # Resolve a constant value. If the value is an identifier reference,
  # resolve it to the Swift constant name. Otherwise return the literal.
  def const_value(value)
    return value.name if value.is_a?(AST::Identifier)
    value
  end

  # ---------------------------------------------------------------------------
  # Type override helpers
  # ---------------------------------------------------------------------------

  # Check if a struct field is an extension point that should be simplified
  # to `let reserved: Int32 = 0`.
  def is_extension_point_field?(struct_name, field_name)
    EXTENSION_POINT_FIELDS.key?(struct_name) &&
      EXTENSION_POINT_FIELDS[struct_name].include?(field_name)
  end

  # Resolve the Swift type for a struct field, applying FIELD_TYPE_OVERRIDES
  # and TYPE_OVERRIDES.
  def resolve_field_type(struct_name, field, member)
    if FIELD_TYPE_OVERRIDES.key?(struct_name) &&
       FIELD_TYPE_OVERRIDES[struct_name].key?(field)
      type_str = FIELD_TYPE_OVERRIDES[struct_name][field]
      is_opt = member.type.sub_type == :optional || typedef_is_optional?(member.declaration.type)
      if is_opt
        "#{type_str}?"
      else
        type_str
      end
    else
      swift_type_string(member.declaration)
    end
  end

  # Check if a typespec resolves to a typedef whose underlying type is optional.
  # This handles typedefs like `typedef AccountID* SponsorshipDescriptor` where
  # the optionality is baked into the typedef, not at the field level.
  #
  # When a typedef has a TYPE_OVERRIDES entry (e.g. SponsorshipDescriptorXDR),
  # the wrapper type handles optionality internally, so we return false to
  # prevent the generator from adding optional decode/encode at the field level.
  def typedef_is_optional?(type)
    return false unless type.is_a?(AST::Typespecs::Simple)
    resolved = type.resolved_type
    return false unless resolved.is_a?(AST::Definitions::Typedef)
    # If the typedef is resolved via TYPE_OVERRIDES to a wrapper type,
    # the wrapper handles optionality internally -- don't add optional
    # decode at the field level.
    resolved_name = name(resolved)
    return false if TYPE_OVERRIDES.key?(resolved_name)
    resolved.declaration.type.sub_type == :optional
  rescue
    false
  end

  # Resolve the init parameter name for a field, using INIT_PARAM_OVERRIDES
  # if present.
  def resolve_init_param_name(struct_name, field_name)
    if INIT_PARAM_OVERRIDES.key?(struct_name) &&
       INIT_PARAM_OVERRIDES[struct_name].key?(field_name)
      INIT_PARAM_OVERRIDES[struct_name][field_name]
    else
      field_name
    end
  end
end
