# fix_constraint_error.rb
# Replaces Dry::Types::ConstraintError with Dry::Struct::Error in spec files
# because Dry::Struct wraps the underlying ConstraintError in its own Error class.

require 'find'

spec_dir = File.join(__dir__, 'spec')
files_fixed = 0
total_replacements = 0

Find.find(spec_dir) do |path|
  next unless path.end_with?('.rb')

  content = File.read(path)
  original = content.dup

  # Replace all variations:
  #   raise_error(Dry::Types::ConstraintError)
  #   raise_error(Dry::Types::ConstraintError, /some message/)
  #   raise_error(Dry::Types::ConstraintError, "some message")
  count = 0
  content.gsub!(/Dry::Types::ConstraintError/) do
    count += 1
    'Dry::Struct::Error'
  end

  if content != original
    File.write(path, content)
    files_fixed += 1
    total_replacements += count
    puts "FIXED: #{path.sub(__dir__ + '/', '')} (#{count} replacement#{'s' if count != 1})"
  end
end

puts
puts "=" * 60
puts "Done! Fixed #{total_replacements} occurrences across #{files_fixed} files."
