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
    module AwsGameliftAlias
      module Types
        # Routing strategy for the alias
        class RoutingStrategy < Dry::Struct
          attribute :type, Pangea::Resources::Types::String.constrained(included_in: ["SIMPLE", "TERMINAL"])
          attribute :fleet_id?, Pangea::Resources::Types::String
          attribute :message?, Pangea::Resources::Types::String

          def self.from_dynamic(d)
            d = Pangea::Resources::Types::Hash[d]
            
            # Validate based on type
            case d[:type]
            when "SIMPLE"
              unless d[:fleet_id]
                raise ArgumentError, "fleet_id is required when routing_strategy type is SIMPLE"
              end
            when "TERMINAL"
              unless d[:message]
                raise ArgumentError, "message is required when routing_strategy type is TERMINAL"
              end
            end

            new(
              type: d.fetch(:type),
              fleet_id: d[:fleet_id],
              message: d[:message]
            )
          end
        end

        # Main attributes for GameLift alias

        # Reference for GameLift alias resources
      end
    end
  end
end