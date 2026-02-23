#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix remaining required attributes that don't have defaults.
#
# Only change `attribute :name,` to `attribute? :name,` when:
# - It's NOT already `attribute?`
# - The attribute name does NOT end with `?` (already optional via Dry convention)
# - The line does NOT have `.default(`

changes = 0
attr_count = 0

(Dir.glob("lib/pangea/resources/aws_*/types.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types/*.rb")).each do |file|
  content = File.read(file)
  original = content.dup
  lines = content.lines

  lines.each_with_index do |line, i|
    # Only match `attribute :name,` (not `attribute?` and not `:name?`)
    next unless line =~ /^(\s+)attribute\s+:(\w+),/
    attr_name = $2

    # Skip if already attribute? or if attribute name ends with ?
    next if line.include?('attribute?')
    next if line.match?(/attribute\s+:\w+\?,/)
    # Skip if has default value
    next if line.include?('.default(')

    # Replace `attribute :name,` with `attribute? :name,`
    lines[i] = line.sub(/attribute(\s+:)/, 'attribute?\1')
    attr_count += 1
  end

  new_content = lines.join
  if new_content != original
    changes += 1
    File.write(file, new_content)
  end
end

puts "Made #{attr_count} remaining attributes optional in #{changes} type files"
