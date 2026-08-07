#!/usr/bin/env ruby
# frozen_string_literal: true

# SEP-0051 (XDR-JSON) test emitter for the iOS/macOS Stellar SDK.
#
# Walks the same XDR AST the main generator walks and emits XCTest suites covering every
# type that carries an XDR-JSON conversion:
#
#   * one round trip per type, from a deterministic fixture: value to tree, tree back to
#     value, and value to tree again, asserting both trees and both texts are equal, plus a
#     crossing into the binary codec so a disagreement between the two paths is visible;
#   * one test per enumeration member, pinning the wire string and the numeric value;
#   * one test per union arm;
#   * one rejection per type, and per union arm that carries a value a bare-string rejection
#     asserting the failure names that arm rather than the catch-all.
#
# Suites are partitioned by .x source file: one Swift file per source, which keeps each file
# openable and keeps an XDR bump's churn inside the sources it touched.
#
# It also emits the type-name-to-Swift dispatch that Sep51CorpusUnitTests drives, so the
# corpus reaches every type through the same AST the conversions are emitted from and an XDR
# bump cannot leave a hand-maintained switch behind.
#
# Output:
#   stellarsdk/stellarsdkUnitTests/sep/xdr_json/generated/
#
# Run:
#   cd tools/xdr-generator && bundle exec ruby test/emit_json_tests.rb
#
# Regeneration is idempotent: running twice produces byte-identical files.

require 'xdrgen'
require 'set'
require 'fileutils'
require_relative '../generator/generator'
require_relative 'json_test_values'

AST = Xdrgen::AST unless defined?(AST)

# Exposes the generator's private name resolution and SEP-0051 registries. The instance is
# never asked to render; it exists only as a handle on that logic, so the emitted tests and
# the emitted conversions read the same AST through the same code.
class Sep51GeneratorAdapter < Generator
  def initialize(ast)
    @top = ast
    @constants = []
    @generated_files = Set.new
    build_json_collapse_registry
  end

  [
    :name,
    :raw_xdr_qualified_name,
    :type_string,
    :resolve_discriminant_info,
    :build_union_case_entries,
    :resolve_field_name,
    :resolve_init_param_name,
    :resolve_field_type,
    :typedef_is_optional?,
    :swift_safe_name,
    :resolve_size,
    :is_extension_point_field?,
    :json_divergent?,
    :json_union_arms,
    :json_member_key,
    :swift_enum_case_name
  ].each do |method_name|
    define_method("pub_#{method_name}") do |*args, **options, &block|
      send(method_name, *args, **options, &block)
    end
  end

  # swift_enum_case_name takes its enum definition as a keyword, which the generic forwarder
  # above cannot express.
  def pub_swift_enum_case_name(enum_name, raw_name, enum_defn)
    swift_enum_case_name(enum_name, raw_name, enum_defn: enum_defn)
  end
end

