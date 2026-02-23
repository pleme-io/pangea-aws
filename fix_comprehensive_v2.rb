#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive pangea-aws fixer, applied in correct order.
#
# Phase 1: Types::Types:: → Types:: (88 resource files)
# Phase 2: Dry::Struct → BaseAttributes (465 type files)
# Phase 3: include → extend in synthesize/instance_eval blocks (spec files)
# Phase 4: Make scalar attributes optional (attribute? + .optional)
# Phase 5: Make array attributes default to [] (not optional/nil)
# Phase 6: Make hash attributes default to {} (not optional/nil)
# Phase 7: Fix safe navigation for .any? on potentially-nil in resource.rb

stats = Hash.new(0)

# === Phase 1: Fix Types::Types:: double-nesting ===
Dir.glob("lib/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup
  content.gsub!(/AWS::Types::Types::/, 'Types::')
  content.gsub!(/Types::Types::/, 'Types::')
  if content != original
    stats[:types_nesting] += 1
    File.write(file, content)
  end
end

# === Phase 2: Dry::Struct → BaseAttributes ===
(Dir.glob("lib/pangea/resources/aws_*/types.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types/*.rb")).each do |file|
  content = File.read(file)
  original = content.dup
  if content.gsub!(/< Dry::Struct\b/, '< Pangea::Resources::BaseAttributes')
    stats[:base_class] += 1
    File.write(file, content)
  end
end

# === Phase 3: include → extend in synthesize/instance_eval blocks ===
Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup
  lines = content.lines
  in_synth_block = false
  depth = 0

  lines.each_with_index do |line, i|
    if line =~ /\b(synthesize|instance_eval)\s+do\b/
      in_synth_block = true
      depth = 0
    end
    if in_synth_block
      depth += line.scan(/\bdo\b/).length
      depth -= line.scan(/\bend\b/).length
      if line =~ /^\s+include\s+Pangea::Resources::/
        lines[i] = line.gsub('include Pangea::Resources::', 'extend Pangea::Resources::')
        stats[:include_extend] += 1
      end
      in_synth_block = false if depth <= 0
    end
  end

  new_content = lines.join
  File.write(file, new_content) if new_content != original
end

# === Phase 4-6: Fix attribute declarations ===
def is_multiline?(type_expr)
  (type_expr.count('(') - type_expr.count(')')) > 0 ||
    (type_expr.count('{') - type_expr.count('}')) > 0 ||
    type_expr.end_with?('{') ||
    type_expr == ')' ||
    type_expr.include?('.constructor')
end

def is_array_type?(type_expr)
  type_expr.match?(/(?:^|\b|::)Array\b/)
end

def is_hash_type?(type_expr)
  type_expr.match?(/(?:^|\b|::)Hash\b/) && !type_expr.include?('.schema(')
end

(Dir.glob("lib/pangea/resources/aws_*/types.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types/*.rb")).each do |file|
  content = File.read(file)
  original = content.dup

  content.gsub!(/^(\s+)(attribute\??\s+):(\w+),\s+(.+)$/) do |match|
    indent = $1
    attr_keyword = $2.strip
    attr_name = $3
    type_expr = $4.strip

    # Already attribute? → skip
    next match if attr_keyword == 'attribute?'
    # Has .default( → already has default value
    next match if type_expr.include?('.default(')
    # Multi-line → skip
    next match if is_multiline?(type_expr)

    if is_array_type?(type_expr)
      # Arrays: default to empty array (not nil — code calls .any?, .each, etc.)
      clean_type = type_expr.gsub(/\.optional\s*$/, '')
      # Don't add default to constrained arrays (min_size check)
      if clean_type.include?('.constrained(')
        stats[:attr_optional] += 1
        "#{indent}attribute? :#{attr_name}, #{type_expr.include?('.optional') ? type_expr : type_expr + '.optional'}"
      else
        stats[:attr_array_default] += 1
        "#{indent}attribute :#{attr_name}, #{clean_type}.default([].freeze)"
      end
    elsif is_hash_type?(type_expr)
      # Hashes: default to empty hash
      clean_type = type_expr.gsub(/\.optional\s*$/, '')
      if clean_type.include?('.constrained(')
        stats[:attr_optional] += 1
        "#{indent}attribute? :#{attr_name}, #{type_expr.include?('.optional') ? type_expr : type_expr + '.optional'}"
      else
        stats[:attr_hash_default] += 1
        "#{indent}attribute :#{attr_name}, #{clean_type}.default({}.freeze)"
      end
    else
      # Scalar types: make key optional with optional type
      if type_expr.include?('.optional')
        stats[:attr_key_optional] += 1
        "#{indent}attribute? :#{attr_name}, #{type_expr}"
      else
        stats[:attr_optional] += 1
        "#{indent}attribute? :#{attr_name}, #{type_expr}.optional"
      end
    end
  end

  File.write(file, content) if content != original
end

# === Phase 7: Safe navigation for .any? on nil in resource/helper files ===
# Only fix the specific `attrs.something.any?` pattern, not generic .any?
(Dir.glob("lib/pangea/resources/aws_*/resource.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types/helpers.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types/validators.rb")).each do |file|
  content = File.read(file)
  original = content.dup

  # Fix: `something.any?` → `something&.any?` (but not already &.any?)
  # Only when preceded by `attrs.` or `_attrs.` accessor
  content.gsub!(/(\w+_attrs\.\w+)\.any\?/) do |match|
    $1 + '&.any?'
  end
  content.gsub!(/(\battrs\.\w+)\.any\?/) do |match|
    $1 + '&.any?'
  end

  if content != original
    stats[:safe_nav] += 1
    File.write(file, content)
  end
end

puts "Phase 1: Fixed #{stats[:types_nesting]} Types::Types files"
puts "Phase 2: Changed #{stats[:base_class]} files to BaseAttributes"
puts "Phase 3: Fixed #{stats[:include_extend]} include→extend in specs"
puts "Phase 4: Made #{stats[:attr_optional]} scalar attributes optional"
puts "Phase 4: Made #{stats[:attr_key_optional]} attributes key-optional"
puts "Phase 5: Set #{stats[:attr_array_default]} array attributes to default([])"
puts "Phase 6: Set #{stats[:attr_hash_default]} hash attributes to default({})"
puts "Phase 7: Added safe navigation in #{stats[:safe_nav]} resource files"
