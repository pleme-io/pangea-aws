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
    # AWS IoT Job Template Types
    # 
    # Job templates define reusable job configurations for device fleet management.
    # They enable consistent job deployment across device groups with standardized
    # parameters, timeouts, and retry policies.
    module AwsIotJobTemplateTypes
      # Timeout configuration for job execution
      class TimeoutConfig < Dry::Struct
        schema schema.strict

        # Timeout for job execution in minutes
        attribute :in_progress_timeout_in_minutes, Resources::Types::Integer.optional
      end

      # Job execution rollout configuration
      class JobExecutionsRolloutConfig < Dry::Struct
        schema schema.strict

        # Maximum number of job executions per minute
        attribute :maximum_per_minute, Resources::Types::Integer.optional
      end

      # Abort criteria for job execution
      class AbortConfig < Dry::Struct
        schema schema.strict

        class CriteriaList < Dry::Struct
          schema schema.strict

          # Failure type that triggers abort
          attribute :failure_type, Resources::Types::String.constrained(included_in: ['FAILED', 'REJECTED', 'TIMED_OUT', 'ALL'])

          # Action to take when criteria is met
          attribute :action, Resources::Types::String.constrained(included_in: ['CANCEL'])

          # Threshold percentage for triggering abort
          attribute :threshold_percentage, Resources::Types::Float.constrained(gteq: 0.0, lteq: 100.0)

          # Minimum number of things for percentage calculation
          attribute :min_number_of_executed_things, Resources::Types::Integer
        end

        # List of abort criteria
        attribute :criteria_list, Resources::Types::Array.of(CriteriaList)
      end

      # Main attributes for IoT job template resource

      # Output attributes from job template resource
    end
  end
end