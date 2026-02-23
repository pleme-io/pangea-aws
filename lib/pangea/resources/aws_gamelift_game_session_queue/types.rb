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

require "dry-struct"
require 'pangea/resources/types'

module Pangea
  module Resources
    module AwsGameliftGameSessionQueue
      module Types
        # Player latency policy for queue
        class PlayerLatencyPolicy < Pangea::Resources::BaseAttributes
          attribute? :maximum_individual_player_latency_milliseconds, Pangea::Resources::Types::Integer.optional
          attribute :policy_duration_seconds?, Pangea::Resources::Types::Integer
        end

        # Destination for game sessions
        unless const_defined?(:Destination)
        class Destination < Pangea::Resources::BaseAttributes
          attribute? :destination_arn, Pangea::Resources::Types::String.optional
        end

        # Filter configuration for fleet selection
        class FilterConfiguration < Pangea::Resources::BaseAttributes
          attribute :allowed_locations?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String)
        end

        # Priority configuration for destinations
        class PriorityConfiguration < Pangea::Resources::BaseAttributes
          attribute :location_order?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String)
          attribute :priority_order?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String.constrained(included_in: ["COST", "DESTINATION", "LATENCY", "LOCATION"]))
        end

        # Main attributes for GameLift game session queue

        # Reference for GameLift game session queue resources
      end
        end
    end
  end
end