#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix private method name collisions in resource files.
#
# Multiple resources define `build_resource_reference` and other helper methods
# in the same module (Pangea::Resources::AWS). Since Ruby module methods are
# global to the module, the last file loaded wins and other resources call
# the wrong implementation.
#
# Fix: rename private methods to include the resource name prefix.

changes = 0

# Find all private method definitions in resource files
# and rename them to avoid collisions
Dir.glob("lib/pangea/resources/aws_*/resource.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Extract resource name from directory
  resource_dir = File.basename(File.dirname(file))  # e.g., "aws_s3_bucket"

  # Common collision-prone method names
  %w[
    build_resource_reference
    build_distribution
    build_tags
    build_public_access_block
    build_input_configuration
    build_target_configurations
    build_error_handling
  ].each do |method_name|
    # Only rename if this file actually defines this method
    next unless content.include?("def #{method_name}")

    # Generate unique name: build_resource_reference → build_aws_s3_bucket_resource_reference
    unique_name = method_name.sub('build_', "build_#{resource_dir}_")

    # Replace definition
    content.gsub!(/\bdef #{Regexp.escape(method_name)}\b/, "def #{unique_name}")

    # Replace all calls within the same file
    content.gsub!(/\b#{Regexp.escape(method_name)}\(/, "#{unique_name}(")
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed method name collisions in #{changes} resource files"
