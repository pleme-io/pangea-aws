#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix bare JSON. references to ::JSON. to avoid shadowing by Dry.Types()

changes = 0
Dir.glob("lib/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Replace JSON.parse, JSON.pretty_generate, JSON.generate, JSON.dump
  # but not ::JSON. (already qualified)
  content.gsub!(/(?<!:)JSON\.parse/, '::JSON.parse')
  content.gsub!(/(?<!:)JSON\.pretty_generate/, '::JSON.pretty_generate')
  content.gsub!(/(?<!:)JSON\.generate/, '::JSON.generate')
  content.gsub!(/(?<!:)JSON\.dump/, '::JSON.dump')

  if content != original
    changes += 1
    File.write(file, content)
    puts "Fixed #{file}"
  end
end

puts "\nFixed #{changes} files"
