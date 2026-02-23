#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix uninitialized constant references in spec files.
# Constants defined under AWS::Types:: are incorrectly referenced as AWS::

changes = 0

# Constants that live under AWS::Types:: but are referenced as AWS::
TYPES_CONSTANTS = %w[
  AttachmentPatterns AwsManagedPolicies GroupPatterns PermissionsBoundaries
  PolicyTemplates RdsEngineConfigs TrustPolicies UserPatterns
  VpcPeeringConnection VpcPeeringConnectionAttributes
]

Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Fix: AWS::SomethingAttributes → AWS::Types::SomethingAttributes
  # Only for constants ending in "Attributes" that aren't already under Types::
  content.gsub!(/\bAWS::(?!Types::)(\w+Attributes)\b/) do |match|
    "AWS::Types::#{$1}"
  end

  # Fix specific known constants
  TYPES_CONSTANTS.each do |const_name|
    # AWS::ConstName → AWS::Types::ConstName (but not if already Types::)
    content.gsub!(/\bAWS::(?!Types::)#{Regexp.escape(const_name)}\b/) do |match|
      "AWS::Types::#{const_name}"
    end
  end

  # Fix: Pangea::Resources::VpcPeeringConnection → Pangea::Resources::AWS::VpcPeeringConnection
  content.gsub!(/Pangea::Resources::(?!AWS::)VpcPeeringConnection\b/, 'Pangea::Resources::AWS::Types::VpcPeeringConnection')

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed constant references in #{changes} spec files"
