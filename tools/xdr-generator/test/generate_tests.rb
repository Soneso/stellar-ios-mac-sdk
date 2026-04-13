#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# TxRep roundtrip test generator for the iOS/macOS Stellar SDK.
#
# Walks the XDR AST using the same infrastructure as the main generator
# (tools/xdr-generator/generator/generator.rb) and emits Swift XCTest
# roundtrip tests for every TxRep-participating type:
#
#   * Enums  - one test per case, verifying toTxRep/fromTxRep roundtrip.
#   * Structs - one test per type, verifying toTxRep -> parse -> fromTxRep
#               produces an instance whose XDR base64 equals the original's.
#   * Unions - one test per arm (void, scalar, struct, array), using the
#              same XDR-base64 roundtrip invariant as structs.
#
# Output:
#   stellarsdk/stellarsdkUnitTests/sep/txrep/generated/
#     GeneratedEnumTxRepTests.swift
#     GeneratedStructTxRepTests.swift
#     GeneratedUnionTxRepTests.swift
#
# Run:
#   cd tools/xdr-generator && bundle exec ruby test/generate_tests.rb
#
# Regeneration is idempotent: running twice produces byte-identical files.
# =============================================================================

require 'xdrgen'
require 'set'
require 'fileutils'
require_relative '../generator/generator'
require_relative '../generator/txrep_types'
require_relative 'txrep_test_values'

AST = Xdrgen::AST unless defined?(AST)

# Adapter that exposes the private helpers on Generator (name/swift_type_string/
# resolve_discriminant_info/build_union_case_entries/resolve_field_name/
# resolve_init_param_name/resolve_field_type/raw_xdr_qualified_name/
# typedef_is_optional?/swift_safe_name/resolve_size/find_struct_defn_for_swift_name).
# We never call `generate` on this instance; it exists solely as a handle to
# the generator's AST traversal and name resolution logic.
class GeneratorAdapter < Generator
  # Bypass render pipeline - we only use the instance as a helper container.
  def initialize(ast)
    @top = ast
    @constants = []
    @generated_files = Set.new
  end

  # Expose selected private methods under public names.
  [
    :name,
    :raw_xdr_qualified_name,
    :swift_type_string,
    :type_string,
    :resolve_discriminant_info,
    :build_union_case_entries,
    :resolve_field_name,
    :resolve_init_param_name,
    :resolve_field_type,
    :resolve_arm_type,
    :resolve_arm_decode_type,
    :typedef_is_optional?,
    :swift_safe_name,
    :resolve_size,
    :is_base_type?,
    :find_struct_defn_for_swift_name,
    :is_extension_point_field?,
    :walk_definitions,
  ].each do |m|
    define_method("pub_#{m}") { |*args, &blk| send(m, *args, &blk) }
  end
end

