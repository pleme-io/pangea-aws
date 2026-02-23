#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix resource(type, name) mock to accept optional 3rd arg

changes = 0
Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Pattern: def resource(type, name) with attributes: {} on next lines
  content.gsub!(
    /def resource\(type, name\)\s*\n(\s+)@resources \|\|= \{\}\s*\n\s+resource_data = \{ type: type, name: name, attributes: \{\} \}/
  ) do
    indent = $1
    "def resource(type, name, attrs = {})\n#{indent}@resources ||= {}\n#{indent}resource_data = { type: type, name: name, attributes: attrs }"
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed #{changes} files"
