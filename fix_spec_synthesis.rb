#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix spec files that use the wrong synthesis pattern.
#
# WRONG pattern:
#   terraform_output = synthesizer.synthesize do ... end
#   json_output = JSON.parse(terraform_output)
#
# CORRECT pattern:
#   synthesizer.synthesize do ... end
#   result = synthesizer.synthesis
#   (use result hash directly — it has symbol keys from TerraformSynthesizer)
#
# Strategy: Replace `JSON.parse(terraform_output)` with `synthesizer.synthesis`
# and change symbol/string key access to match.

changes = 0

Dir.glob("spec/**/*.rb").each do |file|
  content = File.read(file)
  original = content.dup

  # Pattern: `json_output = JSON.parse(terraform_output)`
  # Replace with: `json_output = JSON.parse(synthesizer.synthesis.to_json)`
  # This converts symbol keys to string keys (keeping existing .dig("resource", ...) working)
  content.gsub!(/json_output\s*=\s*JSON\.parse\(terraform_output\)/,
                'json_output = JSON.parse(synthesizer.synthesis.to_json)')

  if content != original
    changes += 1
    File.write(file, content)
  end
end

puts "Fixed #{changes} spec files with synthesis pattern"
