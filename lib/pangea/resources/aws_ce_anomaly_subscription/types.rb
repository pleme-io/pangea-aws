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
        # Anomaly subscription frequency
        AnomalySubscriptionFrequency = Resources::Types::String.constrained(included_in: ['DAILY', 'IMMEDIATE', 'WEEKLY'])
        
        # Anomaly subscription threshold types
        AnomalyThresholdExpression = Resources::Types::String.constrained(included_in: ['AND', 'OR', 'DIMENSION', 'MATCH_OPTIONS'])
        
        class AnomalySubscriptionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Resources::Types::String.constrained(format: /\A[a-zA-Z0-9\s\-_\.]{1,128}\z/)
          attribute :frequency, AnomalySubscriptionFrequency
          attribute :monitor_arn_list, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 1024)
          attribute :subscribers, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 1024)
          attribute :threshold_expression?, Resources::Types::String.optional
          attribute :tags?, Resources::Types::AwsTags.optional
          
          def subscriber_count
            subscribers.length
          end
          
          def monitor_count  
            monitor_arn_list.length
          end
          
          def is_immediate?
            frequency == 'IMMEDIATE'
          end
          
          def has_threshold?
            !threshold_expression.nil?
          end
        end
      end
    end
  end
end