class Sep51TestEmitter
  OUTPUT_DIR = 'stellarsdk/stellarsdkUnitTests/sep/xdr_json/generated'

  # The types the generator does not emit and whose conversions are hand-written instead.
  # Every SKIP_TYPE the .x set declares must appear here, or its tests would address members
  # that do not exist.
  HANDWRITTEN_CODECS = Set[
    'PublicKey',
    'MuxedAccountXDR',
    'MuxedAccountMed25519XDR',
    'TransactionXDR',
    'TransactionV0XDR',
    'FeeBumpTransactionXDR',
    'TransactionV0EnvelopeXDR',
    'TransactionV1EnvelopeXDR',
    'FeeBumpTransactionEnvelopeXDR'
  ].freeze

  # Values no XDR type renders, used to pin that an unknown name is reported rather than
  # mapped onto some arm or member.
  UNKNOWN_ENUM_VALUE = 'not_a_declared_member'
  UNKNOWN_UNION_ARM = 'not_a_declared_arm'

  # Types the corpus dispatch cannot carry, with the reason. The dispatch crosses the binary
  # codec in both directions, and XDRDecoder.decode requires XDRDecodable; Optional conforms
  # only to XDREncodable (XDRCodableExtensions.swift), so an optional typedef has no decode
  # path at all. A corpus entry naming one of these fails Sep51CorpusUnitTests' completeness
  # assertion rather than passing unnoticed, and a name that stops being a declared type
  # stops the emitter.
  UNDISPATCHABLE = {
    'SponsorshipDescriptorXDR' =>
      'renders as PublicKey?, and Optional carries no XDRDecodable conformance'
  }.freeze

  def initialize
    @project_root = File.expand_path('../../..', __dir__)
    @registry = {}
    @sources = {}
    @order = []
    @suites = Hash.new { |hash, key| hash[key] = [] }
    @unfabricated = []
  end

  def generate
    Dir.chdir(@project_root)
    xdr_files = Dir.glob('xdr/*.x').sort
    abort "No .x files in xdr/. Run 'make xdr-generate' first." if xdr_files.empty?

    compilation = Xdrgen::Compilation.new(
      xdr_files,
      output_dir: '/dev/null/',
      generator: Generator,
      namespace: 'stellar'
    )
    top = compilation.send(:ast)

    unless top.namespaces.length == xdr_files.length
      raise "SEP-0051 test emitter: #{xdr_files.length} source files produced " \
            "#{top.namespaces.length} namespaces, so a definition cannot be attributed to " \
            'the file that declares it'
    end

    @gen = Sep51GeneratorAdapter.new(top)

    top.namespaces.each_with_index do |namespace, index|
      source = File.basename(xdr_files[index])
      namespace.definitions.each { |defn| register(defn, source) }
    end

    verify_handwritten_coverage
    verify_undispatchable_names
    @order.each { |swift_name| emit_for(swift_name) }
    write_suites
    write_dispatch
    report
  end

  # Accessor used by Sep51JsonTestValues.
  attr_reader :gen

  def lookup(swift_name) = @registry[swift_name]

  private

  # -- Registration -----------------------------------------------------------

  def register(defn, source)
    defn.nested_definitions.each { |nested| register(nested, source) } if
      defn.respond_to?(:nested_definitions)

    kind = case defn
           when AST::Definitions::Struct then :struct
           when AST::Definitions::Enum then :enum
           when AST::Definitions::Union then :union
           when AST::Definitions::Typedef then :typedef
           end
    return unless kind

    swift_name = @gen.pub_name(defn)
    return if swift_name.nil? || @registry.key?(swift_name)

    @registry[swift_name] = { kind: kind, defn: defn }
    @sources[swift_name] = source
    @order << swift_name
  end

  def verify_handwritten_coverage
    missing = Generator::SKIP_TYPES.select do |type|
      @registry.key?(type) && !HANDWRITTEN_CODECS.include?(type)
    end
    return if missing.empty?

    raise "SEP-0051 test emitter: #{missing.join(', ')} is generated as a hand-written type " \
          'but has no entry in HANDWRITTEN_CODECS, so the emitter cannot tell whether it ' \
          'carries a conversion'
  end

  def verify_undispatchable_names
    stale = UNDISPATCHABLE.keys.reject { |type| @registry.key?(type) }
    return if stale.empty?

    raise "SEP-0051 test emitter: #{stale.join(', ')} is excluded from the corpus dispatch " \
          'but is no longer a declared type, so the exclusion can no longer be justified'
  end

  # -- Dispatch ---------------------------------------------------------------

  def emit_for(swift_name)
    info = @registry[swift_name]

    # A Swift type several XDR definitions render differently carries no conversion of its
    # own. The per-arm helpers that replace it are reached through the union that selects
    # them, which is where those arms are exercised.
    return if @gen.pub_json_divergent?(swift_name)

    tests =
      case info[:kind]
      when :enum then enum_tests(swift_name, info[:defn])
      when :struct then struct_tests(swift_name, info[:defn])
      when :union then union_tests(swift_name, info[:defn])
      when :typedef then typedef_tests(swift_name, info[:defn])
      end

    @suites[@sources[swift_name]].concat(tests)
  end

  def overridden?(swift_name)
    !Sep51JsonOverrides.nominal(swift_name).nil? ||
      !Sep51JsonOverrides.typedef(swift_name).nil?
  end

  def handwritten?(swift_name) = HANDWRITTEN_CODECS.include?(swift_name)

  # A typedef Swift renders as a typealias carries no members; its conversion lives in a
  # namespace beside it. An array typedef becomes a struct and carries the members directly.
  def json_codec_namespace(swift_name)
    info = @registry[swift_name]
    return nil unless info[:kind] == :typedef
    return nil if info[:defn].declaration.is_a?(AST::Declarations::Array)

    "#{swift_name}JsonCodec"
  end

  # -- Enums ------------------------------------------------------------------

  def enum_tests(swift_name, defn)
    identifiers = defn.members.map(&:name)
    tests = defn.members.map do |member|
      wire = Sep51JsonNames.enum_member_json_name(member.name, identifiers)
      case_name = @gen.pub_swift_enum_case_name(defn.name.to_s, member.name.to_s, defn)
      <<~SWIFT
        func test_#{swift_name}_#{identifier(member.name)}() throws {
            let value: #{swift_name} = .#{case_name}
            XCTAssertEqual(try value.toXdrJson(), "\\"#{wire}\\"",
                           "#{swift_name}.#{case_name} must render as #{wire}")
            XCTAssertEqual(value.rawValue, Int32(#{member.value}),
                           "#{swift_name}.#{case_name} must keep its XDR value")
            XCTAssertEqual(try #{swift_name}.fromXdrJson("\\"#{wire}\\""), value,
                           "#{wire} must read back as #{swift_name}.#{case_name}")
        }
      SWIFT
    end

    tests << <<~SWIFT
      func test_#{swift_name}_rejectsUndeclaredValue() throws {
          XCTAssertThrowsError(try #{swift_name}.fromXdrJson("\\"#{UNKNOWN_ENUM_VALUE}\\"")) { error in
              guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                  return XCTFail("#{swift_name}: expected unknownEnumValue, got \\(error)")
              }
              XCTAssertEqual(type, "#{swift_name}")
              XCTAssertEqual(value, "#{UNKNOWN_ENUM_VALUE}")
          }
      }
    SWIFT
    tests
  end

  # -- Structs ----------------------------------------------------------------

  def struct_tests(swift_name, defn)
    value = Sep51JsonTestValues.struct_expr(self, swift_name, defn, 0)
    return record_unfabricated(swift_name) unless value

    [round_trip(swift_name, swift_name, value, binary: true),
     rejects_wrong_shape(swift_name, swift_name)]
  end

  # -- Unions -----------------------------------------------------------------

  def union_tests(swift_name, defn)
    # A hand-written union's Swift cases are not the ones the .x implies, so it is exercised
    # through one fixture rather than arm by arm.
    if handwritten?(swift_name)
      value = Sep51JsonTestValues.type_expr(self, swift_name, 0)
      return record_unfabricated(swift_name) unless value

      return [round_trip(swift_name, swift_name, value, binary: true),
              rejects_wrong_shape(swift_name, swift_name)]
    end

    discriminant = @gen.pub_resolve_discriminant_info(defn)
    entries = @gen.pub_build_union_case_entries(defn, swift_name, discriminant)
    arms = @gen.pub_json_union_arms(defn, swift_name, entries, label: swift_name)
    keys = arms.to_h { |arm| [arm[:swift_case], arm] }

    tests = []
    seen = Set.new
    entries.each do |entry|
      next if entry[:is_default]
      next unless seen.add?(entry[:case_name])

      arm = keys[entry[:case_name]]
      next unless arm

      value = Sep51JsonTestValues.union_case_expr(self, entry, 0)
      unless value
        record_unfabricated("#{swift_name}.#{entry[:case_name]}")
        next
      end

      tests << round_trip(swift_name, "#{swift_name}_#{identifier(entry[:case_name])}",
                          value, binary: true, declared: swift_name)

      # A bespoke conversion chooses its own shape, so only the shapes this emitter derives
      # carry the structural rejections below.
      next if overridden?(swift_name)
      next if arm[:void]

      tests << <<~SWIFT
        func test_#{swift_name}_#{identifier(entry[:case_name])}_rejectsBareString() throws {
            XCTAssertThrowsError(try #{swift_name}.fromXdrJson("\\"#{arm[:key]}\\"")) { error in
                guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                    return XCTFail("#{swift_name}.#{arm[:key]}: expected invalidValue, got \\(error)")
                }
                XCTAssertEqual(type, "#{swift_name}")
                XCTAssertEqual(key, "#{arm[:key]}",
                               "the failure must name the arm rather than the catch-all")
            }
        }
      SWIFT
    end

    tests << if overridden?(swift_name)
               rejects_wrong_shape(swift_name, swift_name)
             else
               <<~SWIFT
                 func test_#{swift_name}_rejectsUndeclaredArm() throws {
                     XCTAssertThrowsError(try #{swift_name}.fromXdrJson("\\"#{UNKNOWN_UNION_ARM}\\"")) { error in
                         guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                             return XCTFail("#{swift_name}: expected unknownUnionArm, got \\(error)")
                         }
                         XCTAssertEqual(type, "#{swift_name}")
                         XCTAssertEqual(key, "#{UNKNOWN_UNION_ARM}")
                     }
                 }
               SWIFT
             end
    tests
  end

  # -- Typedefs ---------------------------------------------------------------

  def typedef_tests(swift_name, defn)
    value = Sep51JsonTestValues.typedef_expr(self, swift_name, defn, 0)
    return record_unfabricated(swift_name) unless value

    if defn.declaration.is_a?(AST::Declarations::Array)
      # An array typedef becomes a struct, so it carries the conversion directly.
      return [round_trip(swift_name, swift_name, value, binary: true),
              rejects_wrong_shape(swift_name, swift_name, input: '"not_an_array"')]
    end

    codec = "#{swift_name}JsonCodec"
    [<<~SWIFT, <<~REJECT]
      func test_#{swift_name}_roundTrip() throws {
          let original: #{swift_name} = #{value}
          let tree = try #{codec}.toXdrJsonValue(original)
          let json = try #{codec}.toXdrJson(original)
          let decoded = try #{codec}.fromXdrJson(json)
          let viaValue = try #{codec}.fromXdrJsonValue(tree)
          let viaTree = try #{codec}.fromXdrJsonTree(tree)
          XCTAssertEqual(try #{codec}.toXdrJsonValue(decoded), tree,
                         "#{swift_name} must produce the same tree after a round trip")
          XCTAssertEqual(try #{codec}.toXdrJson(decoded), json,
                         "#{swift_name} must produce the same text after a round trip")
          XCTAssertEqual(try #{codec}.toXdrJson(viaValue), json,
                         "#{swift_name} must read a tree the same way it reads text")
          XCTAssertEqual(try #{codec}.toXdrJson(viaTree), json,
                         "#{swift_name} must read a depth-checked tree the same way")
      }
    SWIFT
      func test_#{swift_name}_rejectsWrongShape() throws {
          XCTAssertThrowsError(try #{codec}.fromXdrJson("[]")) { error in
              XCTAssertTrue(error is XdrJsonError,
                            "#{swift_name} must report a shape it cannot read as an XdrJsonError")
          }
      }
    REJECT
  end

  # -- Shared test bodies -----------------------------------------------------

  def round_trip(swift_name, test_id, value, binary:, declared: nil)
    type = declared || swift_name
    crossing =
      if binary
        <<~SWIFT.chomp
          \n    let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
              XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                             originalBase64,
                             "#{swift_name} must reach the same bytes through JSON and XDR")
        SWIFT
      else
        ''
      end

    <<~SWIFT
      func test_#{test_id}_roundTrip() throws {
          let original: #{type} = #{value}
          let tree = try original.toXdrJsonValue()
          let json = try original.toXdrJson()
          let decoded = try #{type}.fromXdrJson(json)
          let viaValue = try #{type}.fromXdrJsonValue(tree)
          let viaTree = try #{type}.fromXdrJsonTree(tree)
          XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                         "#{swift_name} must produce the same tree after a round trip")
          XCTAssertEqual(try decoded.toXdrJson(), json,
                         "#{swift_name} must produce the same text after a round trip")
          XCTAssertEqual(try viaValue.toXdrJson(), json,
                         "#{swift_name} must read a tree the same way it reads text")
          XCTAssertEqual(try viaTree.toXdrJson(), json,
                         "#{swift_name} must read a depth-checked tree the same way")#{crossing}
      }
    SWIFT
  end

  def rejects_wrong_shape(swift_name, type, input: '[]')
    literal = input.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
    <<~SWIFT
      func test_#{swift_name}_rejectsWrongShape() throws {
          XCTAssertThrowsError(try #{type}.fromXdrJson("#{literal}")) { error in
              XCTAssertTrue(error is XdrJsonError,
                            "#{swift_name} must report a shape it cannot read as an XdrJsonError")
          }
      }
    SWIFT
  end

  def record_unfabricated(label)
    @unfabricated << label
    []
  end

  def identifier(raw) = raw.to_s.delete('`').gsub(/[^A-Za-z0-9_]/, '_')

  # -- Output -----------------------------------------------------------------

  HEADER = <<~SWIFT
    //
    // GENERATED FILE - DO NOT EDIT
    //
    // This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It exercises
    // the SEP-0051 (XDR-JSON) conversions of every type declared in one .x source. To
    // regenerate, run:
    //
    //     make xdr-generate-tests
    //
    // Any manual edits will be overwritten on the next run.
    //

    import XCTest
    import Foundation
    import stellarsdk
  SWIFT

  def write_suites
    directory = File.join(@project_root, OUTPUT_DIR)
    FileUtils.mkdir_p(directory)

    @suites.keys.sort.each do |source|
      class_name = suite_name(source)
      path = File.join(directory, "#{class_name}.swift")
      body = String.new
      body << HEADER
      body << "\n"
      body << "final class #{class_name}: XCTestCase {\n"
      @suites[source].sort.each do |test|
        body << "\n"
        test.each_line { |line| body << (line.strip.empty? ? "\n" : "    #{line}") }
      end
      body << "}\n"
      File.write(path, body)
      puts "  wrote #{path} (#{@suites[source].length} tests)"
    end
  end

  # -- Corpus dispatch --------------------------------------------------------

  DISPATCH_CLASS = 'GeneratedXdrJsonCorpusDispatch'

  DISPATCH_HEADER = <<~SWIFT
    //
    // GENERATED FILE - DO NOT EDIT
    //
    // This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It maps the
    // type names carried by stellarsdkUnitTests/sep/xdr_json/corpus.json onto the SEP-0051
    // (XDR-JSON) conversion of the corresponding Swift type, in both directions, crossing
    // the binary codec so one corpus entry pins the JSON text and the XDR bytes together.
    // To regenerate, run:
    //
    //     make xdr-generate-tests
    //
    // Any manual edits will be overwritten on the next run.
    //

    import Foundation
    import stellarsdk
  SWIFT

  def write_dispatch
    names = @order.reject { |swift_name| @gen.pub_json_divergent?(swift_name) }
                  .reject { |swift_name| UNDISPATCHABLE.key?(swift_name) }
                  .sort

    body = String.new
    body << DISPATCH_HEADER
    body << "\n"
    body << dispatch_error_type
    body << "\n"
    body << "enum #{DISPATCH_CLASS} {\n"
    body << "\n"
    body << dispatch_emit_function(names)
    body << "\n"
    body << dispatch_read_function(names)
    body << "\n"
    body << dispatch_type_set(names)
    body << "}\n"

    path = File.join(@project_root, OUTPUT_DIR, "#{DISPATCH_CLASS}.swift")
    File.write(path, body)
    @dispatched = names
    puts "  wrote #{path} (#{names.length} types)"
  end

  def dispatch_error_type
    <<~SWIFT
      /// A corpus entry the dispatch cannot serve. Both switches throw rather than skip: a
      /// type quietly stepped over is a type the corpus never tested.
      enum Sep51CorpusDispatchError: Error, CustomStringConvertible {
          case unknownType(String)
          case malformedBase64(String)

          var description: String {
              switch self {
              case .unknownType(let iosType):
                  return "SEP-0051 corpus: no XDR-JSON dispatch for \\(iosType). "
                      + "Run make xdr-generate-tests."
              case .malformedBase64(let iosType):
                  return "SEP-0051 corpus: the xdr of a \\(iosType) entry is not valid base64."
              }
          }
      }
    SWIFT
  end

  def dispatch_emit_function(names)
    cases = names.map do |swift_name|
      codec = json_codec_namespace(swift_name)
      emit = codec ? "#{codec}.toXdrJson(value)" : 'value.toXdrJson()'
      <<~SWIFT
        case "#{swift_name}":
            let value = try XDRDecoder.decode(#{swift_name}.self, data: data)
            return try #{emit}
      SWIFT
    end

    indent(<<~SWIFT)
      /// Reads the base64 XDR with the binary codec and emits the value's XDR-JSON text.
      static func json(forType iosType: String, xdrBase64: String) throws -> String {
          guard let data = Data(base64Encoded: xdrBase64) else {
              throw Sep51CorpusDispatchError.malformedBase64(iosType)
          }
          switch iosType {
      #{indent(cases.join, 1).chomp}
          default:
              throw Sep51CorpusDispatchError.unknownType(iosType)
          }
      }
    SWIFT
  end

  def dispatch_read_function(names)
    cases = names.map do |swift_name|
      codec = json_codec_namespace(swift_name)
      read = codec ? "#{codec}.fromXdrJson(json)" : "#{swift_name}.fromXdrJson(json)"
      <<~SWIFT
        case "#{swift_name}":
            let value = try #{read}
            return try Data(XDREncoder.encode(value)).base64EncodedString()
      SWIFT
    end

    indent(<<~SWIFT)
      /// Reads the XDR-JSON text and emits the base64 XDR the binary codec encodes it to.
      static func xdrBase64(forType iosType: String, json: String) throws -> String {
          switch iosType {
      #{indent(cases.join, 1).chomp}
          default:
              throw Sep51CorpusDispatchError.unknownType(iosType)
          }
      }
    SWIFT
  end

  def dispatch_type_set(names)
    entries = names.map { |swift_name| "\"#{swift_name}\",\n" }
    indent(<<~SWIFT)
      /// Every type name the two switches above handle.
      static let dispatchedTypes: Set<String> = [
      #{indent(entries.join, 1).chomp}
      ]
    SWIFT
  end

  def indent(text, levels = 1)
    pad = '    ' * levels
    text.each_line.map { |line| line.strip.empty? ? line : "#{pad}#{line}" }.join
  end

  # Stellar-contract-config-setting.x becomes GeneratedXdrJsonStellarContractConfigSettingUnitTests.
  def suite_name(source)
    stem = File.basename(source, '.x').split(/[-_]/).map { |word| word.sub(/\A[a-z]/, &:upcase) }
    "GeneratedXdrJson#{stem.join}UnitTests"
  end

  def report
    total = @suites.values.sum(&:length)
    puts 'SEP-0051 test emitter:'
    puts "  sources:    #{@suites.keys.length}"
    puts "  tests:      #{total}"
    puts "  dispatched: #{@dispatched.length}"
    return if @unfabricated.empty?

    puts "  no fixture could be built for #{@unfabricated.length}:"
    @unfabricated.sort.each { |label| puts "    #{label}" }
  end
end

Sep51TestEmitter.new.generate
