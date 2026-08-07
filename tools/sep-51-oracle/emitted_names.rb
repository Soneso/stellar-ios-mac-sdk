#!/usr/bin/env ruby
# frozen_string_literal: true

# Diffs the SEP-0051 XDR-JSON names that actually reached the generated Swift against
# name-map.json, the table name_map.rb derives from the .x sources and checks against the
# pinned reference CLI.
#
# This closes a gap name_map.rb cannot close. That tool proves the derivation module agrees
# with the reference, but it calls the module the same way for every type, so it can only
# ever confirm that the rules are right. It says nothing about how the generator invokes
# them: a wrong sibling list handed to the enum prefix computation, a key emitted under the
# wrong field, a struct whose keys come out in the wrong order, or a type-level override that
# stopped being applied would all leave name_map.rb green and ship wrong JSON. Reading the
# emitted Swift back is the only check that sees those.
#
# The concrete hazard it guards is visible in this repo: xdr/Stellar-overlay.x declares
# IPv4 and IPv6, the generator's camel-casing renders them as the Swift cases pv4 and pv6,
# and the SEP-0051 wire strings are i_pv4 and i_pv6. An emitter fed the Swift case names
# would emit "pv4", which round-trips against itself perfectly and is invisible to every
# round-trip test.
#
# Enum members are matched by their numeric value rather than by name, because the Swift
# case name is the generator's own rendering and does not appear in the .x sources.
#
# Usage:
#   ruby emitted_names.rb           Report the diff.
#   ruby emitted_names.rb --quiet   Print only the summary and any problems.
#
# Exit codes:
#   0  every emitted name matches the table
#   1  a name mismatches, or a name or file is missing or extra
#   2  the JSON emitter has not run, so there are no emitted names to read
#
# Never writes anything.

require 'json'
require 'set'

SCRIPT_DIR = __dir__
ROOT = File.expand_path('../..', __dir__)
NAME_MAP = File.join(SCRIPT_DIR, 'name-map.json')
OVERRIDES_FILE = File.join(ROOT, 'tools/xdr-generator/generator/json_overrides.rb')

# Generated XDR types live in one directory; PublicKey is hand-maintained beside the
# cryptography it belongs to, and is the only type outside it.
SOURCE_DIRS = [
  File.join(ROOT, 'stellarsdk/stellarsdk/responses/xdr'),
  File.join(ROOT, 'stellarsdk/stellarsdk/crypto')
].freeze

# Conversions for the types the generator does not emit are hand-written here, several
# types to a file, so they are located by the extension they declare rather than by name.
HANDWRITTEN_DIR = File.join(ROOT, 'stellarsdk/stellarsdk/xdr_json/handwritten')

# The emitted shapes this tool reads. They describe what the JSON conversions produce and
# must be kept in step with them; a shape that stops matching is reported as a missing
# emission rather than passing silently, and the compared-name counts in the summary make
# a vacuous run visible.
EMISSION_MARKER = 'toXdrJsonValue'
# A Swift enum case declaration carries the discriminant the XDR wire uses.
ENUM_CASE_VALUE = /^\s*case\s+(`?\w+`?)\s*=\s*(-?\d+)\s*$/
# The emission a type builds, found by signature and read to its matching brace. Reading
# braces rather than indentation is what lets one tool cover both the generated files, at
# two spaces, and the hand-written ones, at four.
EMIT_SIGNATURE = 'func toXdrJsonValue() throws -> XdrJsonValue'
DECODE_SIGNATURE = 'static func fromXdrJsonValue(_ value: XdrJsonValue) throws ->'
# The enum emission: one arm per member, rendering the wire string.
ENUM_JSON_ARM = /case\s+\.(`?\w+`?):\s*return\s+\.string\("([^"]+)"\)/
# The keys an emitting struct writes, in emission order.
STRUCT_JSON_KEY = /XdrJsonMember\(\s*\n?\s*key: "([^"]+)"/
# The arm keys a union dispatches on when reading.
UNION_DECODE_KEY = /case\s+"([^"]+)":/

