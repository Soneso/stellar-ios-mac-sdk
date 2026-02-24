# Regenerates snapshot files used by generator_snapshot_test.rb.
# Run from the xdr-generator directory:
#   bundle exec ruby test/update_snapshots.rb

require 'fileutils'
require 'tmpdir'
require 'xdrgen'
require_relative '../generator/generator'

SNAPSHOT_DIR = File.expand_path("snapshots", __dir__)

Dir.chdir(File.expand_path("../..", __dir__))
output = Dir.mktmpdir("xdr_snapshots_")

Xdrgen::Compilation.new(
  Dir.glob("xdr/*.x"),
  output_dir: output + "/",
  generator: Generator,
  namespace: "stellar",
).compile

FileUtils.mkdir_p(SNAPSHOT_DIR)
count = 0
Dir.glob(File.join(SNAPSHOT_DIR, "*.swift")).each { |f| File.delete(f) }

%w[
  DataEntryXDR.swift
  TimeBoundsXDR.swift
  PriceXDR.swift
  AssetXDR.swift
  MemoXDR.swift
  HashXDR.swift
  ContractCostParamsXDR.swift
  XDRConstants.swift
].each do |f|
  src = File.join(output, f)
  if File.exist?(src)
    FileUtils.cp(src, SNAPSHOT_DIR)
    count += 1
  else
    warn "Warning: #{f} not found in generated output"
  end
end

FileUtils.rm_rf(output)
puts "Updated #{count} snapshots in #{SNAPSHOT_DIR}"