class TxRepTestGenerator
  OUTPUT_DIR = 'stellarsdk/stellarsdkUnitTests/sep/txrep/generated'

  MAX_DEPTH = 4

  def initialize
    @project_root = File.expand_path('../../..', __dir__)
    @type_registry = {} # swift_name => { kind:, defn: }
    @txrep_swift_names = Set.new
    @enum_tests = []
    @struct_tests = []
    @union_tests = []
  end

  def generate
    Dir.chdir(@project_root)
    xdr_files = Dir.glob('xdr/*.x').sort

    compilation = Xdrgen::Compilation.new(
      xdr_files,
      output_dir: '/dev/null/',
      generator: Generator,
      namespace: 'stellar',
    )
    top = compilation.send(:ast)

    @gen = GeneratorAdapter.new(top)

    # First pass: collect every definition keyed by its resolved Swift name.
    collect_definitions(top)

    # Precompute the set of Swift type names that participate in TxRep.
    @txrep_swift_names = TxRepTypes.resolved_swift_names(@gen)

    # Second pass: emit tests for each TxRep type (deterministic order).
    @txrep_swift_names.to_a.sort.each do |swift_name|
      info = @type_registry[swift_name]
      next unless info
      case info[:kind]
      when :enum
        @enum_tests.concat(generate_enum_tests(swift_name, info[:defn]))
      when :struct
        t = generate_struct_test(swift_name, info[:defn])
        @struct_tests << t if t
      when :union
        @union_tests.concat(generate_union_tests(swift_name, info[:defn]))
      when :typedef
        # TxRep on typedef wrappers is exercised via the structs that
        # reference them; no dedicated tests emitted here.
      end
    end

    out_dir = File.join(@project_root, OUTPUT_DIR)
    FileUtils.mkdir_p(out_dir)
    write_suite(File.join(out_dir, 'GeneratedEnumTxRepTests.swift'),
                'GeneratedEnumTxRepTests', @enum_tests)
    write_suite(File.join(out_dir, 'GeneratedStructTxRepTests.swift'),
                'GeneratedStructTxRepTests', @struct_tests)
    write_suite(File.join(out_dir, 'GeneratedUnionTxRepTests.swift'),
                'GeneratedUnionTxRepTests', @union_tests)

    puts "TxRep test generator:"
    puts "  enums:   #{@enum_tests.length} tests"
    puts "  structs: #{@struct_tests.length} tests"
    puts "  unions:  #{@union_tests.length} tests"
    puts "  total:   #{@enum_tests.length + @struct_tests.length + @union_tests.length}"
  end

  private

  # ---------------------------------------------------------------------------
  # AST collection
  # ---------------------------------------------------------------------------

  def collect_definitions(node)
    return unless node
    if node.respond_to?(:definitions)
      node.definitions.each { |defn| register_definition(defn) }
    end
    if node.respond_to?(:namespaces)
      node.namespaces.each { |ns| collect_definitions(ns) }
    end
  end

  def register_definition(defn)
    return if defn.is_a?(AST::Definitions::Const)
    return if defn.is_a?(AST::Definitions::Namespace)

    if defn.respond_to?(:nested_definitions)
      defn.nested_definitions.each { |nested| register_definition(nested) }
    end

    swift_name = safe_name(defn)
    return unless swift_name
    return if @type_registry.key?(swift_name)

    kind = case defn
           when AST::Definitions::Struct then :struct
           when AST::Definitions::Enum then :enum
           when AST::Definitions::Union then :union
           when AST::Definitions::Typedef then :typedef
           end
    return unless kind
    @type_registry[swift_name] = { kind: kind, defn: defn }
  end

  def safe_name(defn)
    @gen.pub_name(defn)
  rescue StandardError
    nil
  end

  # ---------------------------------------------------------------------------
  # Enum test generation
  # ---------------------------------------------------------------------------
  #
  # Emits a single XCTest method per enum case. Every generated enum has
  # enumName()/fromTxRepName(_:) plus toTxRep(prefix:lines:)/fromTxRep(_:prefix:),
  # so the invariant we test is:
  #
  #   var lines: [String] = []
  #   try original.toTxRep(prefix: "k", lines: &lines)
  #   let map  = parse(lines)
  #   let back = try EnumType.fromTxRep(map, prefix: "k")
  #   XCTAssertEqual(back, original)
  #
  # Every XDR enum generated by the iOS tool is Int32-backed and conforms to
  # Equatable, so the direct equality assertion is sufficient.
  def generate_enum_tests(swift_name, enum_defn)
    tests = []
    enum_defn.members.each do |m|
      raw = m.name.to_s
      case_name = swift_enum_case_name(swift_name, enum_defn, raw)
      sanitized = safe_test_id(raw)
      body = <<~SWIFT
        func test_#{swift_name}_#{sanitized}() throws {
            let original: #{swift_name} = .#{case_name}
            var lines: [String] = []
            try original.toTxRep(prefix: "k", lines: &lines)
            let map = Self.parseTxRepLines(lines)
            let decoded = try #{swift_name}.fromTxRep(map, prefix: "k")
            XCTAssertEqual(decoded, original, "TxRep roundtrip failed for #{swift_name}.#{case_name}")
        }
      SWIFT
      tests << body
    end
    tests
  end

  def swift_enum_case_name(enum_name, enum_defn, raw_name)
    # Use the generator's private swift_enum_case_name via the helper.
    @gen.send(:swift_enum_case_name, enum_defn.name.to_s, raw_name, enum_defn: enum_defn)
  end

  def safe_test_id(raw)
    # Swift test method names must be valid identifiers. Replace anything
    # that isn't [A-Za-z0-9_] with underscore.
    raw.gsub(/[^A-Za-z0-9_]/, '_')
  end

  # ---------------------------------------------------------------------------
  # Struct test generation
  # ---------------------------------------------------------------------------

  def generate_struct_test(swift_name, struct_defn)
    # Skip structs that are in the generator's SKIP_TYPES set - those are
    # hand-written and have their own hand-written TxRep tests.
    return nil if Generator::SKIP_TYPES.include?(swift_name)

    value_expr = TxRepTestValues.struct_expr(self, swift_name, struct_defn, 0)
    return nil unless value_expr

    <<~SWIFT
      func test_#{swift_name}_roundtrip() throws {
          let original: #{swift_name} = #{value_expr}
          var lines: [String] = []
          try original.toTxRep(prefix: "k", lines: &lines)
          let map = Self.parseTxRepLines(lines)
          let back = try #{swift_name}.fromTxRep(map, prefix: "k")
          let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
          let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
          XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for #{swift_name}")
      }
    SWIFT
  end

  # ---------------------------------------------------------------------------
  # Union test generation
  # ---------------------------------------------------------------------------

  # Unions whose TxRep surface is flattened into a parent type and is NOT
  # callable as `X.toTxRep(prefix:lines:)` / `X.fromTxRep(_:prefix:)`. The
  # parent types (TransactionXDR, etc.) own the serialization.
  UNION_NO_DIRECT_TXREP = Set[
    'TransactionExtXDR',
    'TransactionV0ExtXDR',
    'FeeBumpTransactionExtXDR',
  ].freeze

  def generate_union_tests(swift_name, union_defn)
    # Skip unions that the generator does not emit TxRep for directly.
    return [] if Generator::SKIP_TYPES.include?(swift_name)
    return [] if UNION_NO_DIRECT_TXREP.include?(swift_name)

    disc_info = @gen.pub_resolve_discriminant_info(union_defn)
    case_entries = @gen.pub_build_union_case_entries(union_defn, swift_name, disc_info)

    tests = []
    seen_cases = Set.new

    case_entries.each do |entry|
      next if entry[:is_default]
      case_name = entry[:case_name]
      next if seen_cases.include?(case_name)
      seen_cases.add(case_name)

      value_expr = TxRepTestValues.union_case_expr(self, swift_name, entry, 0)
      next unless value_expr

      sanitized = safe_test_id(case_name)
      tests << <<~SWIFT
        func test_#{swift_name}_#{sanitized}() throws {
            let original: #{swift_name} = #{value_expr}
            var lines: [String] = []
            try original.toTxRep(prefix: "k", lines: &lines)
            let map = Self.parseTxRepLines(lines)
            let back = try #{swift_name}.fromTxRep(map, prefix: "k")
            let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
            let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
            XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for #{swift_name}.#{case_name}")
        }
      SWIFT
    end

    tests
  end

  # ---------------------------------------------------------------------------
  # Accessors used by TxRepTestValues
  # ---------------------------------------------------------------------------

  public

  attr_reader :type_registry, :gen, :txrep_swift_names

  def lookup(swift_name)
    @type_registry[swift_name]
  end

  # ---------------------------------------------------------------------------
  # File writer
  # ---------------------------------------------------------------------------

  private

  HEADER = <<~SWIFT
    //
    // GENERATED FILE - DO NOT EDIT
    //
    // This file was produced by tools/xdr-generator/test/generate_tests.rb.
    // It emits TxRep roundtrip tests for every XDR type registered in
    // TxRepTypes.TXREP_XDR_NAMES. To regenerate, run:
    //
    //     make xdr-generate-tests
    //
    // Any manual edits will be overwritten on the next run.
    //

    import XCTest
    import stellarsdk
  SWIFT

  SHARED_HELPERS = <<~SWIFT
        // Parse TxRep lines ("key: value") into a key->value dictionary.
        //
        // Lines are written by the generated toTxRep methods with the format
        // "<key>: <value>". We split on the first ": " occurrence so values
        // that embed colons (rare, e.g. escaped strings) round-trip intact.
        static func parseTxRepLines(_ lines: [String]) -> [String: String] {
            var map: [String: String] = [:]
            for line in lines {
                if let range = line.range(of: ": ") {
                    let key = String(line[..<range.lowerBound])
                    let value = String(line[range.upperBound...])
                    map[key] = value
                } else {
                    map[line] = ""
                }
            }
            return map
        }
  SWIFT

  def write_suite(path, class_name, tests)
    body = String.new
    body << HEADER
    body << "\n"
    body << "final class #{class_name}: XCTestCase {\n\n"
    body << SHARED_HELPERS
    body << "\n"
    tests.sort.each do |t|
      t.each_line { |line| body << '    ' << line }
      body << "\n"
    end
    body << "}\n"

    File.write(path, body)
    puts "  wrote #{path}"
  end

end

TxRepTestGenerator.new.generate
