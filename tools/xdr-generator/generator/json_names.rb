# frozen_string_literal: true

# The SEP-0051 (XDR-JSON) name derivation rules.
#
# An enum member's JSON name is the member identifier with the enum's shared prefix
# removed, re-cased. A struct field's JSON name is the field identifier in snake_case;
# no prefix is ever stripped from a field. A union arm's key is the discriminant
# member's own JSON name, or "v<n>" for an integer-discriminated union.
#
# Names derive from the .x identifiers, never from the Swift names this generator
# emits: the Swift names pass through MEMBER_OVERRIDES and mechanical camel-casing,
# which rewrites identifiers in ways SEP-0051 does not.
#
# tools/sep-51-oracle/name_map.rb checks the names this module derives against the
# pinned XDR-JSON reference CLI, one enum member and one struct field at a time.
module Sep51JsonNames
  # Raised when an identifier has a shape the derivation rules cannot express. Every
  # case is absent from the current .x set; raising keeps a future XDR pin bump from
  # silently emitting a wrong or empty JSON name.
  class DerivationError < StandardError; end

  module_function

  # The shared prefix of an enum's members: the longest common leading run of
  # characters, truncated back to and including its last underscore. An enum with a
  # single member has no shared prefix, so its member keeps its full identifier. A
  # common run holding no underscore also strips nothing, which is why members like
  # opINNER and opBAD_AUTH keep their leading "op".
  def find_common_prefix(identifiers)
    return '' if identifiers.length <= 1

    first = identifiers.first
    length = first.length
    identifiers.each do |identifier|
      limit = [length, identifier.length].min
      index = 0
      index += 1 while index < limit && identifier[index] == first[index]
      length = index
    end

    last_underscore = first[0, length].rindex('_')
    last_underscore.nil? ? '' : first[0, last_underscore + 1]
  end

  # Removes the shared prefix. When the remainder would start with a digit the
  # prefix's first character is kept, so the name stays a legal identifier.
  def strip_prefix(identifier, prefix)
    remainder =
      if prefix.empty? || !identifier.start_with?(prefix)
        identifier
      else
        identifier[prefix.length..]
      end

    if remainder.empty?
      raise DerivationError,
            "identifier #{identifier.inspect} is equal to its enum's shared prefix " \
            "#{prefix.inspect}, leaving no name to derive"
    end

    remainder = prefix[0] + remainder if digit?(remainder[0]) && !prefix.empty?

    if remainder == 'Error'
      raise DerivationError,
            "identifier #{identifier.inspect} reduces to the reserved remainder " \
            "'Error', whose JSON name the reference implementation escapes"
    end

    remainder
  end

  # Splits an identifier into words: at every non-alphanumeric character, after a
  # lowercase or digit that is followed by an uppercase, and before the final
  # uppercase of an uppercase run that is followed by a lowercase. The last rule is
  # what makes IPv4 two words ("I", "Pv4") and signerSponsoringIDs four ("signer",
  # "Sponsoring", "I", "Ds").
  def words(identifier)
    identifier.split(/[^[:alnum:]]+/).reject(&:empty?).flat_map { |run| split_run(run) }
  end

  def split_run(run)
    characters = run.chars
    result = []
    start = 0
    mode = :boundary

    characters.each_with_index do |character, index|
      following = characters[index + 1]

      if following.nil?
        result << run[start..]
        break
      end

      next_mode =
        if lower?(character) then :lowercase
        elsif upper?(character) then :uppercase
        else mode
        end

      if next_mode == :lowercase && upper?(following)
        result << run[start..index]
        start = index + 1
        mode = :boundary
      elsif mode == :uppercase && upper?(character) && lower?(following)
        result << run[start...index] unless start == index
        start = index
        mode = :boundary
      else
        mode = next_mode
      end
    end

    result.reject(&:empty?)
  end

  def upper_camel(identifier)
    words(identifier).map { |word| word[0].upcase + word[1..].to_s.downcase }.join
  end

  def snake(identifier)
    words(identifier).map(&:downcase).join('_')
  end

  # Lowercases an UpperCamelCase name, inserting an underscore before every
  # non-initial uppercase character.
  def rename_snake(name)
    result = +''
    name.each_char.with_index do |character, index|
      result << '_' if index.positive? && upper?(character)
      result << character.downcase
    end
    result
  end

  def enum_member_json_name(identifier, sibling_identifiers)
    prefix = find_common_prefix(sibling_identifiers)
    rename_snake(upper_camel(strip_prefix(identifier, prefix)))
  end

  def struct_field_json_name(identifier)
    snake(identifier)
  end

  # A union arm's key is the discriminant member's own JSON name, so an
  # enum-discriminated arm can never disagree with the enum's own rendering. The
  # prefix comes from the discriminant enum's full member list, not from the arms
  # the union happens to cover, so a union switching over a proper subset of the
  # enum still keys its arms the way the enum renders them.
  #
  # An integer-discriminated union keys its arms "v" followed by the case value; the
  # declared discriminant name never reaches the wire, so a union switching on
  # "version" still keys its arms "v0", "v1" and so on.
  def union_arm_json_key(kase, union)
    discriminant = union.discriminant_type
    label = kase.value_s

    unless discriminant.is_a?(Xdrgen::AST::Definitions::Enum)
      value = Integer(label, exception: false) || union.resolved_case(kase).value
      raise DerivationError, "negative union case label #{value} has no JSON key" if value.negative?

      return "v#{value}"
    end

    identifiers = discriminant.members.map(&:name)
    unless identifiers.include?(label)
      raise DerivationError, "union case #{label.inspect} names no member of its discriminant enum"
    end

    enum_member_json_name(label, identifiers)
  end

  def upper?(character) = character.match?(/[[:upper:]]/)
  def lower?(character) = character.match?(/[[:lower:]]/)
  def digit?(character) = character.match?(/[[:digit:]]/)
end
