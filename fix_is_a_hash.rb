#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix is_a?(Hash) → is_a?(::Hash) to prevent shadowing by Dry.Types() includes

changes = 0
Dir.glob("lib/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup
  content.gsub!('.is_a?(Hash)', '.is_a?(::Hash)')
  if content != original
    changes += 1
    File.write(file, content)
  end
end
puts "Fixed is_a?(Hash) → is_a?(::Hash) in #{changes} files"
