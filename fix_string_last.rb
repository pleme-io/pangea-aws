#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix String#last calls in specs — Ruby String doesn't have #last
# Replace patterns like `az.last` with `az[-1]`

changes = 0
Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Replace .last when used on string variables (common pattern: az.last, name.last)
  # Only in string interpolation and direct call contexts
  content.gsub!(/(\w+)\.last\b(?!\?)/) do |match|
    var = $1
    # Skip if it's likely an array method (result, list, etc.)
    if %w[last].include?(var) || var.end_with?('s') || var.end_with?('list') || var.end_with?('array')
      match
    else
      "#{var}[-1]"
    end
  end

  if content != original
    changes += 1
    File.write(file, content)
    puts "Fixed #{file}"
  end
end

puts "\nFixed #{changes} files"
