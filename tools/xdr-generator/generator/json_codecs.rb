# frozen_string_literal: true

require_relative 'json_names'
require_relative 'json_overrides'
require_relative 'json_field_overrides'

# Chooses the SEP-0051 (XDR-JSON) conversion for one declaration site.
#
# Dispatch is on the declaration's AST node, never on the Swift type it renders as.
# Swift collapses several XDR types onto one another -- Hash, ContractID and PoolID all
# become WrappedData32, and AssetCode4, Thresholds and SignatureHint all become
# WrappedData4 -- while SEP-0051 gives each of them a different wire form, so the Swift
# type cannot decide the conversion. The AST keeps the distinction: a named type carries
# its declared typedef name one hop from the field's typespec, and a type the .x declares
# inline is separated by the node class itself.
#
# The unit this module produces is a Codec: a pair of Swift expression builders, one for
# each direction, plus flags saying whether either direction can throw. The flags matter
# because a `try` covering nothing is a compiler warning, and this generator emits several
# thousand conversions.
module Sep51JsonCodecs
  # One declaration site's conversion, in both directions.
  #
  # +emit+ turns a Swift accessor into an expression of type XdrJsonValue. +read+ turns an
  # expression of type XdrJsonValue into the Swift value. +read_statements+ is present only
  # where reading needs more than one statement, in which case +read+ is unavailable.
  class Codec
    attr_reader :swift_type

    def initialize(swift_type:, emit: nil, emit_statements: nil, read: nil,
                   read_statements: nil, emit_throws: true)
      @swift_type = swift_type
      @emit = emit
      @emit_statements = emit_statements
      @read = read
      @read_statements = read_statements
      @emit_throws = emit_throws
    end

    # The emission expression without a `try`, for a caller that supplies its own.
    def emit(accessor)
      raise "codec for #{@swift_type} has no single-expression emission" if @emit.nil?

      @emit.call(accessor)
    end

    # The emission expression with a `try` only where one is needed. A `try` covering a
    # call that cannot throw is a compiler warning, and this generator emits thousands.
    def emit_expression(accessor)
      @emit_throws ? "try #{emit(accessor)}" : emit(accessor)
    end

    def emit_throws? = @emit_throws

    # True when emission is a single expression, so a caller can nest it in a container.
    def expression_emit? = !@emit.nil?

    # True when reading is a single expression, so a caller can nest it.
    def expression_read? = !@read.nil?

    # Writes the statements that bind +local+ to the emitted XdrJsonValue.
    def write_emit(out, accessor, local)
      if @emit_statements
        @emit_statements.call(out, accessor, local)
      else
        out.puts "let #{local}: XdrJsonValue = #{emit_expression(accessor)}"
      end
    end

    def read(value)
      raise "codec for #{@swift_type} has no single-expression read" if @read.nil?

      @read.call(value)
    end

    # Writes the statements that bind +local+ to the decoded value.
    def write_read(out, value, local)
      if @read_statements
        @read_statements.call(out, value, local)
      else
        out.puts "let #{local}: #{@swift_type} = #{read(value)}"
      end
    end
  end

  # The owner a typedef's own conversion body reports a failure against.
  #
  # A typedef is a spelling, not a type a document names, so a failure inside one is located
  # by the site that declared it. The generated conversion receives that site as its `type`
  # and `key` parameters and every runtime call in its body forwards them, which is what this
  # owner renders. It keeps the typedef's name for the generator's own abort messages, where
  # naming the declaration under construction is what makes them actionable.
  class ForwardedContext
    def initialize(typedef_name)
      @typedef_name = typedef_name
    end

    def to_s = @typedef_name
  end

  # ---------------------------------------------------------------------------
  # Entry points
  # ---------------------------------------------------------------------------

  # The conversion for a struct member or a union arm.
  #
  # +swift_type+ is the type the site actually declares in Swift, which the type and field
  # override tables can move away from what the AST implies. Where the two disagree the
  # difference is reconciled explicitly and an unrecognised disagreement aborts generation,
  # so a new override entry cannot silently produce wrong JSON.
  def json_codec(decl, owner:, key:, swift_type:)
    case decl
    when AST::Declarations::Array
      element_type = swift_type.sub(/\A\[(.*)\]\z/m, '\1')
      json_array_codec(json_element_codec(decl, owner: owner, key: key, swift_type: element_type),
                       owner: owner, key: key,
                       fixed_size: decl.fixed? ? resolve_size(decl) : nil)
    when AST::Declarations::Opaque
      json_opaque_codec(decl.type, owner: owner, key: key, swift_type: swift_type)
    when AST::Declarations::String
      json_string_codec(owner: owner, key: key)
    else
      json_element_codec(decl, owner: owner, key: key, swift_type: swift_type)
    end
  end

  # The conversion for one value of a declaration, ignoring any array around it.
  #
  # An optional declared at the field carries its own null handling here. An optional
  # declared by the typedef -- SponsorshipDescriptor is `AccountID*` -- does not: the
  # typedef's own codec namespace already renders it as null or a value, so wrapping it
  # again would ask for a null of a null.
  def json_element_codec(decl, owner:, key:, swift_type:)
    field_optional = decl.is_a?(AST::Declarations::Optional) || decl.type.sub_type == :optional
    unless field_optional
      return json_codec_for_type(decl.type, owner: owner, key: key, swift_type: swift_type)
    end

    inner = json_codec_for_type(decl.type, owner: owner, key: key,
                                swift_type: swift_type.sub(/\?\z/, ''))
    json_optional_codec(inner)
  end

  # The conversion for a typespec: a named type, a primitive, or an inline declaration.
  def json_codec_for_type(type, owner:, key:, swift_type:)
    case type
    when AST::Typespecs::Bool
      json_scalar_codec('Bool', 'bool', owner: owner, key: key)
    when AST::Typespecs::Int
      json_scalar_codec('Int32', 'int32', owner: owner, key: key)
    when AST::Typespecs::UnsignedInt
      json_scalar_codec('UInt32', 'uint32', owner: owner, key: key)
    when AST::Typespecs::Hyper
      json_hyper_codec(signed: true, owner: owner, key: key, swift_type: swift_type)
    when AST::Typespecs::UnsignedHyper
      json_hyper_codec(signed: false, owner: owner, key: key, swift_type: swift_type)
    when AST::Typespecs::String
      json_string_codec(owner: owner, key: key)
    when AST::Typespecs::Opaque
      json_opaque_codec(type, owner: owner, key: key, swift_type: swift_type)
    when AST::Typespecs::Simple
      json_named_codec(type, owner: owner, key: key, swift_type: swift_type)
    when AST::Concerns::NestedDefinition, AST::Definitions::Base
      json_nominal_codec(name(type), owner: owner, key: key, swift_type: swift_type)
    else
      raise "SEP-0051: no conversion for #{type.class.name} at #{owner}.#{key}"
    end
  end

  # ---------------------------------------------------------------------------
  # Named types
  # ---------------------------------------------------------------------------

  # A named type resolves one hop. `Typespecs::Simple#resolved_type` performs exactly one
  # lookup, which is what keeps `typedef Hash PoolID` distinguishable from `Hash` itself;
  # `Definitions::Typedef#resolved_type` chases the whole chain and would destroy that.
  def json_named_codec(type, owner:, key:, swift_type:)
    resolved = type.resolved_type

    unless resolved.is_a?(AST::Definitions::Typedef)
      return json_nominal_codec(name(resolved), owner: owner, key: key, swift_type: swift_type)
    end

    typedef_name = name(resolved)

    # An array typedef the type table collapses to a bare Swift array leaves no wrapper to
    # delegate to, so the site converts the array itself.
    collapsed = TYPE_OVERRIDES[typedef_name]
    if collapsed&.start_with?('[')
      element_type = collapsed.sub(/\A\[(.*)\]\z/m, '\1')
      element = json_codec_for_type(resolved.declaration.type, owner: owner, key: key,
                                    swift_type: element_type)
      return json_array_codec(element, owner: owner, key: key, fixed_size: nil)
    end

    if json_typedef_form(resolved) == :struct
      return json_nominal_codec(typedef_name, owner: owner, key: key, swift_type: swift_type)
    end

    # A field table entry can store a typedef in a type other than the one the typedef
    # names, and OfferEntry.offerID does exactly that: an XDR int64 stored as a Swift
    # UInt64. The codec namespace speaks the typedef's own type, so the site converts
    # against the underlying declaration instead, which is where the reinterpretation lives.
    # A site can spell the same type three ways: the typedef's own name, the name the
    # typealias points at, and the name the type table substitutes at reference sites. All
    # three are the same Swift type, so any of them keeps the codec namespace usable.
    target = json_typedef_target(resolved)
    spellings = [typedef_name, target, TYPE_OVERRIDES[typedef_name]].compact
    unless spellings.include?(swift_type)
      unless is_base_type?(resolved.declaration.type)
        raise "SEP-0051: #{owner}.#{key} declares #{typedef_name} (#{target}) but renders " \
              "as #{swift_type}; add the reconciliation to json_codecs.rb before generating"
      end

      return json_codec_for_type(resolved.declaration.type, owner: owner, key: key,
                                 swift_type: swift_type)
    end

    json_typedef_codec_reference(typedef_name, owner: owner, key: key, swift_type: swift_type)
  end

  # A typedef Swift renders as a typealias carries no methods of its own, so its conversion
  # lives in a generated codec namespace and every site calls that.
  #
  # The site passes the type and key it is written under, because that is what locates the
  # value in the document; the typedef's own name appears nowhere the caller could look up.
  def json_typedef_codec_reference(typedef_name, owner:, key:, swift_type:)
    namespace = json_codec_namespace(typedef_name)
    context = json_codec_context(owner, key)
    Codec.new(
      swift_type: swift_type,
      emit: ->(accessor) { "#{namespace}.toXdrJsonValue(#{accessor}, #{context})" },
      read: ->(value) { "try #{namespace}.fromXdrJsonValue(#{value}, #{context})" }
    )
  end

  # A struct, enum or union converts through its own members.
  #
  # Two type table entries move a nominal type's Swift form to a plain integer. The XDR type
  # is still an enumeration and SEP-0051 still renders its name, so the stored integer is
  # routed through the enumeration rather than emitted as a number.
  def json_nominal_codec(nominal_name, owner:, key:, swift_type:)
    # A Swift type shared by XDR definitions that render differently has no conversion of its
    # own. Only a union arm can supply one, because only the arm knows which definition the
    # value is; every other reference is a shape this generator cannot render and stops on.
    if json_divergent?(swift_type)
      raise "SEP-0051: #{owner}.#{key} references #{swift_type}, which several XDR definitions " \
            'collapse onto with different wire names. Only a union arm can render it; add the ' \
            'reference to json_codecs.rb before generating'
    end

    if %w[Int32 UInt32].include?(swift_type) && swift_type != nominal_name
      return json_enum_raw_value_codec(nominal_name, owner: owner, key: key, swift_type: swift_type)
    end

    unless swift_type == nominal_name
      raise "SEP-0051: #{owner}.#{key} declares #{nominal_name} but renders as #{swift_type}; " \
            'add the reconciliation to json_codecs.rb before generating'
    end

    Codec.new(
      swift_type: swift_type,
      emit: ->(accessor) { "#{accessor}.toXdrJsonValue()" },
      read: ->(value) { "try #{nominal_name}.fromXdrJsonValue(#{value})" }
    )
  end

  # An enumeration stored as its raw integer. Emission rejects a value the enumeration does
  # not declare rather than writing a number SEP-0051 has no reading for.
  def json_enum_raw_value_codec(enum_name, owner:, key:, swift_type:)
    context = json_context(owner, key)
    Codec.new(
      swift_type: swift_type,
      emit_statements: lambda { |out, accessor, local|
        out.puts "guard let #{local}Case = #{enum_name}(rawValue: #{accessor}) else {"
        out.indent do
          out.puts "throw XdrJsonError.invalidValue(#{context}, " \
                   "message: \"#{enum_name} declares no member \\(#{accessor})\")"
        end
        out.puts '}'
        out.puts "let #{local}: XdrJsonValue = try #{local}Case.toXdrJsonValue()"
      },
      read_statements: lambda { |out, value, local|
        out.puts "let #{local}Case = try #{enum_name}.fromXdrJsonValue(#{value})"
        out.puts "let #{local}: #{swift_type} = #{local}Case.rawValue"
      }
    )
  end

  # ---------------------------------------------------------------------------
  # Primitives
  # ---------------------------------------------------------------------------

  def json_scalar_codec(swift_type, helper, owner:, key:)
    context = json_context(owner, key)
    Codec.new(
      swift_type: swift_type,
      emit: ->(accessor) { "XdrJson.#{helper}(#{accessor})" },
      read: ->(value) { "try XdrJson.#{helper}(#{value}, #{context})" },
      emit_throws: false
    )
  end

  # A 64-bit integer renders as a signed or unsigned base-10 string according to the XDR
  # declaration, not according to the Swift storage. One field table entry stores an XDR
  # int64 as a Swift UInt64, and a value at or above 2^63 renders negative in SEP-0051, so
  # the bit pattern is reinterpreted rather than the number reformatted.
  def json_hyper_codec(signed:, owner:, key:, swift_type:)
    declared = signed ? 'Int64' : 'UInt64'
    context = json_context(owner, key)

    if swift_type == declared
      return json_scalar_codec(declared, signed ? 'int64' : 'uint64', owner: owner, key: key)
    end

    unless %w[Int64 UInt64].include?(swift_type)
      raise "SEP-0051: #{owner}.#{key} declares #{declared} but renders as #{swift_type}"
    end

    helper = signed ? 'int64' : 'uint64'
    Codec.new(
      swift_type: swift_type,
      emit: ->(accessor) { "XdrJson.#{helper}(#{declared}(bitPattern: #{accessor}))" },
      read: ->(value) { "#{swift_type}(bitPattern: try XdrJson.#{helper}(#{value}, #{context}))" },
      emit_throws: false
    )
  end

  def json_string_codec(owner:, key:)
    context = json_context(owner, key)
    Codec.new(
      swift_type: 'String',
      emit: ->(accessor) { "XdrJson.escapedString(#{accessor})" },
      read: ->(value) { "try XdrJson.unescapedText(#{value}, #{context})" },
      emit_throws: false
    )
  end

  # Opaque data renders as lowercase hexadecimal in both the fixed and the variable form.
  #
  # SEP-0051 §Fixed-Length Opaque Data requires hexadecimal wherever the XDR type is opaque.
  # The reference implementation emits an array of byte numbers where the .x declares the
  # opaque inline rather than through a named typedef; this SDK follows the specification in
  # both cases, which is a documented divergence.
  def json_opaque_codec(type, owner:, key:, swift_type:)
    context = json_context(owner, key)

    unless type.fixed?
      return Codec.new(
        swift_type: 'Data',
        emit: ->(accessor) { "XdrJson.hex(#{accessor})" },
        read: ->(value) { "try XdrJson.hex(#{value}, #{context})" },
        emit_throws: false
      )
    end

    size = type.size.to_i
    if swift_type.start_with?('WrappedData')
      Codec.new(
        swift_type: swift_type,
        emit: ->(accessor) { "XdrJson.hex(#{accessor}.wrapped, expectedLength: #{size}, #{context})" },
        read: lambda { |value|
          "#{swift_type}(try XdrJson.hex(#{value}, expectedLength: #{size}, #{context}))"
        }
      )
    else
      Codec.new(
        swift_type: 'Data',
        emit: ->(accessor) { "XdrJson.hex(#{accessor}, expectedLength: #{size}, #{context})" },
        read: ->(value) { "try XdrJson.hex(#{value}, expectedLength: #{size}, #{context})" }
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Containers
  # ---------------------------------------------------------------------------

  # An absent optional renders as JSON null and its key stays present in the parent object.
  def json_optional_codec(inner)
    Codec.new(
      swift_type: "#{inner.swift_type}?",
      emit: lambda { |accessor|
        "XdrJson.optional(#{accessor}.map { element in #{inner.emit_expression('element')} })"
      },
      read_statements: lambda { |out, value, local|
        out.puts "let #{local}Value = #{value}"
        out.puts "let #{local}: #{inner.swift_type}?"
        out.puts "if #{local}Value.isNull {"
        out.indent { out.puts "#{local} = nil" }
        out.puts '} else {'
        out.indent do
          if inner.expression_read?
            out.puts "#{local} = #{inner.read("#{local}Value")}"
          else
            inner.write_read(out, "#{local}Value", "#{local}Present")
            out.puts "#{local} = #{local}Present"
          end
        end
        out.puts '}'
      },
      emit_throws: inner.emit_throws?
    )
  end

  # An array renders as a JSON array, empty included. A fixed-length array checks its
  # element count on input, because a wrong count would re-encode to the wrong bytes.
  def json_array_codec(element, owner:, key:, fixed_size:)
    context = json_context(owner, key)

    Codec.new(
      swift_type: "[#{element.swift_type}]",
      emit: lambda { |accessor|
        "XdrJson.array(#{accessor}.map { element in #{element.emit_expression('element')} })"
      },
      read_statements: lambda { |out, value, local|
        out.puts "let #{local}Elements = try XdrJson.array(#{value}, #{context})"
        if fixed_size
          out.puts "guard #{local}Elements.count == Int(#{fixed_size}) else {"
          out.indent do
            out.puts "throw XdrJsonError.invalidValue(#{context}, " \
                     "message: \"expected \\(Int(#{fixed_size})) elements, got \\(#{local}Elements.count)\")"
          end
          out.puts '}'
        end
        if element.expression_read?
          out.puts "let #{local}: [#{element.swift_type}] = try #{local}Elements.map " \
                   "{ element in #{element.read('element')} }"
        else
          out.puts "var #{local}: [#{element.swift_type}] = []"
          out.puts "#{local}.reserveCapacity(#{local}Elements.count)"
          out.puts "for element in #{local}Elements {"
          out.indent do
            element.write_read(out, 'element', "#{local}Item")
            out.puts "#{local}.append(#{local}Item)"
          end
          out.puts '}'
        end
      },
      emit_throws: element.emit_throws?
    )
  end

  # ---------------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------------

  # The type and key a runtime call reports a failure against. The key is the JSON key, so a
  # message points at the document rather than at the Swift property. Inside a typedef's own
  # conversion the two are the parameters the caller supplied rather than literals.
  def json_context(owner, key)
    return 'type: type, key: key' if owner.is_a?(ForwardedContext)

    key.nil? ? %(type: "#{owner}") : %(type: "#{owner}", key: "#{key}")
  end

  # The context arguments a call into a generated typedef codec carries. Both labels are
  # always written, because the overload that receives them declares both.
  def json_codec_context(owner, key)
    return 'type: type, key: key' if owner.is_a?(ForwardedContext)

    key.nil? ? %(type: "#{owner}", key: nil) : %(type: "#{owner}", key: "#{key}")
  end

  def json_codec_namespace(typedef_name) = "#{typedef_name}JsonCodec"

  # The Swift form of a typedef decides where its conversion can live: an array typedef
  # becomes a struct that can carry methods, everything else becomes a typealias that cannot.
  def json_typedef_form(typedef)
    typedef.declaration.is_a?(AST::Declarations::Array) ? :struct : :typealias
  end


  # The JSON key a struct member is written under. It derives from the .x identifier, never
  # from the Swift property: the field table renames properties, so ClaimableBalanceEntry's
  # `balanceID` is the Swift `claimableBalanceID` while its JSON key stays `balance_id`.
  def json_member_key(member) = Sep51JsonNames.struct_field_json_name(member.name)

  # The list of keys a struct declares, in declaration order, as a Swift array literal.
  #
  # SEP-0051 §Struct requires `type` on output and accepts the pre-28.0.0 reference
  # spelling `type_` on input, so that one key carries an alias and every other key is a
  # bare string literal.
  def json_declared_key_literal(key)
    key == 'type' ? %(XdrJson.DeclaredKey("type", alias: "type_")) : %("#{key}")
  end
end
