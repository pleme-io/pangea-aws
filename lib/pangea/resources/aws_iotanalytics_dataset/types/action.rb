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
    module AwsIotanalyticsDatasetTypes
      # Action configuration for dataset content generation
      class Action < Pangea::Resources::BaseAttributes
        schema schema.strict

        # Name of the action
        attribute? :action_name, Resources::Types::String.optional

        # SQL query to execute for data retrieval
        class QueryAction < Pangea::Resources::BaseAttributes
          schema schema.strict

          # SQL query string
          attribute? :sql_query, Resources::Types::String.optional

          # Filter configuration for query results
          unless const_defined?(:Filter)
          class Filter < Pangea::Resources::BaseAttributes
            schema schema.strict

            # Delta time filter for incremental processing
            class DeltaTime < Pangea::Resources::BaseAttributes
              schema schema.strict

              # Offset in seconds from current time
              attribute? :offset_seconds, Resources::Types::Integer.optional

              # Time expression for filtering
              attribute? :time_expression, Resources::Types::String.optional
            end

            attribute? :delta_time, DeltaTime.optional
          end
          end

          attribute :filters, Resources::Types::Array.of(Filter).default([].freeze)
        end

        attribute? :query_action, QueryAction.optional

        # Container action for custom data processing
        class ContainerAction < Pangea::Resources::BaseAttributes
          schema schema.strict

          # Docker image URI for processing
          attribute? :image, Resources::Types::String.optional

          # Execution role ARN
          attribute? :execution_role_arn, Resources::Types::String.optional

          # Resource configuration
          class ResourceConfiguration < Pangea::Resources::BaseAttributes
            schema schema.strict

            # Compute type for processing
            attribute? :compute_type, Resources::Types::String.constrained(included_in: ['ACU_1', 'ACU_2']).optional

            # Volume size in GB
            attribute? :volume_size_in_gb, Resources::Types::Integer.constrained(gteq: 1, lteq: 50).optional
          end

          attribute? :resource_configuration, ResourceConfiguration.optional

          # Environment variables for container
          attribute :variables, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)
        end

        attribute? :container_action, ContainerAction.optional
      end
    end
  end
end
