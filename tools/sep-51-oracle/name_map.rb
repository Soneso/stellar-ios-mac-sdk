#!/usr/bin/env ruby
# frozen_string_literal: true

# Derives the SEP-0051 XDR-JSON name of every enum member, struct field and union
# arm directly from the .x sources, and checks the derivation against the pinned
# XDR-JSON reference CLI.
#
# The derivation rules come from the generator itself
# (tools/xdr-generator/generator/json_names.rb), so this check gates the code that
# actually emits the names rather than a second copy of it.
#
# Names are computed from the parsed .x AST rather than from generated Swift, so
# the tool keeps working when an XDR pin bump introduces types before any Swift
# exists for them. Swift type names come from the generator's own name resolution,
# so type_map.json keys match the type names the SDK ships.
#
# Usage:
#   ruby name_map.rb              Write name-map.json and type_map.json.
#   ruby name_map.rb --diff       Also probe the reference CLI for every enum
#                                 member and struct type it can resolve, and
#                                 report mismatches. Exits 1 if any name
#                                 disagrees with the reference.
#   ruby name_map.rb --check      Diff without writing anything, and report
#                                 whether the committed artefacts are current.
#                                 Exits 1 on a mismatch or a stale artefact,
#                                 so it can gate a build.
#   ruby name_map.rb --advisory   Diff against whatever build STELLAR_XDR names
#                                 instead of the pinned one, writing nothing. For
#                                 checking a new reference release before adopting
#                                 it; the pinned gates are unaffected.
#   ruby name_map.rb --diff --quiet   Diff, printing only the summary.
#   ruby name_map.rb --offline-check  Re-derive the names from the .x sources and
#                                 compare them with the committed name-map.json,
#                                 without the reference CLI. Answers "does the
#                                 committed table still match the .x?", which is
#                                 the half of the question a build machine with no
#                                 Rust toolchain can ask.
#
# Exit codes:
#   0  the derived names agree with the reference, and the artefacts are current
#   1  a name disagrees, or a committed artefact is stale
#   2  the reference CLI is missing or does not match the pin
#
# A caller that treats any non-zero exit as disagreement would report a missing
# CLI as a name mismatch, so the prerequisite failure is a distinct code.
#
# Types and enum members newer than the commit the reference CLI vendors are
# reported as unresolvable, never as mismatches; oracle-pin.json records both
# commits.

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../xdr-generator/Gemfile', __dir__)

require 'bundler/setup'
require 'xdrgen'
require 'base64'
require 'json'
require 'open3'
require 'set'
require 'tmpdir'
require_relative '../xdr-generator/generator/generator'
require_relative '../xdr-generator/generator/json_names'

Sep51Names = Sep51JsonNames
DerivationError = Sep51Names::DerivationError

# The reference CLI is absent or does not match the pin. Distinct from a name
# disagreement, because the two call for different responses: install the pinned
# build, versus fix the derivation.
PrerequisiteError = Class.new(StandardError)

SCRIPT_DIR = __dir__
XDR_DIR = File.expand_path('../../xdr', __dir__)
PIN_FILE = File.join(SCRIPT_DIR, 'oracle-pin.json')

# Structs that SEP-0051 renders as a single JSON string rather than an object:
# the integer-parts types become one base-10 decimal, and the account and
# signed-payload types become strkeys. They carry no JSON field names, so the
# field-name diff does not apply to them and reports them separately. A struct
# appearing here unexpectedly means a new type needs a string rendering; one
# disappearing means a type that used to be a string is now an object.
STRING_RENDERED_STRUCTS = %w[
  Int128Parts
  Int256Parts
  UInt128Parts
  UInt256Parts
  MuxedEd25519Account
  med25519
  ed25519SignedPayload
].freeze

# The reference implementation escapes a type name that collides with a reserved
# Rust type by prefixing "S", so Stellar-overlay.x's `struct Error` is addressed
# as SError. The escape changes only how the oracle is addressed, never a JSON
# key, so it is resolved here rather than in the naming rules.
ORACLE_RESERVED_ESCAPE = 'S'

