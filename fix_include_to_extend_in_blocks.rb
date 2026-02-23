#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix specs that use `include Pangea::Resources::AWS` at describe level
# combined with `synthesize do`/`instance_eval do` blocks.
#
# Problem: `include` at describe level mixes methods into the RSpec example group.
# But `synthesize do` uses `instance_eval` which changes `self` to the synthesizer.
# So resource methods (aws_vpc, aws_s3_bucket, etc.) are not accessible.
#
# Fix: Add `extend Pangea::Resources::AWS` inside each synthesize/instance_eval block
# that doesn't already have one.

changes = 0

Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)

  # Only process files with include at describe level
  next unless content.match?(/^\s{2}include Pangea::Resources::\w+\s*$/)

  # Extract the module being included
  module_name = content.match(/^\s{2}include (Pangea::Resources::\w+)\s*$/)[1]

  lines = content.lines
  original = content.dup
  new_lines = lines.dup
  insertions = 0

  i = 0
  while i < new_lines.length
    line = new_lines[i]

    # Detect synthesize/instance_eval blocks
    if line =~ /^(\s+).*\.(synthesize|instance_eval)\s+do\s*$/
      block_indent = $1
      block_start = i

      # Check if the next few lines already have `extend`
      has_extend = false
      j = i + 1
      depth = 1
      while j < new_lines.length && depth > 0
        l = new_lines[j]
        depth += l.scan(/\bdo\b/).length
        depth -= l.scan(/\bend\b/).length
        has_extend = true if l =~ /extend #{Regexp.escape(module_name)}/
        break if depth <= 0
        j += 1
      end

      unless has_extend
        # Insert `extend Module` as the first line inside the block
        inner_indent = block_indent + "  "
        new_lines.insert(i + 1, "#{inner_indent}extend #{module_name}\n")
        insertions += 1
      end
    end

    i += 1
  end

  new_content = new_lines.join
  if new_content != original
    changes += 1
    File.write(file, new_content)
  end
end

puts "Added extend inside synthesize blocks in #{changes} spec files"
