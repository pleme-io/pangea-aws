# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Elemental Data Plane Channel resources
      class ElementalDataPlaneChannelAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Channel name (required)
        attribute :name, Resources::Types::String

        # Channel description
        attribute :description, Resources::Types::String.default("")

        # Channel type
        attribute :channel_type, Resources::Types::String.constrained(included_in: ['LIVE', 'PLAYOUT']).default('LIVE')

        # Input specifications
        attribute :input_specifications, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            codec: Resources::Types::String.constrained(included_in: ['MPEG2', 'AVC', 'HEVC']),
            maximum_bitrate: Resources::Types::String.constrained(included_in: ['MAX_10_MBPS', 'MAX_20_MBPS', 'MAX_50_MBPS']),
            resolution: Resources::Types::String.constrained(included_in: ['SD', 'HD', 'UHD'])
          )
        ).default([].freeze)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Helper methods
        def live_channel?
          channel_type == 'LIVE'
        end

        def playout_channel?
          channel_type == 'PLAYOUT'
        end

        def has_input_specs?
          input_specifications.any?
        end
      end
    end
      end
    end
  end
