#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix `.gsub` / `.sub` / `.downcase` called on Symbol keys.
#
# Hash keys from Dry::Struct are Symbols, but many resource files
# call String methods directly on them. Fix by adding `.to_s`.
#
# Patterns:
#   key.gsub(...)    → key.to_s.gsub(...)
#   key.downcase     → key.to_s.downcase
#   attr_name.gsub   → attr_name.to_s.gsub
# But NOT if `.to_s` is already there.

changes = 0

Dir.glob("lib/pangea/resources/aws_*/resource.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Fix: key.gsub → key.to_s.gsub (for hash iteration variables)
  # Match variable names like key, dim_key, attr_name, tag_key
  content.gsub!(/\b(\w*(?:key|attr_name|dim_key|tag_key))\.(gsub|sub|downcase|upcase|match\?|start_with\?|end_with\?|include\?)/) do |match|
    var = $1
    method = $2
    if match.include?('.to_s.')
      match
    else
      "#{var}.to_s.#{method}"
    end
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed string methods on symbol keys in #{changes} resource files"
