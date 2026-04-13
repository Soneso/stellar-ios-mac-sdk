# frozen_string_literal: true
#
# Verifies that running generate_tests.rb twice produces byte-identical output.
# Used by CI / manual audit after every change to the test generator.
#
#   cd tools/xdr-generator && bundle exec ruby test/check_idempotence.rb
#

require 'digest'

GENERATED_DIR = File.expand_path(
  '../../../stellarsdk/stellarsdkUnitTests/sep/txrep/generated',
  __dir__,
)

def hash_dir(dir)
  Dir.glob(File.join(dir, '*.swift')).sort.to_h do |path|
    [File.basename(path), Digest::SHA256.hexdigest(File.read(path))]
  end
end

before = hash_dir(GENERATED_DIR)

# Regenerate
script = File.expand_path('generate_tests.rb', __dir__)
ok = system('bundle', 'exec', 'ruby', script, out: '/dev/null')
raise 'generator exited with error' unless ok

after = hash_dir(GENERATED_DIR)

if before == after
  puts 'IDEMPOTENT'
  before.each { |f, h| puts "  #{f}: #{h}" }
  exit 0
else
  puts 'NOT IDEMPOTENT'
  before.each_key do |f|
    puts "  #{f}: #{before[f]} -> #{after[f]}"
  end
  exit 1
end