# Reuses the generator's own Swift name resolution so type_map.json keys are the
# names the SDK ships, including every NAME_OVERRIDES deviation.
class SwiftNamer < Generator
  def initialize(top)
    super(top, nil)
  end

  def swift_name(definition) = name(definition)
  def xdr_qualified_name(definition) = raw_xdr_qualified_name(definition)

  # The Swift form a typedef takes, which decides whether it can carry members at
  # all: an array typedef becomes a struct, everything else collapses to a
  # typealias over a type that other typedefs also collapse to.
  def typedef_form(typedef)
    case typedef.declaration
    when AST::Declarations::Array then 'struct'
    else 'typealias'
    end
  end

  def typedef_target(typedef)
    declaration = typedef.declaration
    case declaration
    when AST::Declarations::Array then "[#{type_string(declaration.type)}]"
    when AST::Declarations::String then 'String'
    else
      target = type_string(declaration.type)
      declaration.type.sub_type == :optional ? "#{target}?" : target
    end
  end
end

# The parser sees every .x file as one concatenated document, so a definition's
# source file is recovered from where its text begins. Per-source emission and the
# per-source audits both need that provenance.
class SourceIndex
  def initialize(paths, separator_length)
    offset = 0
    @spans = paths.map do |path|
      length = File.read(path).length
      span = [offset, offset + length, File.basename(path)]
      offset += length + separator_length
      span
    end
  end

  def file_for(definition)
    position = definition.interval.first
    span = @spans.find { |start, stop, _| position >= start && position < stop }
    span ? span[2] : 'unknown'
  end
end

# Walks the parsed .x AST and produces the full name table.
class NameMapBuilder
  include Xdrgen::AST

  def initialize(top, source_index)
    @top = top
    @namer = SwiftNamer.new(top)
    @source_index = source_index
    @enums = []
    @structs = []
    @unions = []
    @typedefs = []
  end

  attr_reader :enums, :structs, :unions, :typedefs

  def build
    walk_definitions(@top)
    self
  end

  private

  def walk_definitions(node)
    node.definitions.each { |definition| visit(definition) }
    node.namespaces.each { |namespace| walk_definitions(namespace) }
  end

  def visit(definition)
    if definition.respond_to?(:nested_definitions)
      definition.nested_definitions.each { |nested| visit(nested) }
    end

    case definition
    when Definitions::Enum then @enums << describe_enum(definition)
    when Definitions::Struct then @structs << describe_struct(definition)
    when Definitions::Union then @unions << describe_union(definition)
    when Definitions::Typedef then @typedefs << describe_typedef(definition)
    end
  end

  # A typedef carries no JSON names of its own, so it takes no part in the name
  # diff. It is recorded because the Swift form decides where its JSON codec can
  # live: a typedef the language collapses to a typealias shares its Swift type
  # with every other typedef that collapses to the same target, and those targets
  # have different JSON renderings.
  def describe_typedef(typedef)
    identity(typedef).merge(
      'swift_form' => @namer.typedef_form(typedef),
      'swift_target' => @namer.typedef_target(typedef)
    )
  end

  def describe_enum(enum)
    identifiers = enum.members.map(&:name)
    identity(enum).merge(
      'members' => enum.members.map do |member|
        {
          'identifier' => member.name,
          'value' => member.value,
          'json' => Sep51Names.enum_member_json_name(member.name, identifiers)
        }
      end
    )
  end

  def describe_struct(struct)
    identity(struct).merge(
      'fields' => struct.members.map do |member|
        {
          'identifier' => member.name,
          'json' => Sep51Names.struct_field_json_name(member.name)
        }
      end
    )
  end

  # A union arm's key is the discriminant member's own JSON name, so an
  # enum-discriminated arm can never disagree with the enum's own rendering. An
  # integer-discriminated union keys its arms "v" followed by the case value.
  def describe_union(union)
    discriminant_enum = union.discriminant_type
    enum_discriminated = discriminant_enum.is_a?(Definitions::Enum)

    arms = union.arms.flat_map do |arm|
      if arm.is_a?(Definitions::UnionDefaultArm)
        [{ 'case' => 'default', 'json' => nil, 'void' => arm.void? }]
      else
        arm.cases.map do |kase|
          { 'case' => kase.value_s, 'json' => Sep51Names.union_arm_json_key(kase, union), 'void' => arm.void? }
        end
      end
    end

    identity(union).merge(
      'discriminant' => union.discriminant.name,
      'discriminant_kind' => enum_discriminated ? 'enum' : 'int',
      'discriminant_type' => enum_discriminated ? @namer.xdr_qualified_name(discriminant_enum) : nil,
      'arms' => arms
    )
  end

  def identity(definition)
    {
      'xdr_name' => definition.name,
      'xdr_qualified_name' => @namer.xdr_qualified_name(definition),
      'swift_name' => @namer.swift_name(definition),
      'source' => @source_index.file_for(definition)
    }
  end