# Reads the block a signature opens, from its `{` to the matching `}`. String literals are
# skipped so a brace inside a message cannot end the block early.
def block_after(source, signature)
  start = source&.index(signature)
  return nil if start.nil?

  index = source.index('{', start + signature.length)
  return nil if index.nil?

  depth = 0
  in_string = false
  body_start = index + 1
  while index < source.length
    character = source[index]
    if in_string
      if character == '\\'
        index += 2
        next
      end
      in_string = false if character == '"'
    elsif character == '"'
      in_string = true
    elsif character == '{'
      depth += 1
    elsif character == '}'
      depth -= 1
      return source[body_start...index] if depth.zero?
    end
    index += 1
  end
  nil
end

# Types whose JSON form is a single string rather than an object or a keyed arm, so they
# carry no derived names to diff. Read from the generator's own registry, so a type entering
# or leaving it is reported rather than silently excused.
def load_overridden
  return Set.new unless File.exist?(OVERRIDES_FILE)

  require OVERRIDES_FILE
  Sep51JsonOverrides.type_names.to_set
end

# The name of the per-arm conversion a collapsed definition is emitted under. The generator
# derives it from the XDR name so the two shapes of a collapsed Swift type stay
# distinguishable both in the emitted Swift and here.
def inline_helper(xdr_qualified_name)
  xdr_qualified_name[0].downcase + xdr_qualified_name[1..].to_s
end

