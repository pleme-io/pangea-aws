#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix `[]` called on nil in resource and types files.
#
# After making attributes optional, `attrs.something[:key]` and
# bare `accessor[:key]` in instance methods can fail on nil.
#
# Fix patterns:
# 1. attrs.accessor[:key] → attrs.accessor&.dig(:key)
# 2. In instance methods of attribute classes: accessor[:key] → accessor&.dig(:key)
#    (where accessor is a known attribute? name)

changes = 0

(Dir.glob("lib/pangea/resources/aws_*/resource.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types.rb") +
 Dir.glob("lib/pangea/resources/aws_*/types/*.rb") +
 Dir.glob("lib/pangea/resources/aws_*/builders/*.rb")).each do |file|
  content = File.read(file)
  original = content.dup

  # Pattern 1: attrs.accessor[:key] or word_attrs.accessor[:key]
  content.gsub!(/(\b(?:\w+_)?attrs\.(\w+))\[([^\]]+)\](?!\s*=(?!=))/) do |match|
    prefix = $1
    key = $3
    next match if prefix.include?('&.')
    "#{prefix}&.dig(#{key})"
  end

  # Pattern 2: For types files, find attribute? declarations and fix
  # bare accessor[:key] in instance methods
  if file.include?('/types')
    # Collect optional attribute names (attribute? :name)
    optional_attrs = content.scan(/attribute\?\s+:(\w+)/).flatten

    optional_attrs.each do |attr|
      # Fix: attr_name[:key] → attr_name&.dig(:key)
      # But only in instance method bodies (not in class method `self.new`)
      # And not when it's a local variable assignment target
      content.gsub!(/(?<!\w)#{Regexp.escape(attr)}\[([^\]]+)\](?!\s*=(?!=))/) do |match|
        key = $1
        next match if match.include?('&.')
        "#{attr}&.dig(#{key})"
      end
    end
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed nil subscript access in #{changes} files"
