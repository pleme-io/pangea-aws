#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix template/factory methods that are defined in separate Templates modules
# but not wired as class methods on the Attributes classes.
#
# The specs call e.g. BatchComputeEnvironmentAttributes.spot_managed_environment(...)
# but the method is in BatchComputeEnvironmentTemplates module.
# Fix: extend the attributes class with the templates module.

changes = 0

Dir.glob("lib/pangea/resources/aws_*/types/templates.rb").each do |templates_file|
  content = File.read(templates_file)

  # Extract the module name from the templates file
  module_match = content.match(/module (\w+Templates)/)
  next unless module_match

  module_name = module_match[1]

  # Find the corresponding attributes file
  resource_dir = File.dirname(templates_file)
  attributes_file = File.join(resource_dir, "attributes.rb")
  next unless File.exist?(attributes_file)

  attrs_content = File.read(attributes_file)

  # Check if the templates module is already extended
  if attrs_content.include?("extend #{module_name}")
    next
  end

  # Find the class definition and add extend after it
  # Pattern: class SomethingAttributes < Pangea::Resources::BaseAttributes
  if attrs_content.match?(/class (\w+Attributes) < Pangea::Resources::BaseAttributes/)
    class_name_match = attrs_content.match(/class (\w+Attributes) < Pangea::Resources::BaseAttributes/)
    class_name = class_name_match[1]

    # Add extend after the class line
    attrs_content.sub!(
      /class #{Regexp.escape(class_name)} < Pangea::Resources::BaseAttributes/,
      "class #{class_name} < Pangea::Resources::BaseAttributes\n          extend #{module_name}"
    )

    changes += 1
    File.write(attributes_file, attrs_content)
    puts "Extended #{class_name} with #{module_name} in #{attributes_file}"
  end
end

# Also check for types files that have Templates modules directly (single-file types)
Dir.glob("lib/pangea/resources/aws_*/types.rb").each do |types_file|
  content = File.read(types_file)

  module_match = content.match(/module (\w+Templates)/)
  next unless module_match

  module_name = module_match[1]

  # Find the class definition and add extend
  class_match = content.match(/class (\w+Attributes) < Pangea::Resources::BaseAttributes/)
  next unless class_match

  class_name = class_match[1]

  if content.include?("extend #{module_name}")
    next
  end

  content.sub!(
    /class #{Regexp.escape(class_name)} < Pangea::Resources::BaseAttributes/,
    "class #{class_name} < Pangea::Resources::BaseAttributes\n          extend #{module_name}"
  )

  changes += 1
  File.write(types_file, content)
  puts "Extended #{class_name} with #{module_name} in #{types_file}"
end

puts "\nFixed #{changes} attribute classes with template extensions"
