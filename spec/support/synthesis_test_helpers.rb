# frozen_string_literal: true

# Load shared test helpers from pangea-core
require 'pangea/testing'

# Top-level aliases for backwards compatibility with existing specs
SynthesisTestHelpers = Pangea::Testing::SynthesisTestHelpers unless defined?(SynthesisTestHelpers)
MockTerraformSynthesizer = Pangea::Testing::MockTerraformSynthesizer unless defined?(MockTerraformSynthesizer)
MockResourceReference = Pangea::Testing::MockResourceReference unless defined?(MockResourceReference)