end

# Drives the pinned reference CLI.
class Oracle
  UnknownType = Class.new(StandardError)

  attr_reader :version, :xdr_commit

  def initialize(pin, advisory: false)
    @cli = ENV.fetch('STELLAR_XDR', 'stellar-xdr')
    @pin = pin
    @advisory = advisory
    verify_pin
  end

  def types
    @types ||= run!('types', 'list').lines.map(&:strip).reject(&:empty?).to_set
  end

  def knows?(type) = types.include?(type)

  # Renders one enum member. XDR encodes an enum as a four-byte big-endian
  # signed integer, so a member is probed by decoding its own value.
  def decode_enum_member(type, value)
    encoded = Base64.strict_encode64([value].pack('l>'))
    output, status = run('decode', '--type', type, '--input', 'single-base64', '--output', 'json',
                         stdin: encoded)
    raise UnknownType, output.strip unless status.success?

    JSON.parse(output.strip, quirks_mode: true)
  end

  # The reference CLI orders schema properties alphabetically, so a schema is
  # evidence about field names only and says nothing about emission order.
  def struct_schema(type)
    output, status = run('types', 'schema', '--type', type)
    raise UnknownType, output.strip unless status.success?

    JSON.parse(output)
  end

  def self.field_names(schema)
    (schema['properties'] || {}).keys.reject { |key| key == '$schema' }.to_set
  end

  private

  def verify_pin
    output, status = run('version')
    unless status.success?
      raise PrerequisiteError, <<~MESSAGE
        '#{@cli} version' failed; is it the XDR reference CLI?
          #{output.strip}
        Install the pinned build with:
          #{@pin['install']}
      MESSAGE
    end

    @version = output.lines.first.to_s.split[1]
    @xdr_commit = output.lines.find { |line| line.start_with?('xdr:') }.to_s.split[1]
    version = @version
    xdr_commit = @xdr_commit

    return if version == @pin['version'] && xdr_commit == @pin['xdr_commit']

    # An advisory run exists precisely to probe a build other than the pinned one, so the
    # mismatch is the point rather than a failure. The build actually used is reported.
    return if @advisory

    raise PrerequisiteError, <<~MESSAGE
      reference CLI does not match oracle-pin.json.
          want: version #{@pin['version']}, xdr #{@pin['xdr_commit']}
          got:  version #{version}, xdr #{xdr_commit}
        Install the pinned build with:
          #{@pin['install']}
    MESSAGE
  end

  def run(*args, stdin: nil)
    output, error, status = Open3.capture3(@cli, *args, stdin_data: stdin.to_s)
    [status.success? ? output : "#{output}#{error}", status]
  rescue SystemCallError => e
    # The binary is absent or not executable, which Open3 reports by raising
    # rather than through an exit status.
    raise PrerequisiteError, <<~MESSAGE
      reference CLI #{@cli.inspect} could not be run: #{e.message}
      Install the pinned build with:
        #{@pin['install']}
      then ensure it is on PATH, or set STELLAR_XDR.
    MESSAGE
  end

  def run!(*args)
    output, status = run(*args)
    raise "#{@cli} #{args.join(' ')} failed: #{output}" unless status.success?

    output
  end
