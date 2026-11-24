require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require_relative '../generator/generator'

class GeneratorSnapshotTest < Minitest::Test
  SNAPSHOT_DIR = File.expand_path("snapshots", __dir__)
  XDR_DIR      = File.expand_path("../../../xdr", __dir__)

  def setup
    @output_dir = self.class.shared_output_dir
  end

  # Generates the full XDR output once for the entire suite. minitest builds a
  # fresh instance per test method, so per-instance memoization cannot help; the
  # shared output directory is built lazily on first use and removed after the run.
  def self.shared_output_dir
    @shared_output_dir ||= begin
      dir = Dir.mktmpdir("xdr_gen_test_")
      Dir.chdir(File.expand_path("../../..", __dir__)) do
        Xdrgen::Compilation.new(
          Dir.glob("xdr/*.x"),
          output_dir: dir + "/",
          generator: Generator,
          namespace: "stellar",
        ).compile
      end
      Minitest.after_run { FileUtils.rm_rf(dir) }
      dir
    end
  end

  # -- Configuration tests --

  def test_generator_loads
    assert defined?(Generator), "Generator class should be defined"
    assert Generator < Xdrgen::Generators::Base, "Generator should inherit from Base"
  end

  def test_skip_types_populated
    %w[PublicKey TransactionXDR MuxedAccountXDR FeeBumpTransactionXDR TransactionV0XDR].each do |t|
      assert Generator::SKIP_TYPES.include?(t), "SKIP_TYPES should include #{t}"
    end
  end

  def test_overrides_loaded
    assert NAME_OVERRIDES.is_a?(Hash), "NAME_OVERRIDES should be a Hash"
    assert MEMBER_OVERRIDES.is_a?(Hash), "MEMBER_OVERRIDES should be a Hash"
    assert FIELD_OVERRIDES.is_a?(Hash), "FIELD_OVERRIDES should be a Hash"
    assert TYPE_OVERRIDES.is_a?(Hash), "TYPE_OVERRIDES should be a Hash"
  end

  # -- Snapshot tests --
  # Compare generated output against committed snapshots.
  # To update snapshots after intentional changes:
  #   ruby -e "require_relative 'test/update_snapshots'"

  def test_snapshot_data_entry_xdr
    assert_snapshot "DataEntryXDR.swift"
  end

  def test_snapshot_time_bounds_xdr
    assert_snapshot "TimeBoundsXDR.swift"
  end

  def test_snapshot_price_xdr
    assert_snapshot "PriceXDR.swift"
  end

  def test_snapshot_asset_xdr
    assert_snapshot "AssetXDR.swift"
  end

  def test_snapshot_memo_xdr
    assert_snapshot "MemoXDR.swift"
  end

  def test_snapshot_hash_xdr
    assert_snapshot "HashXDR.swift"
  end

  def test_snapshot_contract_cost_params_xdr
    assert_snapshot "ContractCostParamsXDR.swift"
  end

  def test_snapshot_xdr_constants
    assert_snapshot "XDRConstants.swift"
  end

  def test_snapshot_operation_body_xdr
    assert_snapshot "OperationBodyXDR.swift"
  end

  def test_snapshot_operation_type
    assert_snapshot "OperationType.swift"
  end

  def test_snapshot_sc_val_xdr
    assert_snapshot "SCValXDR.swift"
  end

  def test_snapshot_ledger_key_xdr
    assert_snapshot "LedgerKeyXDR.swift"
  end

  def test_snapshot_soroban_transaction_data_xdr
    assert_snapshot "SorobanTransactionDataXDR.swift"
  end

  # -- Output sanity checks --

  def test_generated_files_count
    count = Dir.glob(File.join(@output_dir, "*.swift")).length
    assert count > 300, "Should generate 300+ files, got #{count}"
  end

  def test_no_skip_types_generated
    Generator::SKIP_TYPES.each do |skip|
      path = File.join(@output_dir, "#{skip}.swift")
      refute File.exist?(path), "SKIP_TYPE #{skip} should not be generated"
    end
  end

  # The property type is the resolved type, not the typedef name. The XDR-JSON codec is a
  # separate matter: it is keyed on the declared XDR name precisely because several typedefs
  # resolve to one Swift type and render differently, so AccountIDXDRJsonCodec does appear
  # elsewhere in the same file.
  def test_typedef_resolution_in_structs
    content = File.read(File.join(@output_dir, "DataEntryXDR.swift"))
    assert_includes content, "public let accountID: PublicKey",
                    "DataEntryXDR should declare accountID as PublicKey"
    refute_includes content, "accountID: AccountIDXDR",
                    "DataEntryXDR should not declare accountID as AccountIDXDR"
  end

  def test_extension_point_simplification
    content = File.read(File.join(@output_dir, "DataEntryXDR.swift"))
    assert_includes content, "let reserved: Int32 = 0", "Extension point should be simplified to Int32"
  end

  def test_let_types_use_let
    content = File.read(File.join(@output_dir, "PriceXDR.swift"))
    assert_includes content, "public let n:", "LET_TYPES structs should use let"
    refute_includes content, "public var n:", "LET_TYPES structs should not use var"
  end

  def test_field_overrides_applied
    content = File.read(File.join(@output_dir, "DataEntryXDR.swift"))
    assert_includes content, "reserved", "FIELD_OVERRIDES should rename ext to reserved"
  end

  def test_txrep_fixed_opaque_writer_checks_width
    sig_content = File.read(File.join(@output_dir, "DecoratedSignatureXDR.swift"))
    assert_includes sig_content,
                    'lines.append("\(prefix).hint: \(try TxRepHelper.bytesToHex(self.hint, key: "\(prefix).hint"))")',
                    "Fixed opaque field hint should format through the width-checking bytesToHex helper"

    code_content = File.read(File.join(@output_dir, "LedgerKeyContractCodeXDR.swift"))
    assert_includes code_content,
                    'lines.append("\(prefix).hash: \(try TxRepHelper.bytesToHex(self.hash, key: "\(prefix).hash"))")',
                    "Fixed opaque field hash should format through the width-checking bytesToHex helper"
  end

  def test_txrep_variable_opaque_writer_unchanged
    sig_content = File.read(File.join(@output_dir, "DecoratedSignatureXDR.swift"))
    assert_includes sig_content,
                    'lines.append("\(prefix).signature: \(TxRepHelper.bytesToHex(self.signature))")',
                    "Variable opaque field signature should format through unchecked bytesToHex"
  end

  # -- Declared maxima --

  def test_declared_maximum_bounds_a_variable_array_named_by_a_constant
    content = generated("AccountEntryXDR.swift")
    assert_includes content, "signers = try decodeArray(type: SignerXDR.self, dec: decoder, maxCount: 20)"
    assert_includes content, "try container.encodeArray(signers, maxCount: 20)"
    assert_includes content, "try XdrJson.requireMaxCount(try XdrJson.array(try XdrJson.field(members, " \
                             'key: "signers", type: "AccountEntryXDR"), type: "AccountEntryXDR", key: "signers"), 20, ' \
                             'type: "AccountEntryXDR", key: "signers")'
  end

  def test_declared_maximum_bounds_an_array_of_optional_elements
    content = generated("AccountEntryExtensionV2.swift")
    assert_includes content, "try decodeArrayOfOptional(type: PublicKey.self, dec: decoder, maxCount: 20)"
    assert_includes content, "try encodeArrayOfOptional(signerSponsoringIDs, enc: encoder, maxCount: 20)"
  end

  def test_declared_maximum_bounds_a_string_field
    content = generated("ErrorXDR.swift")
    assert_includes content, "msg = try container.decodeString(maxLength: 100)"
    assert_includes content, "try container.encodeString(msg, maxLength: 100)"
    assert_includes content, 'try XdrJson.requireMaxLength(try XdrJson.unescapedText(try XdrJson.field(members, ' \
                             'key: "msg", type: "ErrorXDR"), type: "ErrorXDR", key: "msg"), 100, type: "ErrorXDR", key: "msg")'
  end

  def test_declared_maximum_bounds_an_opaque_field
    content = generated("Ed25519SignedPayload.swift")
    assert_includes content, "payload = try container.decodeOpaque(maxLength: 64)"
    assert_includes content, "try container.encodeOpaque(payload, maxLength: 64)"
    assert_includes content, 'try TxRepHelper.requireMaxLength(try TxRepHelper.requireHex(map, "\(prefix).payload"), ' \
                             '64, key: "\(prefix).payload")'
  end

  def test_declared_maximum_follows_string_and_opaque_typedefs_to_the_site
    data_entry = generated("DataEntryXDR.swift")
    assert_includes data_entry, "dataName = try container.decodeString(maxLength: 64)"
    assert_includes data_entry, "dataValue = try container.decodeOpaque(maxLength: 64)"

    set_options = generated("SetOptionsOperationXDR.swift")
    assert_includes set_options, "homeDomain = try container.decodeString(maxLength: 32)"
    assert_includes set_options, "try container.encodeString(val, maxLength: 32)"
    assert_includes set_options, 'homeDomain = try TxRepHelper.requireMaxLength(try TxRepHelper.unescapeString(' \
                                 'TxRepHelper.getValue(map, "\(prefix).homeDomain") ?? ""), 32, key: "\(prefix).homeDomain")'

    assert_includes generated("String64XDR.swift"),
                    "try XdrJson.requireMaxLength(try XdrJson.unescapedText(value, type: type, key: key), 64, type: type, key: key)"
    assert_includes generated("SignatureXDR.swift"),
                    "try XdrJson.requireMaxLength(try XdrJson.hex(value, type: type, key: key), 64, type: type, key: key)"
  end

  def test_declared_maximum_bounds_each_element_of_an_array_of_bounded_typedefs
    event = generated("SCSpecEventV0XDR.swift")
    assert_includes event, "prefixTopics = try decodeStringArray(dec: decoder, maxCount: 2, maxLength: 32)"
    assert_includes event, "try container.encodeStringArray(prefixTopics, maxCount: 2, maxLength: 32)"

    value = generated("StellarValueXDR.swift")
    assert_includes value, "upgrades = try decodeOpaqueArray(dec: decoder, maxCount: 6, maxLength: 128)"
    assert_includes value, "try container.encodeOpaqueArray(upgrades, maxCount: 6, maxLength: 128)"
  end

  def test_declared_maximum_bounds_union_arms
    predicate = generated("ClaimPredicateXDR.swift")
    assert_includes predicate, "let val = try decodeArray(type: ClaimPredicateXDR.self, dec: decoder, maxCount: 2)"
    assert_includes predicate, "try container.encodeArray(val, maxCount: 2)"

    sc_val = generated("SCValXDR.swift")
    assert_includes sc_val, "let val = try container.decodeString(maxLength: 32)"
    assert_includes sc_val, "try container.encodeString(val, maxLength: 32)"
  end

  def test_declared_maximum_bounds_bytes_backed_strings_as_strings
    content = generated("InvokeContractArgsXDR.swift")
    assert_includes content, "functionName = try container.decodeStringBytes(maxLength: 32)"
    assert_includes content, "try container.encodeStringBytes(functionName, maxLength: 32)"
    assert_includes content, 'try TxRepHelper.requireMaxLength(try TxRepHelper.requireStringBytes(map, ' \
                             '"\(prefix).functionName"), 32, key: "\(prefix).functionName")'
  end

  def test_declared_maximum_bounds_an_array_typedef_wrapper
    content = generated("TxAdvertVectorXDR.swift")
    assert_includes content, "wrapped = try decodeArray(type: HashXDR.self, dec: decoder, maxCount: 1000)"
    assert_includes content, "try container.encodeArray(wrapped, maxCount: 1000)"
  end

  def test_unbounded_sites_stay_unbounded
    sc_val = generated("SCValXDR.swift")
    assert_includes sc_val, "let val = try container.decode(Data.self)"
    assert_includes sc_val, "self = .vec(try container.decode([SCValXDR].self))"

    args = generated("InvokeContractArgsXDR.swift")
    assert_includes args, "args = try decodeArray(type: SCValXDR.self, dec: decoder)"
    assert_includes args, "try container.encode(args)"
  end

  def test_declared_maximum_resolves_constants_and_typedef_chains
    content = generate_probe(<<~XDR).fetch("ProbeStructXDR.swift")
      namespace stellar {
      const PROBE_LIMIT = 7;
      typedef string ProbeName<10>;
      typedef ProbeName ProbeAlias;
      struct ProbeStruct {
        ProbeAlias alias;
        int items<PROBE_LIMIT>;
        string open<>;
      };
      }
    XDR
    assert_includes content, "alias = try container.decodeString(maxLength: 10)"
    assert_includes content, "try container.encodeString(alias, maxLength: 10)"
    assert_includes content, "items = try decodeArray(type: Int32.self, dec: decoder, maxCount: 7)"
    assert_includes content, "try container.encodeArray(items, maxCount: 7)"
    assert_includes content, "`open` = try container.decode(String.self)"
    assert_includes content, "try container.encode(`open`)"
  end

  def test_unresolvable_maximum_constant_fails_generation
    error = assert_raises(RuntimeError) do
      generate_probe(<<~XDR)
        namespace stellar {
        struct ProbeStruct {
          int items<PROBE_UNKNOWN_LIMIT>;
        };
        }
      XDR
    end
    assert_includes error.message, "Could not resolve constant: PROBE_UNKNOWN_LIMIT"
  end

  private

  # The generator, minus the check that every bytes-backed field of the Stellar definitions
  # was rendered, for definitions that declare none of them.
  class ProbeGenerator < Generator
    def verify_bytes_backed_string_fields!; end
  end

  def generated(filename)
    File.read(File.join(@output_dir, filename))
  end

  # Generates +source+ in a scratch directory and returns each file's content by name.
  def generate_probe(source)
    Dir.mktmpdir("xdr_probe_") do |dir|
      path = File.join(dir, "probe.x")
      File.write(path, source)
      output = File.join(dir, "out")
      FileUtils.mkdir_p(output)
      Xdrgen::Compilation.new([path], output_dir: output + "/", generator: ProbeGenerator,
                                      namespace: "stellar").compile
      Dir.glob(File.join(output, "*.swift")).to_h { |f| [File.basename(f), File.read(f)] }
    end
  end

  def assert_snapshot(filename)
    generated = File.join(@output_dir, filename)
    snapshot  = File.join(SNAPSHOT_DIR, filename)

    assert File.exist?(generated), "Generated file #{filename} should exist"
    assert File.exist?(snapshot), "Snapshot file #{filename} should exist"

    expected = File.read(snapshot)
    actual   = File.read(generated)
    assert_equal expected, actual, "Generated #{filename} does not match snapshot"
  end
end
