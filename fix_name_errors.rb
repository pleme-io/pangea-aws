#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix NameError: uninitialized constant errors in specs
#
# Patterns:
# 1. Specs using Pangea::Resources::AWS::Types::VpcPeeringConnection as a module to extend/include
#    → should be Pangea::Resources::AWS
# 2. Wrong namespace references in resource files (Types::X where class is at Resources::X)

changes = 0

# Pattern 1: Fix extend/include of wrong constant in specs
Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Fix: Pangea::Resources::AWS::Types::VpcPeeringConnection → Pangea::Resources::AWS
  content.gsub!(/Pangea::Resources::AWS::Types::VpcPeeringConnection(?!Attributes)/, 'Pangea::Resources::AWS')

  if content != original
    changes += 1
    File.write(file, content)
  end
end

# Pattern 2: Fix resource files referencing Types:: namespace incorrectly
Dir.glob("lib/pangea/resources/aws_*/resource.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Fix: Pangea::Resources::Types::VpcPeeringConnectionAttributes
  # → Pangea::Resources::VpcPeeringConnectionAttributes
  if content.include?('Pangea::Resources::Types::VpcPeeringConnectionAttributes')
    content.gsub!('Pangea::Resources::Types::VpcPeeringConnectionAttributes',
                  'Pangea::Resources::VpcPeeringConnectionAttributes')
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed #{changes} files with NameError constant issues"