end

# Every .x file in xdr/ is generated, including the overlay, internal and exporter
# sources, so the whole directory is parsed. Compilation joins the sources with a
# newline before parsing, which SourceIndex has to account for.
SOURCE_SEPARATOR_LENGTH = 1

def load_ast
  sources = Dir.glob(File.join(XDR_DIR, '*.x')).sort

  if sources.empty?
    abort "No .x files in #{XDR_DIR}. Run 'make xdr-generate' first."
  end

  ast = Xdrgen::Compilation.new(sources, output_dir: Dir.tmpdir, namespace: 'name_map').ast
  [ast, SourceIndex.new(sources, SOURCE_SEPARATOR_LENGTH)]
end

# The reference CLI spells type names in UpperCamelCase of the .x identifier
# (SCVal becomes ScVal, PoolID becomes PoolId), escaping a name that collides with
# a reserved Rust type by prefixing "S". Nested types carry their parent's name,
# matching how this SDK names them.
def resolve_oracle_type(oracle, entry)
  candidate = Sep51Names.upper_camel(entry['xdr_qualified_name'])
  return candidate if oracle.knows?(candidate)

  escaped = "#{ORACLE_RESERVED_ESCAPE}#{candidate}"
  return escaped if oracle.knows?(escaped)

  oracle.types.find { |type| type.casecmp?(candidate) || type.casecmp?(escaped) }
end

def build_type_map(oracle, entries)
  mapping = {}
  unknown = []

  entries.each do |entry|
    resolved = resolve_oracle_type(oracle, entry)
    if resolved
      mapping[entry['swift_name']] = resolved
    else
      unknown << entry['swift_name']
    end
  end

  [mapping, unknown.uniq]
end

def diff(oracle, builder, quiet:)
  enum_total = 0
  enum_checked = 0
  enum_unresolvable = []
  struct_checked = 0
  struct_unresolvable = []
  mismatches = []

  builder.enums.each do |entry|
    type = resolve_oracle_type(oracle, entry)
    entry['members'].each do |member|
      enum_total += 1
      label = "#{entry['xdr_qualified_name']}.#{member['identifier']}"

      if type.nil?
        enum_unresolvable << label
        next
      end

      begin
        actual = oracle.decode_enum_member(type, member['value'])
      rescue Oracle::UnknownType
        enum_unresolvable << label
        next
      end

      enum_checked += 1
      next if actual == member['json']

      mismatches << "enum  #{label}: derived #{member['json'].inspect}, reference #{actual.inspect}"
    end
  end

  string_rendered = []

  builder.structs.each do |entry|
    type = resolve_oracle_type(oracle, entry)
    if type.nil?
      struct_unresolvable << entry['xdr_qualified_name']
      next
    end

    begin
      schema = oracle.struct_schema(type)
    rescue Oracle::UnknownType
      struct_unresolvable << entry['xdr_qualified_name']
      next
    end

    # A struct the reference renders as a string has no field names to compare.
    if schema['type'] != 'object'
      string_rendered << entry['xdr_name']
      unless STRING_RENDERED_STRUCTS.include?(entry['xdr_name'])
        mismatches << "struct #{entry['xdr_qualified_name']}: reference renders it as " \
                      "#{schema['type'].inspect}, not an object, and it is not a known " \
                      'string-rendered type'
      end
      next
    end

    struct_checked += 1
    derived = entry['fields'].map { |field| field['json'] }.to_set
    actual = Oracle.field_names(schema)
    next if derived == actual

    mismatches << "struct #{entry['xdr_qualified_name']}: derived #{derived.to_a.sort.inspect}, " \
                  "reference #{actual.to_a.sort.inspect}"
  end

  # A type the reference cannot resolve says nothing about its rendering, and it is already
  # reported as unresolvable, so it is not also counted as a lost string rendering.
  unresolvable_names = struct_unresolvable.map { |label| label.split('.').last }
  (STRING_RENDERED_STRUCTS - string_rendered - unresolvable_names).each do |name|
    mismatches << "struct #{name}: expected the reference to render it as a string, but it " \
                  'did not; its string rendering may have been dropped'
  end

  enum_mismatches = mismatches.count { |line| line.start_with?('enum ') }
  struct_mismatches = mismatches.count { |line| line.start_with?('struct ') }

  unless quiet
    puts
    puts "Unresolvable by reference CLI #{oracle.version} (newer than the XDR commit it vendors):"
    puts "  enum members (#{enum_unresolvable.length}):"
    enum_unresolvable.each { |label| puts "    #{label}" }
    puts "  struct types (#{struct_unresolvable.length}):"
    struct_unresolvable.each { |label| puts "    #{label}" }
    puts
    puts "Rendered as a string by the reference, so no field names to diff (#{string_rendered.length}):"
    string_rendered.sort.each { |label| puts "    #{label}" }
  end

  puts
  puts "SEP-0051 name derivation vs reference CLI #{oracle.version}"
  puts format('  enum members:  %d total, %d resolvable, %d matched, %d mismatched',
              enum_total, enum_checked, enum_checked - enum_mismatches, enum_mismatches)
  puts format('  struct types:  %d total, %d field-comparable, %d matched, %d mismatched ' \
              '(%d string-rendered, %d unresolvable)',
              builder.structs.length, struct_checked, struct_checked - struct_mismatches,
              struct_mismatches, string_rendered.length, struct_unresolvable.length)

  unless mismatches.empty?
    puts
    puts 'Mismatches:'
    mismatches.each { |line| puts "  #{line}" }
  end

  { enum_total: enum_total, enum_checked: enum_checked, enum_unresolvable: enum_unresolvable,
    struct_checked: struct_checked, struct_unresolvable: struct_unresolvable,
    string_rendered: string_rendered, mismatches: mismatches }
