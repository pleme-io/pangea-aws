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

# TerraformSynthesizer#synthesis returns symbol keys but tests use both
# string and symbol keys. Use an indifferent-access hash so both work.
class IndifferentHash < Hash
  def [](key)
    result = super(key.to_s)
    return result unless result.nil?
    key.respond_to?(:to_sym) ? super(key.to_sym) : nil
  end

  def dig(key, *rest)
    val = self[key]
    return val if rest.empty? || val.nil?
    val.respond_to?(:dig) ? val.dig(*rest) : nil
  end

  def has_key?(key)
    super(key.to_s) || (key.respond_to?(:to_sym) && super(key.to_sym))
  end
  alias_method :key?, :has_key?
  alias_method :include?, :has_key?

  def fetch(key, *args, &block)
    if has_key?(key)
      self[key]
    elsif args.any?
      args.first
    elsif block
      block.call(key)
    else
      raise KeyError, "key not found: #{key.inspect}"
    end
  end

  def self.deep_convert(obj)
    case obj
    when Hash
      result = IndifferentHash.new
      obj.each { |k, v| result[k.to_s] = deep_convert(v) }
      result
    when Array
      obj.map { |v| deep_convert(v) }
    else
      obj
    end
  end
end

if defined?(TerraformSynthesizer)
  class TerraformSynthesizer
    alias_method :_original_synthesis, :synthesis

    def synthesis
      IndifferentHash.deep_convert(_original_synthesis)
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
