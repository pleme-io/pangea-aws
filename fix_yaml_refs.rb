#!/usr/bin/env ruby
# frozen_string_literal: true

changes = 0
Dir.glob("lib/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup
  content.gsub!(/(?<!:)YAML\.safe_load/, '::YAML.safe_load')
  content.gsub!(/(?<!:)YAML\.dump/, '::YAML.dump')
  content.gsub!(/(?<!:)YAML\.load/, '::YAML.load')
  if content != original
    changes += 1
    File.write(file, content)
  end
end
puts "Fixed #{changes} files"
