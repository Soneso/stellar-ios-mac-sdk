#!/usr/bin/env ruby
# frozen_string_literal: true

# Validates the generated Swift XDR files against the XDR .x file definitions.
#
# This script parses the .x files using xdrgen's AST and compares the structure
# of each generated Swift file to ensure accuracy. It reuses the same override
# files and type mapping logic that the generator uses.
#
# Usage:
#   cd tools/xdr-generator && bundle exec ruby test/validate_generated_types.rb

require 'xdrgen'
require 'set'
require_relative '../generator/generator'

AST = Xdrgen::AST unless defined?(AST)

# =============================================================================
# Validation Engine
# =============================================================================

class GeneratedTypeValidator
  # Reuse SKIP_TYPES from the Generator class
  SKIP_TYPES = Generator::SKIP_TYPES + ADDITIONAL_SKIP_TYPES

  attr_reader :pass_count, :fail_count, :missing_count, :skip_count, :failures

  def initialize(generated_dir, xdr_dir)
    @generated_dir = generated_dir
    @xdr_dir = xdr_dir
    @pass_count = 0
    @fail_count = 0
    @missing_count = 0
    @skip_count = 0
    @failures = []
    @missing_types = []
    @generated_files_cache = Set.new
    @seen_swift_names = Set.new

    # Build a helper Generator instance to reuse its methods.
    # We need a lightweight wrapper that exposes the private helper methods.
    @gen = GeneratorHelper.new
  end

  # ---------------------------------------------------------------------------
  # Main entry point
  # ---------------------------------------------------------------------------

  def validate
    # Cache all generated Swift filenames for quick lookup
    Dir.glob(File.join(@generated_dir, "*.swift")).each do |path|
      @generated_files_cache.add(File.basename(path, ".swift"))
    end

    # Parse XDR files using xdrgen (same approach as generate.rb)
    Dir.chdir(File.expand_path("../../..", __dir__))
    compilation = Xdrgen::Compilation.new(
      Dir.glob("xdr/*.x"),
      output_dir: "/dev/null/", # We won't actually generate; just parse
      generator: Generator,
      namespace: "stellar",
    )
    # Access the parsed AST top node via the compilation
    # xdrgen stores the parsed AST in compilation's internal state.
    # We need to walk the AST manually.
    top = compilation.send(:ast)

    walk_definitions(top)

    print_report
  end

  private

  # ---------------------------------------------------------------------------
  # AST Traversal
  # ---------------------------------------------------------------------------

  def walk_definitions(node)
    node.definitions.each { |defn| validate_definition(defn) }
    node.namespaces.each { |ns| walk_definitions(ns) }
  end

  def walk_nested_definitions(defn)
    return unless defn.respond_to?(:nested_definitions)
    defn.nested_definitions.each { |nested| validate_definition(nested) }
  end

  def validate_definition(defn)
    # Skip namespaces -- they are containers, not types
    return if defn.is_a?(AST::Definitions::Namespace)

    walk_nested_definitions(defn)

    swift_name = @gen.name(defn)

    # Skip constants -- they go into XDRConstants.swift, not individual files
    return if defn.is_a?(AST::Definitions::Const)

    # Skip types on the skip list
    if SKIP_TYPES.include?(swift_name)
      @skip_count += 1
      return
    end

    # Avoid validating the same Swift name twice (e.g. when two XDR types
    # map to the same Swift name via NAME_OVERRIDES)
    return if @seen_swift_names.include?(swift_name)
    @seen_swift_names.add(swift_name)

    # Check that the generated file exists
    swift_file = File.join(@generated_dir, "#{swift_name}.swift")
    unless File.exist?(swift_file)
      @missing_count += 1
      @missing_types << swift_name
      return
    end

    swift_content = File.read(swift_file)

    case defn
    when AST::Definitions::Struct
      validate_struct(defn, swift_name, swift_content)
    when AST::Definitions::Enum
      validate_enum(defn, swift_name, swift_content)
    when AST::Definitions::Union
      validate_union(defn, swift_name, swift_content)
    when AST::Definitions::Typedef
      validate_typedef(defn, swift_name, swift_content)
    end
  end

  # ---------------------------------------------------------------------------
  # Struct Validation
  # ---------------------------------------------------------------------------

  def validate_struct(struct_defn, swift_name, content)
    errors = []

    # Check that it's declared as a struct
    unless content =~ /public struct #{Regexp.escape(swift_name)}: XDRCodable/
      errors << "Not declared as 'public struct #{swift_name}: XDRCodable'"
    end

    # Build expected fields
    expected_fields = []
    struct_defn.members.each do |m|
      field_name = @gen.resolve_field_name(swift_name, m.name)

      if @gen.is_extension_point_field?(swift_name, field_name)
        expected_fields << { name: field_name, type: "Int32", extension_point: true }
      else
        type_str = @gen.resolve_field_type(swift_name, field_name, m)
        expected_fields << { name: field_name, type: type_str, extension_point: false }
      end
    end

    # Extract actual fields from Swift file
    # Match patterns like: public var/let fieldName: Type
    # Also handles backtick-escaped names like `protocol`
    actual_fields = []
    content.scan(/public\s+(?:private\(set\)\s+)?(?:var|let)\s+(`?\w+`?):\s+([^\n{=]+?)(?:\s*=\s*[^\n]+)?$/) do |match|
      fname = match[0].strip
      ftype = match[1].strip
      actual_fields << { name: fname, type: ftype }
    end

    # Compare field count
    if expected_fields.length != actual_fields.length
      errors << "Field count mismatch: expected #{expected_fields.length}, got #{actual_fields.length}"
      errors << "  Expected fields: #{expected_fields.map { |f| f[:name] }.join(', ')}"
      errors << "  Actual fields:   #{actual_fields.map { |f| f[:name] }.join(', ')}"
    end

    # Compare individual fields
    expected_fields.each_with_index do |expected, idx|
      actual = actual_fields[idx]
      next unless actual

      if expected[:name] != actual[:name]
        errors << "Field #{idx} name mismatch: expected '#{expected[:name]}', got '#{actual[:name]}'"
      end

      # Normalize types for comparison (strip whitespace)
      expected_type = normalize_type(expected[:type])
      actual_type = normalize_type(actual[:type])

      if expected_type != actual_type
        errors << "Field '#{expected[:name]}' type mismatch: expected '#{expected_type}', got '#{actual_type}'"
      end
    end

    record_result(swift_name, "struct", errors)
  end

  # ---------------------------------------------------------------------------
  # Enum Validation
  # ---------------------------------------------------------------------------

  def validate_enum(enum_defn, swift_name, content)
    errors = []

    # Check that it's declared as an enum with Int32
    unless content =~ /public enum #{Regexp.escape(swift_name)}: Int32, XDRCodable/
      errors << "Not declared as 'public enum #{swift_name}: Int32, XDRCodable'"
    end

    xdr_name = enum_defn.name.camelize

    # Build expected cases using the same logic as the generator
    raw_names = enum_defn.members.map { |m| m.name.to_s }
    normalized_names = raw_names.map { |n| n.underscore.upcase }
    prefix = @gen.detect_common_prefix(normalized_names)

    expected_cases = []
    enum_defn.members.each_with_index do |m, idx|
      raw_member_name = raw_names[idx]
      normalized = normalized_names[idx]

      if MEMBER_OVERRIDES.key?(xdr_name) && MEMBER_OVERRIDES[xdr_name].key?(raw_member_name)
        case_name = MEMBER_OVERRIDES[xdr_name][raw_member_name]
      else
        stripped = prefix.empty? ? normalized : normalized.sub(/\A#{Regexp.escape(prefix)}/, "")
        stripped = normalized if stripped.empty?
        case_name = @gen.mechanical_camel_case(stripped)
      end

      safe_case = @gen.swift_safe_name(case_name)
      expected_cases << { name: safe_case.to_s, value: m.value.to_s }
    end

    # Extract actual cases from Swift file
    actual_cases = []
    content.scan(/case\s+(`?\w+`?)\s*=\s*(-?\d+)/) do |match|
      actual_cases << { name: match[0], value: match[1] }
    end

    # Compare case count
    if expected_cases.length != actual_cases.length
      errors << "Case count mismatch: expected #{expected_cases.length}, got #{actual_cases.length}"
    end

    # Compare individual cases
    expected_cases.each_with_index do |expected, idx|
      actual = actual_cases[idx]
      next unless actual

      if expected[:name] != actual[:name]
        errors << "Case #{idx} name mismatch: expected '#{expected[:name]}', got '#{actual[:name]}'"
      end

      if expected[:value] != actual[:value]
        errors << "Case '#{expected[:name]}' value mismatch: expected #{expected[:value]}, got #{actual[:value]}"
      end
    end

    record_result(swift_name, "enum", errors)
  end

  # ---------------------------------------------------------------------------
  # Union Validation
  # ---------------------------------------------------------------------------

  def validate_union(union_defn, swift_name, content)
    errors = []

    # Check that it's declared as an enum (unions are Swift enums)
    # Unions use `public enum Name: XDRCodable` (no Int32)
    # Some are indirect
    unless content =~ /public\s+(?:indirect\s+)?enum\s+#{Regexp.escape(swift_name)}:\s+XDRCodable/
      errors << "Not declared as 'public [indirect] enum #{swift_name}: XDRCodable'"
    end

    # Build expected case entries using the generator's logic
    disc_info = @gen.resolve_discriminant_info(union_defn)
    case_entries = @gen.build_union_case_entries(union_defn, swift_name, disc_info)

    expected_cases = case_entries.map do |entry|
      case_name = @gen.swift_safe_name(entry[:case_name]).to_s
      {
        name: case_name,
        associated_type: entry[:associated_type],
        is_void: entry[:decode_style] == :void,
      }
    end

    # Extract actual cases from Swift file
    # Match: case name(Type) or case name
    actual_cases = []
    content.scan(/^\s*case\s+(`?\w+`?)(?:\(([^)]+)\))?(?:\s*$|\s*\/\/)/) do |match|
      cname = match[0]
      ctype = match[1]&.strip
      # Skip discriminant cases in `switch` statements
      actual_cases << { name: cname, associated_type: ctype, is_void: ctype.nil? }
    end

    # Sometimes the regex picks up switch cases too; filter to only enum case declarations.
    # The actual enum cases appear at the top of the enum body.
    # A more robust approach: find all case declarations between the enum opening and first
    # method declaration.
    actual_cases = extract_union_cases(content, swift_name)

    # Compare case count
    if expected_cases.length != actual_cases.length
      errors << "Case count mismatch: expected #{expected_cases.length}, got #{actual_cases.length}"
      errors << "  Expected: #{expected_cases.map { |c| c[:name] }.join(', ')}"
      errors << "  Actual:   #{actual_cases.map { |c| c[:name] }.join(', ')}"
    end

    # Compare individual cases
    expected_cases.each_with_index do |expected, idx|
      actual = actual_cases[idx]
      next unless actual

      if expected[:name] != actual[:name]
        errors << "Case #{idx} name mismatch: expected '#{expected[:name]}', got '#{actual[:name]}'"
      end

      if expected[:is_void] != actual[:is_void]
        if expected[:is_void]
          errors << "Case '#{expected[:name]}' should be void but has associated type '#{actual[:associated_type]}'"
        else
          errors << "Case '#{expected[:name]}' should have associated type '#{expected[:associated_type]}' but is void"
        end
      elsif !expected[:is_void] && expected[:associated_type] && actual[:associated_type]
        exp_type = normalize_type(expected[:associated_type])
        act_type = normalize_type(actual[:associated_type])
        if exp_type != act_type
          errors << "Case '#{expected[:name]}' type mismatch: expected '#{exp_type}', got '#{act_type}'"
        end
      end
    end

    record_result(swift_name, "union", errors)
  end

  # ---------------------------------------------------------------------------
  # Typedef Validation
  # ---------------------------------------------------------------------------

  def validate_typedef(typedef_defn, swift_name, content)
    errors = []
    decl = typedef_defn.declaration

    case decl
    when AST::Declarations::Array
      # Array typedefs are wrapped in a struct
      base = @gen.type_string(decl.type)
      field_name = @gen.resolve_field_name(swift_name, "wrapped")

      if content =~ /public struct #{Regexp.escape(swift_name)}: XDRCodable/
        # Verify the array field exists
        unless content =~ /(?:var|let)\s+#{Regexp.escape(field_name)}:\s+\[#{Regexp.escape(base)}\]/
          errors << "Array wrapper field '#{field_name}: [#{base}]' not found"
        end
      else
        errors << "Array typedef not declared as 'public struct #{swift_name}: XDRCodable'"
      end
    when AST::Declarations::Opaque
      target = @gen.type_string(decl.type)
      unless content =~ /public typealias #{Regexp.escape(swift_name)} = #{Regexp.escape(target)}/
        errors << "Opaque typedef expected 'typealias #{swift_name} = #{target}'"
      end
    when AST::Declarations::String
      unless content =~ /public typealias #{Regexp.escape(swift_name)} = String/
        errors << "String typedef expected 'typealias #{swift_name} = String'"
      end
    else
      target = @gen.type_string(decl.type)
      if decl.type.sub_type == :optional
        expected_pattern = /public typealias #{Regexp.escape(swift_name)} = #{Regexp.escape(target)}\?/
      else
        expected_pattern = /public typealias #{Regexp.escape(swift_name)} = #{Regexp.escape(target)}/
      end
      unless content =~ expected_pattern
        errors << "Typedef expected 'typealias #{swift_name} = #{target}#{decl.type.sub_type == :optional ? '?' : ''}'"
      end
    end

    record_result(swift_name, "typedef", errors)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def extract_union_cases(content, swift_name)
    cases = []

    # Find the enum body: from the opening brace after the enum declaration
    # to the first public init/func
    pattern = /public\s+(?:indirect\s+)?enum\s+#{Regexp.escape(swift_name)}[^{]*\{(.+)/m
    match = content.match(pattern)
    return cases unless match

    body = match[1]

    # Extract lines until we hit a method declaration or closing brace
    body.each_line do |line|
      line = line.strip
      break if line =~ /^public\s+(init|func)\b/

      if line =~ /^case\s+(`?\w+`?)\(([^)]+)\)\s*$/
        cases << { name: $1, associated_type: $2.strip, is_void: false }
      elsif line =~ /^case\s+(`?\w+`?)\s*$/
        cases << { name: $1, associated_type: nil, is_void: true }
      end
    end

    cases
  end

  def normalize_type(type_str)
    return nil if type_str.nil?
    type_str.strip.gsub(/\s+/, " ")
  end

  def record_result(swift_name, kind, errors)
    if errors.empty?
      @pass_count += 1
    else
      @fail_count += 1
      @failures << { name: swift_name, kind: kind, errors: errors }
    end
  end

  # ---------------------------------------------------------------------------
  # Report
  # ---------------------------------------------------------------------------

  def print_report
    total = @pass_count + @fail_count + @missing_count

    puts ""
    puts "=" * 72
    puts "XDR Generated Type Validation Report"
    puts "=" * 72
    puts ""
    puts "Total types checked:  #{total}"
    puts "  Passed:             #{@pass_count}"
    puts "  Failed:             #{@fail_count}"
    puts "  Missing files:      #{@missing_count}"
    puts "  Skipped:            #{@skip_count}"
    puts ""

    if @missing_types.any?
      puts "-" * 72
      puts "MISSING FILES (#{@missing_types.length}):"
      puts "-" * 72
      @missing_types.sort.each { |name| puts "  #{name}" }
      puts ""
    end

    if @failures.any?
      puts "-" * 72
      puts "FAILURES (#{@failures.length}):"
      puts "-" * 72
      @failures.sort_by { |f| f[:name] }.each do |failure|
        puts ""
        puts "  #{failure[:name]} (#{failure[:kind]}):"
        failure[:errors].each { |e| puts "    - #{e}" }
      end
      puts ""
    end

    if @fail_count == 0 && @missing_count == 0
      puts "All generated types passed validation."
    end

    puts "=" * 72
  end