class Diff
  attr_reader :problems, :counts

  def initialize(overridden)
    @overridden = overridden
    @problems = []
    @counts = Hash.new(0)
    @sources = {}
  end

  # Every Swift file the SDK ships an XDR-JSON conversion in.
  def self.all_sources
    @all_sources ||= (SOURCE_DIRS + [HANDWRITTEN_DIR])
                     .flat_map { |dir| Dir.glob(File.join(dir, '*.swift')) }
                     .map { |path| File.read(path) }
  end

  # The body of a collapsed definition's per-arm conversion, wherever it was emitted. A
  # collapsed type has no conversion of its own, so this is the only place its names appear.
  def self.inline_body(xdr_qualified_name, direction)
    signature = "func #{inline_helper(xdr_qualified_name)}#{direction}XdrJsonValue("
    all_sources.filter_map { |source| block_after(source, signature) }
  end

  # Where an entry's names were emitted: on the type itself when it owns its conversion, or
  # in its per-arm conversion when several XDR definitions collapse onto one Swift type.
  def emission(entry, direction)
    if @collapsed.include?(entry['swift_name'])
      bodies = self.class.inline_body(entry['xdr_qualified_name'], direction)
      if bodies.empty?
        @problems << "#{entry['xdr_qualified_name']}: collapses onto #{entry['swift_name']} " \
                     'and emits no per-arm conversion'
        return nil
      end
      if bodies.length > 1
        @problems << "#{entry['xdr_qualified_name']}: emits #{bodies.length} per-arm conversions"
        return nil
      end
      return bodies.first
    end

    source = read(entry['swift_name'])
    return nil if source.nil?

    block_after(source, direction == 'To' ? EMIT_SIGNATURE : DECODE_SIGNATURE)
  end

  # Swift names that several XDR definitions collapse onto with different wire names. Read
  # off the table itself, so a new collapse is covered without an edit here.
  def note_collapsed(table)
    @table = table
    grouped = Hash.new { |hash, key| hash[key] = [] }
    %w[enums structs unions].each do |kind|
      table[kind].each { |entry| grouped[entry['swift_name']] << entry }
    end

    @collapsed = grouped.filter_map do |swift_name, entries|
      next if entries.length < 2
      next if entries.map { |entry| shape_of(entry) }.uniq.length == 1

      swift_name
    end.to_set
    @counts[:collapsed] = @collapsed.length
  end

  def shape_of(entry)
    return entry['fields'].map { |field| field['json'] } if entry['fields']
    return entry['members'].map { |member| [member['value'], member['json']] } if entry['members']

    entry['arms'].map { |arm| arm['json'] }
  end

  def read(type)
    return @sources[type] if @sources.key?(type)

    parts = []
    path = SOURCE_DIRS.map { |dir| File.join(dir, "#{type}.swift") }.find { |candidate| File.exist?(candidate) }
    parts << File.read(path) if path
    parts.concat(self.class.handwritten_extensions(type))

    if parts.empty?
      @problems << "#{type}: no source declares it under #{SOURCE_DIRS.join(', ')} or #{HANDWRITTEN_DIR}"
      return @sources[type] = nil
    end

    @sources[type] = parts.join("\n")
  end

  # Every `extension <Type>` block the hand-written directory declares for this type.
  def self.handwritten_extensions(type)
    @handwritten ||= Dir.glob(File.join(HANDWRITTEN_DIR, '*.swift')).map { |path| File.read(path) }
    @handwritten.filter_map do |source|
      block_after(source, "extension #{type}:") || block_after(source, "extension #{type} ")
    end
  end

  # Enum members are keyed by discriminant: the Swift case name is the generator's own
  # rendering of the .x identifier and cannot be matched back to it from the file alone.
  def enums(entries)
    entries.each do |entry|
      type = entry['swift_name']
      next if skip_overridden(type, 'enum')

      if @collapsed.include?(type)
        collapsed_enum(entry)
        next
      end

      source = read(type) or next
      declared = source.scan(ENUM_CASE_VALUE).to_h { |name, value| [strip_escape(name), value.to_i] }
      arms = emission(entry, 'To')&.scan(ENUM_JSON_ARM)&.map { |name, json| [strip_escape(name), json] }

      if arms.nil? || arms.empty?
        @problems << "enum #{type}: emits no wire strings"
        next
      end

      emitted = {}
      arms.each do |case_name, json|
        value = declared[case_name]
        if value.nil?
          @problems << "enum #{type}: emission names case #{case_name.inspect}, which the enum does not declare"
          next
        end
        emitted[value] = json
      end

      expected = entry['members'].to_h { |member| [member['value'], member['json']] }

      (expected.keys - emitted.keys).each do |value|
        @problems << "enum #{type}: discriminant #{value} emits no wire string"
      end
      (emitted.keys - expected.keys).each do |value|
        @problems << "enum #{type}: discriminant #{value} is emitted but not in the table"
      end

      expected.each do |value, json|
        @counts[:enum_members] += 1
        actual = emitted[value]
        next if actual.nil? || actual == json

        @problems << "enum #{type}: discriminant #{value} emitted #{actual.inspect}, table #{json.inspect}"
      end
    end
  end

  # A collapsed enumeration has no conversion of its own, and never needs one: an XDR
  # enumeration this SDK collapses is only ever a union discriminant, so its wire strings are
  # observable exactly as the arm keys of the unions it discriminates.
  def collapsed_enum(entry)
    discriminated = @table['unions'].select do |union|
      union['discriminant_type'] == entry['xdr_qualified_name']
    end

    if discriminated.empty?
      @problems << "enum #{entry['xdr_qualified_name']}: collapses onto #{entry['swift_name']} " \
                   'and discriminates no union, so its wire names are unobservable'
      return
    end

    emitted = discriminated.flat_map { |union| emission(union, 'From')&.scan(UNION_DECODE_KEY).to_a }
                           .flatten.to_set
    arms = discriminated.flat_map { |union| union['arms'] }
                        .to_h { |arm| [arm['case'], arm['json']] }

    entry['members'].each do |member|
      json = arms[member['identifier']]
      next if json.nil?

      @counts[:enum_members] += 1
      next if emitted.include?(json)

      @problems << "enum #{entry['xdr_qualified_name']}: #{member['identifier']} emits no " \
                   "#{json.inspect} among the arm keys of the unions it discriminates"
    end
  end

  # Struct keys are compared as an ordered list: SEP-0051 output is field declaration order,
  # so a reordering is a wire-format change even when the key set is unchanged.
  def structs(entries)
    entries.each do |entry|
      type = entry['swift_name']
      next if skip_overridden(type, 'struct')

      emitted = emission(entry, 'To')&.scan(STRUCT_JSON_KEY)&.flatten
      expected = entry['fields'].map { |field| field['json'] }
      @counts[:struct_types] += 1
      @counts[:struct_keys] += expected.length

      if emitted.nil?
        @problems << "struct #{type}: emits no JSON object"
      elsif emitted != expected
        @problems << "struct #{type}: emitted #{emitted.inspect}, table #{expected.inspect}"
      end
    end
  end

  # Arm keys are compared as a set: a union renders one arm at a time, so their order in the
  # generated dispatch carries no wire meaning.
  def unions(entries)
    entries.each do |entry|
      type = entry['swift_name']
      next if skip_overridden(type, 'union')

      emitted = emission(entry, 'From')&.scan(UNION_DECODE_KEY)&.flatten.to_a.to_set
      expected = entry['arms'].reject { |arm| arm['case'] == 'default' }
                              .map { |arm| arm['json'] }.to_set
      @counts[:union_types] += 1
      @counts[:union_arms] += expected.length
      next if emitted == expected

      @problems << "union #{type}: emitted #{emitted.to_a.sort.inspect}, " \
                   "table #{expected.to_a.sort.inspect}"
    end
  end

  # A type with a Stellar-specific rendering emits a single string and therefore no keyed
  # names. It must still exist, and it must genuinely have stopped emitting an object.
  def skip_overridden(type, kind)
    return false unless @overridden.include?(type)

    @counts[:overridden] += 1
    source = read(type)
    if source && block_after(source, EMIT_SIGNATURE)&.match?(STRUCT_JSON_KEY)
      @problems << "#{kind} #{type}: has a Stellar-specific rendering but still emits a JSON object"
    end
    true
  end

  # Every registered override must reach a source file, so a renamed type cannot quietly
  # drop the rendering the registry holds for it.
  def overrides
    @overridden.each { |type| read(type) }
    @counts[:overrides_registered] = @overridden.length
  end

  def strip_escape(name) = name.delete('`')
