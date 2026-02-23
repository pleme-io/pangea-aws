#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix specs that define their own MockTerraformSynthesizer.
# Replace `MockTerraformSynthesizer.new` with `TerraformSynthesizer.new`
# and remove the inline class definition.

changes = 0

Dir.glob("spec/resources/**/complete_synthesis_spec.rb").each do |file|
  content = File.read(file)
  next unless content.include?('MockTerraformSynthesizer')
  original = content.dup

  # Remove the inline MockTerraformSynthesizer class definition
  content.gsub!(/^# Mock TerraformSynthesizer.*\nclass MockTerraformSynthesizer\n.*?\nend\n/m, '')

  # Replace MockTerraformSynthesizer.new with TerraformSynthesizer.new
  content.gsub!('MockTerraformSynthesizer.new', 'TerraformSynthesizer.new')

  if content != original
    # Ensure terraform-synthesizer is required
    unless content.include?("require 'terraform-synthesizer'")
      content.sub!("require 'spec_helper'", "require 'spec_helper'\nrequire 'terraform-synthesizer'")
    end
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed #{changes} spec files using MockTerraformSynthesizer"