end

# =============================================================================
# GeneratorHelper -- exposes Generator's private methods for validation
# =============================================================================

class GeneratorHelper
  def initialize
    # We need to create a minimal Generator-like object that exposes the
    # private helper methods. Since Generator inherits from Xdrgen::Generators::Base
    # and requires an output context, we use a delegate approach instead.
  end

  # Expose the name resolution method
  def name(named)
    raw_xdr_name = raw_xdr_qualified_name(named)

    if NAME_OVERRIDES.key?(raw_xdr_name)
      return NAME_OVERRIDES[raw_xdr_name]
    end

    xdr_name = named.name.camelize
    if NAME_OVERRIDES.key?(xdr_name)
      return NAME_OVERRIDES[xdr_name]
    end

    if named.is_a?(AST::Concerns::NestedDefinition)
      parent = name(named.parent_defn)
      "#{parent}#{xdr_name}XDR"
    else
      "#{xdr_name}XDR"
    end
  end

  def raw_xdr_qualified_name(named)
    xdr_name = named.name.camelize
    if named.is_a?(AST::Concerns::NestedDefinition)
      parent_raw = raw_xdr_qualified_name(named.parent_defn)
      "#{parent_raw}#{xdr_name}"
    else
      xdr_name
    end
  end

  def resolve_field_name(struct_name, xdr_field_name)
    field = swift_safe_name(xdr_field_name)
    if FIELD_OVERRIDES.key?(struct_name) && FIELD_OVERRIDES[struct_name].key?(field)
      FIELD_OVERRIDES[struct_name][field]
    else
      field
    end
  end

  def is_extension_point_field?(struct_name, field_name)
    EXTENSION_POINT_FIELDS.key?(struct_name) &&
      EXTENSION_POINT_FIELDS[struct_name].include?(field_name)
  end

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
      raise "quadruple not supported"
    when AST::Typespecs::String
      "String"
    when AST::Typespecs::Opaque
      if type.fixed? && [4, 12, 16, 32].include?(type.size.to_i)
        "WrappedData#{type.size.to_i}"
      else
        "Data"
      end
    when AST::Typespecs::Simple
      resolved = type.resolved_type
      if resolved.is_a?(AST::Definitions::Typedef)
        underlying = resolved.declaration.type
        if is_base_type?(underlying)
          return type_string(underlying)
        end
        if underlying.sub_type == :optional
          return type_string(underlying)
        end
      end
      resolved_name = name(resolved)
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

  def typedef_is_optional?(type)
    return false unless type.is_a?(AST::Typespecs::Simple)
    resolved = type.resolved_type
    return false unless resolved.is_a?(AST::Definitions::Typedef)
    resolved_name = name(resolved)
    return false if TYPE_OVERRIDES.key?(resolved_name)
    resolved.declaration.type.sub_type == :optional
  rescue
    false
  end

  # ---------------------------------------------------------------------------
  # Enum/Union name helpers (mirrored from Generator)
  # ---------------------------------------------------------------------------

  SWIFT_RESERVED_WORDS = Generator::SWIFT_RESERVED_WORDS

  DIGIT_WORDS = {
    "0" => "zero", "1" => "one", "2" => "two", "3" => "three",
    "4" => "four", "5" => "five", "6" => "six", "7" => "seven",
    "8" => "eight", "9" => "nine"
  }.freeze

  def swift_safe_name(identifier)
    identifier = identifier.to_s
    return "`#{identifier}`" if SWIFT_RESERVED_WORDS.include?(identifier)
    if identifier =~ /\A(\d)(.*)/
      word = DIGIT_WORDS[$1]
      rest = $2
      rest = rest.sub(/\A(.)/) { $1.upcase } unless rest.empty?
      identifier = "#{word}#{rest}"
    end
    identifier
  end

  def mechanical_camel_case(input)
    str = input.to_s
    parts = str.split("_")

    if parts.length == 1
      if str =~ /\A[A-Z][a-z]/
        return str[0].downcase + str[1..]
      else
        return str.downcase
      end
    end

    first = parts.first.downcase
    rest = parts[1..].map(&:capitalize)
    "#{first}#{rest.join}"
  end

  def detect_common_prefix(member_names)
    return "" if member_names.empty?

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

  def swift_enum_case_name(enum_name, member_name, enum_defn: nil)
    if MEMBER_OVERRIDES.key?(enum_name)
      overrides = MEMBER_OVERRIDES[enum_name]
      return overrides[member_name] if overrides.key?(member_name)
    end

    if enum_defn
      raw_names = enum_defn.members.map { |m| m.name.to_s }
      normalized_names = raw_names.map { |n| n.underscore.upcase }
      prefix = detect_common_prefix(normalized_names)
      normalized_member = member_name.to_s.underscore.upcase
      stripped = prefix.empty? ? normalized_member : normalized_member.sub(/\A#{Regexp.escape(prefix)}/, "")
      stripped = normalized_member if stripped.empty?
      return mechanical_camel_case(stripped)
    end

    mechanical_camel_case(member_name)
  end

  # ---------------------------------------------------------------------------
  # Union helpers (mirrored from Generator)
  # ---------------------------------------------------------------------------

  def resolve_discriminant_info(union)
    dtype = union.discriminant.type

    if dtype.respond_to?(:resolved_type)
      resolved = dtype.resolved_type
      if resolved.is_a?(AST::Definitions::Enum)
        xdr_name = resolved.name.camelize
        swift_name = name(resolved)
        skip_types = Generator::SKIP_TYPES

        if skip_types.include?(swift_name)
          return { kind: :skip_type_struct, swift_name: swift_name, xdr_name: xdr_name, enum_defn: resolved }
        else
          return { kind: :enum, swift_name: swift_name, xdr_name: xdr_name, enum_defn: resolved }
        end
      end
    end

    { kind: :int, swift_name: nil, xdr_name: nil, enum_defn: nil }
  end

  def build_union_case_entries(union, union_name, disc_info)
    entries = []
    seen_case_names = Set.new

    union.normal_arms.each do |arm|
      if arm.void?
        arm.cases.each do |c|
          case_name = swift_case_name_for_discriminant_value(c.value, disc_info)
          if MEMBER_OVERRIDES.key?(union_name) && MEMBER_OVERRIDES[union_name].key?(case_name)
            case_name = MEMBER_OVERRIDES[union_name][case_name]
          end
          next if seen_case_names.include?(case_name)
          seen_case_names.add(case_name)

          entries << {
            case_name: case_name,
            associated_type: nil,
            disc_expressions: [disc_match_expression(c.value, disc_info)],
            disc_return: disc_match_expression(c.value, disc_info),
            decode_style: :void,
            decode_type: nil,
          }
        end
      else
        assoc_type, decode_style = resolve_arm_type(arm)
        decode_type = resolve_arm_decode_type(arm)

        if arm.cases.length > 1
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
              disc_return: disc_match_expression(c.value, disc_info),
              decode_style: decode_style,
              decode_type: decode_type,
            }
          end
        else
          case_name = swift_safe_name(arm.name.to_s.camelize(:lower))
          if MEMBER_OVERRIDES.key?(union_name) && MEMBER_OVERRIDES[union_name].key?(case_name)
            case_name = MEMBER_OVERRIDES[union_name][case_name]
          end
          next if seen_case_names.include?(case_name)
          seen_case_names.add(case_name)

          entries << {
            case_name: case_name,
            associated_type: assoc_type,
            disc_expressions: arm.cases.map { |c| disc_match_expression(c.value, disc_info) },
            disc_return: disc_match_expression(arm.cases.first.value, disc_info),
            decode_style: decode_style,
            decode_type: decode_type,
          }
        end
      end
    end

    if union.default_arm.present?
      da = union.default_arm
      if da.void?
        entries << {
          case_name: "default_",
          associated_type: nil,
          disc_expressions: [:default],
          disc_return: "0",
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
          disc_return: "0",
          decode_style: decode_style,
          decode_type: resolve_arm_decode_type(da),
          is_default: true,
        }
      end
    end

    entries
  end

  def swift_case_name_for_discriminant_value(value, disc_info)
    if value.is_a?(AST::Identifier)
      xdr_name = disc_info[:xdr_name]
      swift_enum_case_name(xdr_name, value.name, enum_defn: disc_info[:enum_defn])
    else
      int_val = value.value.to_i
      int_val == 0 ? "void" : "v#{int_val}"
    end
  end

  def disc_match_expression(value, disc_info)
    if value.is_a?(AST::Identifier)
      case disc_info[:kind]
      when :skip_type_struct
        member_name = value.name
        xdr_name = disc_info[:xdr_name]
        if MEMBER_OVERRIDES.key?(xdr_name) && MEMBER_OVERRIDES[xdr_name].key?(member_name)
          constant = MEMBER_OVERRIDES[xdr_name][member_name]
        else
          constant = member_name
        end
        "#{disc_info[:swift_name]}.#{constant}"
      when :enum
        case_name = swift_enum_case_name(disc_info[:xdr_name], value.name, enum_defn: disc_info[:enum_defn])
        "#{disc_info[:swift_name]}.#{swift_safe_name(case_name)}.rawValue"
      end
    else
      value.value.to_s
    end
  end

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
end

# =============================================================================
# Main
# =============================================================================

if __FILE__ == $0
  project_root = File.expand_path("../../..", __dir__)
  generated_dir = File.join(project_root, "stellarsdk", "stellarsdk", "responses", "xdr")
  xdr_dir = File.join(project_root, "xdr")

  unless Dir.exist?(generated_dir)
    $stderr.puts "ERROR: Generated files directory not found: #{generated_dir}"
    exit 1
  end

  unless Dir.exist?(xdr_dir)
    $stderr.puts "ERROR: XDR directory not found: #{xdr_dir}"
    exit 1
  end

  validator = GeneratedTypeValidator.new(generated_dir, xdr_dir)
  validator.validate

  exit(validator.fail_count > 0 || validator.missing_count > 0 ? 1 : 0)
end
