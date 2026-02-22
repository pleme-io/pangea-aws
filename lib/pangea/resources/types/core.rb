# frozen_string_literal: true

# Shim: pangea-core already defines Pangea::Resources::Types in its own
# types/core.rb.  This file exists so that `require_relative '../core'`
# inside types/aws/*.rb resolves without error — it is intentionally empty
# because the real module is loaded by `require 'pangea-core'`.
