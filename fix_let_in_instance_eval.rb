#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix RSpec `let` variables used inside `instance_eval` blocks.
#
# Problem: `instance_eval` changes `self` to the synthesizer, so `let` variables
# (which are methods on the example group) become inaccessible and trigger
# `method_missing` → `InvalidSynthesizerKeyError`.
#
# Solution: Capture `let` variables into local variables before `instance_eval`,
# then reference the locals inside the block.
#
# BEFORE:
#   let(:rest_api_id) { "abc123" }
#   it "test" do
#     synthesizer.instance_eval do
#       aws_api_gateway_resource(:x, { rest_api_id: rest_api_id })
#     end
#   end
#
# AFTER:
#   let(:rest_api_id) { "abc123" }
#   it "test" do
#     _rest_api_id = rest_api_id
#     synthesizer.instance_eval do
#       aws_api_gateway_resource(:x, { rest_api_id: _rest_api_id })
#     end
#   end

changes = 0

Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  lines = content.lines

  # Step 1: Collect all `let` variable names in this file
  let_vars = []
  lines.each do |line|
    if line =~ /let\(:(\w+)\)/
      let_vars << $1
    end
  end
  next if let_vars.empty?

  # Step 2: Find instance_eval blocks and check if they reference let vars
  original = content.dup
  new_lines = lines.dup
  offset = 0  # track insertions

  i = 0
  while i < new_lines.length
    line = new_lines[i]

    # Detect `instance_eval do` or `synthesize do` (with optional assignment before)
    if line =~ /^(\s*).*\.(instance_eval|synthesize)\s+do\s*$/
      block_indent = $1
      block_start = i

      # Find the matching `end`
      depth = 1
      block_end = nil
      j = i + 1
      while j < new_lines.length && depth > 0
        l = new_lines[j]
        # Count do/end — be careful with inline blocks
        depth += l.scan(/\bdo\b/).length
        depth -= l.scan(/\bend\b/).length
        if depth == 0
          block_end = j
        end
        j += 1
      end

      next i += 1 unless block_end

      # Collect the block content
      block_content = new_lines[(block_start + 1)...block_end].join

      # Find which let vars are referenced in the block as bare identifiers
      # (not as symbol keys like `rest_api_id:` on the left side of a hash)
      used_lets = []
      let_vars.each do |var|
        # Match the variable used as a VALUE (not a hash key label)
        # Patterns where let var is used as value:
        #   something: rest_api_id,   (hash value)
        #   something: rest_api_id    (hash value, last in hash)
        #   [rest_api_id]             (array element)
        #   rest_api_id               (standalone, like a method call)
        #   foo(rest_api_id)          (argument)
        # But NOT:
        #   rest_api_id:              (hash key label)
        #   :rest_api_id              (symbol)
        #   extend ...rest_api_id     (not a thing, but safe)

        # Check if the var appears as a value reference (not just a hash key)
        # A hash key is `word:` at the start (followed by space).
        # A value reference is the var NOT immediately followed by `:`
        if block_content.match?(/(?<![:\w])#{Regexp.escape(var)}(?![\w:])/)
          # But exclude cases where it only appears as a hash key (var:)
          # Count value usages vs key usages
          value_uses = block_content.scan(/(?<![:\w])#{Regexp.escape(var)}(?![\w:])/).length
          key_uses = block_content.scan(/\b#{Regexp.escape(var)}:/).length

          # If value_uses > key_uses, there are genuine value references
          # (key uses like `rest_api_id: rest_api_id` have both a key and value use)
          if value_uses > 0
            used_lets << var
          end
        end
      end

      if used_lets.any?
        # Insert local variable captures before the instance_eval line
        # Find the `it` block's indent level (should be block_indent minus some)
        it_indent = block_indent

        captures = used_lets.map { |var| "#{it_indent}_#{var} = #{var}" }

        # Insert captures before the instance_eval line
        captures.each_with_index do |capture, idx|
          new_lines.insert(block_start + idx, capture + "\n")
        end

        # Adjust block_end for insertions
        block_end += captures.length

        # Now replace var references inside the block with _var
        used_lets.each do |var|
          ((block_start + captures.length + 1)..block_end).each do |k|
            next unless new_lines[k]
            # Replace value references (not key labels) inside the block
            # Replace `var` but not `var:` (hash key) and not `:var` (symbol)
            new_lines[k] = new_lines[k].gsub(/(?<![:\w])#{Regexp.escape(var)}(?![\w:])/, "_#{var}")
          end
        end

        i = block_end + 1
        next
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

puts "Fixed let variable capture in #{changes} spec files"
