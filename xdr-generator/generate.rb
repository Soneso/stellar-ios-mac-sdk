require 'xdrgen'
require_relative 'generator/generator'

puts "Generating Swift XDR classes..."

Dir.chdir("..")

Xdrgen::Compilation.new(
  Dir.glob("xdr/*.x"),
  output_dir: "stellarsdk/stellarsdk/responses/xdr/",
  generator: Generator,
  namespace: "stellar",
).compile

puts "Done!"
