#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix `expect(x).to have(N).items` — requires rspec-collection_matchers gem.
# Replace with standard `expect(x.size).to eq(N)`.

changes = 0
count = 0

Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Pattern: expect(something).to have(N).items
  content.gsub!(/expect\(([^)]+)\)\.to have\((\d+)\)\.items/) do |match|
    subject = $1
    num = $2
    count += 1
    "expect(#{subject}.size).to eq(#{num})"
  end

  # Pattern: expect(something).to have(N).characters
  content.gsub!(/expect\(([^)]+)\)\.to have\((\d+)\)\.characters/) do |match|
    subject = $1
    num = $2
    count += 1
    "expect(#{subject}.length).to eq(#{num})"
  end

  # Pattern: expect(something).to have(N).item (singular)
  content.gsub!(/expect\(([^)]+)\)\.to have\((\d+)\)\.item\b/) do |match|
    subject = $1
    num = $2
    count += 1
    "expect(#{subject}.size).to eq(#{num})"
  end

  # Pattern: expect(something).to have_key('key')
  # This is a built-in RSpec matcher, should be fine — skip

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed #{count} have() matchers in #{changes} spec files"
