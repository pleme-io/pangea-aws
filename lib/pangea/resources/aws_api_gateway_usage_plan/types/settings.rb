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

module Pangea
  module Resources
    module AWS
      module Types
        # Throttle settings type for API Gateway usage plans
        ThrottleSettingsType = Resources::Types::Hash.schema(
          burst_limit?: Resources::Types::Integer.optional,
          rate_limit?: Resources::Types::Coercible::Float.optional
        ).lax.optional

        # Quota settings type for API Gateway usage plans
        QuotaSettingsType = Resources::Types::Hash.schema(
          limit: Resources::Types::Integer,
          offset?: Resources::Types::Integer.optional,
          period: Resources::Types::String.constrained(included_in: ['DAY', 'WEEK', 'MONTH'])
        ).lax.optional

        # Per-path throttle settings for API stages
        PathThrottleType = Resources::Types::Hash.schema(
          path?: Resources::Types::String.optional,
          burst_limit?: Resources::Types::Integer.optional,
          rate_limit?: Resources::Types::Coercible::Float.optional
        ).lax.optional

        # API stage configuration type
        ApiStageType = Resources::Types::Hash.schema(
          api_id: Resources::Types::String,
          stage: Resources::Types::String,
          throttle?: PathThrottleType
        ).lax

        # Array of API stages type
        ApiStagesType = Resources::Types::Array.of(ApiStageType).default([].freeze)
      end
    end
  end
end
