#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix templates modules that use `def self.method_name` — when these modules
# are `extend`ed into a class, only instance methods become class methods.
# `def self.method_name` stays on the module itself and is NOT available on the class.
#
# Fix: add `module_function` after the module definition, which makes methods
# available both as `ModuleName.method` and as class methods when extended.

changes = 0

Dir.glob("lib/pangea/resources/aws_*/types/templates.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Check if this module has `def self.` patterns
  next unless content.include?("def self.")

  # Replace `def self.method_name` with `def method_name`
  content.gsub!(/^(\s+)def self\.(\w+)/, '\1def \2')

  # Add module_function after the module line if not already present
  unless content.include?("module_function")
    content.sub!(/^(\s+)(module \w+Templates)\s*$/) do
      indent = $1
      mod_line = $2
      "#{indent}#{mod_line}\n#{indent}  module_function"
    end
  end

  if content != original
    changes += 1
    File.write(file, content)
    puts "Fixed #{file}"
  end
end

# Also fix types.rb files that have inline Templates modules
Dir.glob("lib/pangea/resources/aws_*/types.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Check if this file has a Templates module with `def self.`
  next unless content.match?(/module \w+Templates/)
  next unless content.include?("def self.")

  # Replace `def self.method_name` with `def method_name` inside Templates module
  in_templates = false
  lines = content.lines
  new_lines = []
  indent = ""

  lines.each do |line|
    if line.match?(/module \w+Templates/)
      in_templates = true
      indent = line[/^\s*/]
      new_lines << line
      unless lines.any? { |l| l.include?("module_function") && l.start_with?(indent) }
        new_lines << "#{indent}  module_function\n"
      end
      next
    end

    if in_templates && line.match?(/^#{indent}end/)
      in_templates = false
    end

    if in_templates
      line = line.sub(/^(\s+)def self\.(\w+)/, '\1def \2')
    end

    new_lines << line
  end

  content = new_lines.join

  if content != original
    changes += 1
    File.write(file, content)
    puts "Fixed #{file}"
  end
end

puts "\nFixed #{changes} template files"
