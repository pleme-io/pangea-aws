#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix method calls on potentially nil values in resource and builder files.
#
# Patterns:
# 1. `tags.any?` → `tags&.any?`
# 2. `headers.each` → `headers&.each` (or add `return unless headers`)
# 3. `something[:key]` → `something&.dig(:key)` where something is a method parameter
# 4. `something.method` → `something&.method` in specific guard contexts

changes = 0

# Fix specific known nil-guard issues
fixes = {
  # Lambda block_builders: tags.any? on nil
  'lib/pangea/resources/aws_lambda_function/block_builders.rb' => [
    ['return unless tags.any?', 'return unless tags&.any?']
  ],

  # S3 configuration_builder: logging[:target_bucket] on nil
  'lib/pangea/resources/aws_s3_bucket/builders/configuration_builder.rb' => [
    ['return unless logging[:target_bucket]', 'return unless logging&.dig(:target_bucket)'],
    ['return unless object_lock_config[:object_lock_enabled]', 'return unless object_lock_config&.dig(:object_lock_enabled)']
  ],

  # CloudFront origin_builder: headers.each on nil
  'lib/pangea/resources/aws_cloudfront_distribution/builders/origin_builder.rb' => [
    ['build_custom_headers(context, origin_config[:custom_header])', 'build_custom_headers(context, origin_config[:custom_header]) if origin_config[:custom_header]'],
    # Also fix headers.each in build_custom_headers
    ['def build_custom_headers(context, headers)', "def build_custom_headers(context, headers)\n            return unless headers&.any?"]
  ]
}

fixes.each do |file, replacements|
  next unless File.exist?(file)
  content = File.read(file)
  original = content.dup

  replacements.each do |old, new_str|
    content.sub!(old, new_str)
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

# Broader fix: find all .any? calls on variables that could be nil in resource/builder files
(Dir.glob("lib/pangea/resources/aws_*/resource.rb") +
 Dir.glob("lib/pangea/resources/aws_*/builders/*.rb") +
 Dir.glob("lib/pangea/resources/aws_*/block_builders.rb")).each do |file|
  content = File.read(file)
  original = content.dup

  # Fix: return unless something.any? → return unless something&.any?
  content.gsub!(/return unless (\w+)\.any\?/) do |match|
    var = $1
    next match if match.include?('&.')
    "return unless #{var}&.any?"
  end

  # Fix: if something.any? → if something&.any?
  content.gsub!(/if (\w+)\.any\?(?!\s*\{)/) do |match|
    var = $1
    next match if match.include?('&.')
    "if #{var}&.any?"
  end

  # Fix: unless something.empty? → unless something&.empty?
  content.gsub!(/unless (\w+)\.empty\?/) do |match|
    var = $1
    next match if match.include?('&.')
    "unless #{var}&.empty?"
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

# Fix specific known resource files
known_nil_guard_files = {
  'lib/pangea/resources/aws_wafv2_web_acl/resource.rb' => [
    [/return unless (\w+_tags|tags)\.any\?/, 'return unless \1&.any?']
  ],
  'lib/pangea/resources/aws_kinesis_analytics_application/resource.rb' => [
    [/return unless (\w+_tags|tags)\.any\?/, 'return unless \1&.any?']
  ]
}

known_nil_guard_files.each do |file, patterns|
  next unless File.exist?(file)
  content = File.read(file)
  original = content.dup

  patterns.each do |pattern, replacement|
    content.gsub!(pattern, replacement)
  end

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed nil method calls in #{changes} files"