end

# Writes the artefact, or in check mode compares it with what is already committed and reports
# whether it is current. Returns true when the file on disk matches the freshly derived content.
def emit(name, content, check_only:)
  path = File.join(SCRIPT_DIR, name)

  unless check_only
    File.write(path, content)
    puts "Wrote #{path}"
    return true
  end

  committed = File.exist?(path) ? File.read(path) : nil
  if committed == content
    puts "Up to date: #{path}"
    true
  else
    puts "STALE: #{path} differs from the freshly derived table; re-run without --check"
    false
  end
end

# The committed name-map.json, as a plain document. The verification block is supplied by
# the caller: an oracle run has a fresh one, an offline run carries the committed one over.
def name_map_document(pin, builder, verification)
  document = {
    'oracle' => pin.slice('tool', 'version', 'xdr_commit'),
    'sdk_xdr_commit' => pin['sdk_xdr_commit'],
    'description' => 'SEP-0051 XDR-JSON names derived from the .x sources. Regenerate with ' \
                     'ruby tools/sep-51-oracle/name_map.rb --diff after any XDR pin bump.',
    'verification' => verification,
    'enums' => builder.enums,
    'structs' => builder.structs,
    'unions' => builder.unions,
    'typedefs' => builder.typedefs
  }
  # Round-tripped so the comparison in offline_check is between two documents in the same
  # form, rather than between a parsed one and freshly built Ruby objects.
  JSON.parse(JSON.generate(document))
end

# Compares the freshly derived names with the committed table without consulting the
# reference. The committed file's verification block is the record of the last oracle run,
# so it is carried over rather than compared: an offline run has nothing to say about it,
# and rebuilding it here would report every artefact as stale on a machine with no CLI.
# type_map.json is skipped for the same reason -- deciding which types the reference knows
# is the one thing that cannot be answered without asking it.
def offline_check(builder, pin)
  path = File.join(SCRIPT_DIR, 'name-map.json')
  unless File.exist?(path)
    warn "name_map.rb: #{path} does not exist; run 'ruby name_map.rb --diff' to create it."
    return 1
  end

  committed = JSON.parse(File.read(path))
  derived = name_map_document(pin, builder, committed['verification'])

  if committed == derived
    puts "Up to date: #{path} matches the names derived from the .x sources."
    puts "  #{builder.enums.length} enums, #{builder.structs.length} structs, " \
         "#{builder.unions.length} unions, #{builder.typedefs.length} typedefs."
    return 0
  end

  warn "STALE: #{path} does not match the names derived from the .x sources."
  %w[enums structs unions typedefs].each do |section|
    next if committed[section] == derived[section]

    warn "  #{section}: committed #{Array(committed[section]).length} entries, " \
         "derived #{derived[section].length}"
  end
  warn '  Regenerate with: ruby tools/sep-51-oracle/name_map.rb --diff'
  1