end

# Before the JSON emitters run there is nothing to read back, and reporting that as several
# hundred missing names would bury the one fact that matters.
def emitter_ran?
  (SOURCE_DIRS + [HANDWRITTEN_DIR]).any? do |dir|
    Dir.glob(File.join(dir, '*.swift')).any? { |path| File.read(path).include?(EMISSION_MARKER) }
  end
end

def main
  quiet = ARGV.include?('--quiet')

  unless File.exist?(NAME_MAP)
    abort "Missing #{NAME_MAP}. Run 'ruby tools/sep-51-oracle/name_map.rb' first."
  end

  unless emitter_ran?
    warn "emitted_names.rb: no #{EMISSION_MARKER} found under #{SOURCE_DIRS.join(', ')}; " \
         'the XDR-JSON emitters have not produced any names to check. Run make xdr-generate.'
    exit 2
  end

  table = JSON.parse(File.read(NAME_MAP))
  diff = Diff.new(load_overridden)
  diff.note_collapsed(table)
  diff.enums(table['enums'])
  diff.structs(table['structs'])
  diff.unions(table['unions'])
  diff.overrides

  counts = diff.counts
  total = counts[:enum_members] + counts[:struct_keys] + counts[:union_arms]

  unless quiet
    puts
    puts 'Generated Swift vs name-map.json'
  end
  puts format('  enum members:   %d matched by discriminant', counts[:enum_members])
  puts format('  struct types:   %d, %d field keys compared in emission order',
              counts[:struct_types], counts[:struct_keys])
  puts format('  union types:    %d, %d arm keys', counts[:union_types], counts[:union_arms])
  puts format('  string-rendered: %d types skipped, %d overrides registered',
              counts[:overridden], counts[:overrides_registered])
  puts format('  collapsed:      %d Swift types read through their per-arm conversions',
              counts[:collapsed])
  puts format('  names compared: %d', total)
  puts format('  problems:       %d', diff.problems.length)

  unless diff.problems.empty?
    puts
    puts 'Problems:'
    diff.problems.each { |problem| puts "  #{problem}" }
    exit 1
  end
end

main if $PROGRAM_NAME == __FILE__
