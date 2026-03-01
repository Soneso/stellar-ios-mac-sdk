# Swift XDR code generator for the iOS/macOS Stellar SDK.
#
# This generator is invoked by xdrgen and produces Swift structs, enums,
# and typedefs that conform to XDRCodable and Sendable.
#
# Usage:
#   ruby generate.rb
#
# The generated files are placed into stellarsdk/stellarsdk/xdr/.

require 'set'
require 'xdrgen'
require_relative 'name_overrides'
require_relative 'member_overrides'
require_relative 'field_overrides'
require_relative 'type_overrides'

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
    TransactionSignaturePayload
    TaggedTransaction
    TransactionV0EnvelopeXDR
    TransactionV1EnvelopeXDR
    FeeBumpTransactionEnvelopeXDR
    TransactionXDR
    TransactionV0XDR
    FeeBumpTransactionXDR
    InnerTransactionXDR
    TransactionEnvelopeXDR
    OperationXDR
    OperationBodyXDR
    MuxedAccountXDR
    MuxedAccountMed25519XDR
    TransactionResultXDR
    InnerTransactionResultXDR
    TransactionResultCode
    TransactionResultBodyXDR
    InnerTransactionResultPair
    InnerTransactionResultBodyXDR
    OperationResultXDR
    OperationResultXDRTrXDR
    TransactionResultXDRResultXDR
    InnerTransactionResultXDRResultXDR
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
    return if ADDITIONAL_SKIP_TYPES.include?(defn_name)

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
      end
    end
    out.puts "}"
    out.close
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
    out.close
  end

  # Resolve discriminant metadata: whether it's an enum, a SKIP_TYPES
  # struct-with-constants, or a plain integer.
  #
  # Returns a hash with:
  #   :kind        - :enum, :skip_type_struct, or :int
  #   :swift_name  - The Swift type name for the discriminant type (or nil for :int)
  #   :xdr_name    - The XDR canonical name (for looking up MEMBER_OVERRIDES)
  def resolve_discriminant_info(union)
    dtype = union.discriminant.type

    if dtype.respond_to?(:resolved_type)
      resolved = dtype.resolved_type
      if resolved.is_a?(AST::Definitions::Enum)
        xdr_name = resolved.name.camelize
        swift_name = name(resolved)

        if SKIP_TYPES.include?(swift_name)
          return { kind: :skip_type_struct, swift_name: swift_name, xdr_name: xdr_name, enum_defn: resolved }
        else
          return { kind: :enum, swift_name: swift_name, xdr_name: xdr_name, enum_defn: resolved }
        end
      end
    end

    # Integer discriminant (e.g., `int v` for extension unions).
    { kind: :int, swift_name: nil, xdr_name: nil, enum_defn: nil }
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
      if type.fixed? && [4, 12, 32].include?(type.size.to_i)
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
         AST::Typespecs::Opaque,
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