end

def main
  advisory = ARGV.include?('--advisory')
  check_only = ARGV.include?('--check')
  offline = ARGV.include?('--offline-check')
  # Checking without diffing would compare the artefacts against themselves and prove nothing.
  run_diff = !offline && (ARGV.include?('--diff') || check_only || advisory)
  quiet = ARGV.include?('--quiet')

  ast, source_index = load_ast
  builder = NameMapBuilder.new(ast, source_index).build

  pin = JSON.parse(File.read(PIN_FILE))
  exit offline_check(builder, pin) if offline

  oracle = Oracle.new(pin, advisory: advisory)

  if advisory
    puts "ADVISORY: comparing against #{oracle.version} (xdr #{oracle.xdr_commit}), " \
         "not the pinned #{pin['version']}."
    puts 'Nothing is written; the pinned gates are unaffected.'
    puts
  end

  entries = builder.enums + builder.structs + builder.unions + builder.typedefs
  type_map, unknown = build_type_map(oracle, entries)

  type_map_content =
    "#{JSON.pretty_generate(
      'oracle' => pin.slice('tool', 'version', 'xdr_commit'),
      'sdk_xdr_commit' => pin['sdk_xdr_commit'],
      'description' => 'Maps this SDK\'s generated XDR type names to the reference CLI\'s ' \
                       'spelling. The two differ in acronym casing, in the reserved-name ' \
                       'escape and in this SDK\'s XDR suffix, so a tool that guesses one ' \
                       'from the other reports resolvable types as unresolvable. ' \
                       'unknown_to_oracle lists every type the reference build does not ' \
                       'resolve, whatever the cause; the expected cause is a type added ' \
                       'after the XDR commit that build vendors.',
      'type_map' => type_map.sort.to_h,
      'unknown_to_oracle' => unknown.sort
    )}\n"

  result = run_diff ? diff(oracle, builder, quiet: quiet) : nil

  verification =
    if result
      {
        'enum_members_total' => result[:enum_total],
        'enum_members_checked' => result[:enum_checked],
        'enum_members_unresolvable' => result[:enum_unresolvable].sort,
        'struct_types_total' => builder.structs.length,
        'struct_types_field_comparable' => result[:struct_checked],
        'struct_types_string_rendered' => result[:string_rendered].sort,
        'struct_types_unresolvable' => result[:struct_unresolvable].sort,
        'mismatches' => result[:mismatches]
      }
    else
      'not verified in this run; re-run with --diff'
    end

  name_map_content = "#{JSON.pretty_generate(name_map_document(pin, builder, verification))}\n"

  puts
  if advisory
    # An advisory run reports and stops: the artefacts belong to the pinned build, so
    # neither writing them nor judging them stale against another build would be right.
    if result[:mismatches].empty?
      puts 'ADVISORY: every derived name matches this build. A pin bump would be routine.'
      exit 0
    end
    puts "ADVISORY: #{result[:mismatches].length} name(s) differ under this build."
    exit 1
  end

  current = emit('type_map.json', type_map_content, check_only: check_only)
  current &= emit('name-map.json', name_map_content, check_only: check_only)

  exit 1 if result && !result[:mismatches].empty?
  exit 1 unless current
end

if $PROGRAM_NAME == __FILE__
  begin
    main
  rescue PrerequisiteError => e
    warn "name_map.rb: #{e.message}"
    exit 2
  end
end
