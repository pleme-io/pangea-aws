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

require 'dry-types'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        include Dry.Types()

        # SageMaker Endpoint deployment configuration for updates
        SageMakerDeploymentConfig = Resources::Types::Hash.schema(
          blue_green_update_policy?: Resources::Types::Hash.schema(
            traffic_routing_configuration: Resources::Types::Hash.schema(
              type: Resources::Types::String.constrained(included_in: ['ALL_AT_ONCE', 'CANARY', 'LINEAR']),
              wait_interval_in_seconds: Resources::Types::Integer.constrained(gteq: 0, lteq: 3600),
              canary_size?: Resources::Types::Hash.schema(
                type: Resources::Types::String.constrained(included_in: ['INSTANCE_COUNT', 'CAPACITY_PERCENT']),
                value: Resources::Types::Integer.constrained(gteq: 1, lteq: 100)
              ).lax.optional,
              linear_step_size?: Resources::Types::Hash.schema(
                type: Resources::Types::String.constrained(included_in: ['INSTANCE_COUNT', 'CAPACITY_PERCENT']),
                value: Resources::Types::Integer.constrained(gteq: 1, lteq: 100)
              ).lax.optional
            ),
            termination_wait_in_seconds?: Resources::Types::Integer.constrained(gteq: 0, lteq: 3600).optional,
            maximum_execution_timeout_in_seconds?: Resources::Types::Integer.constrained(gteq: 600, lteq: 14400).optional
          ).optional,
          auto_rollback_configuration?: Resources::Types::Hash.schema(
            alarms?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                alarm_name: Resources::Types::String
              ).lax
            ).optional
          ).optional
        )
      end
    end
  end
end
