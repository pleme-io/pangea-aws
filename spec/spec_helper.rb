# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  track_files 'lib/**/*.rb'
end

lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require 'rspec'

begin
  require 'dry-types'
  require 'dry-struct'
  require 'terraform-synthesizer'
  require 'json'
rescue LoadError => e
  puts "Warning: Could not load dependency: #{e.message}"
end

begin
  require 'pangea-aws'
rescue LoadError => e
  puts "Warning: Could not load pangea-aws: #{e.message}"
end

# TerraformSynthesizer#synthesis returns symbol keys but tests expect string keys.
# Normalize via JSON roundtrip so all test assertions use string keys consistently.
if defined?(TerraformSynthesizer)
  class TerraformSynthesizer
    alias_method :_original_synthesis, :synthesis

    def synthesis
      JSON.parse(_original_synthesis.to_json)
    end
  end
end

Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include SynthesisTestHelpers if defined?(SynthesisTestHelpers)
  config.before(:suite) { ENV['PANGEA_ENV'] = 'test' }
  config.formatter = :progress
  config.color = true
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true
  config.order = :random
  Kernel.srand config.seed
  config.warnings = false
end
