# frozen_string_literal: true

# Per-field SEP-0051 (XDR-JSON) conversion overrides, keyed by the Swift struct name and
# the Swift property name.
#
# This table is the escape hatch for a field whose conversion cannot be derived from its
# declaration. It is empty, and that is the expected state: dispatch keys on the declared
# XDR type from the AST, which keeps every distinction the Swift type erases, and the two
# fields whose Swift storage differs from their XDR type -- OfferEntry.offerID stored as an
# unsigned 64-bit integer and LedgerKeyConfigSetting.configSettingID stored as a plain
# 32-bit integer -- are reconciled from FIELD_TYPE_OVERRIDES itself, so a new entry there
# is handled or aborts generation rather than needing a duplicate entry here.
#
# An entry added here needs a written reason: what about the field the declaration does not
# say, and why the reconciliation cannot live in json_codecs.rb.
#
# Format: "StructName" => { "propertyName" => { emit: <Swift>, read: <Swift> } }
JSON_FIELD_OVERRIDES = {}.freeze
