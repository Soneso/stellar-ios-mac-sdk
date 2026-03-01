require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require_relative '../generator/generator'

class GeneratorSnapshotTest < Minitest::Test
  SNAPSHOT_DIR = File.expand_path("snapshots", __dir__)
  XDR_DIR      = File.expand_path("../../../xdr", __dir__)

  def setup
    @output_dir = Dir.mktmpdir("xdr_gen_test_")
    generate_all
  end

  def teardown
    FileUtils.rm_rf(@output_dir)
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

  def test_typedef_resolution_in_structs
    content = File.read(File.join(@output_dir, "DataEntryXDR.swift"))
    assert_includes content, "PublicKey", "DataEntryXDR should use PublicKey (not AccountIDXDR)"
    refute_includes content, "AccountIDXDR", "DataEntryXDR should not use AccountIDXDR"
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

  private

  def generate_all
    return if @generated
    Dir.chdir(File.expand_path("../../..", __dir__))
    Xdrgen::Compilation.new(
      Dir.glob("xdr/*.x"),
      output_dir: @output_dir + "/",
      generator: Generator,
      namespace: "stellar",
    ).compile
    @generated = true
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
