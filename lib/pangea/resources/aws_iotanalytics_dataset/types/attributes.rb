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
      # Main attributes for IoT Analytics dataset resource
      unless const_defined?(:Attributes)
      class Attributes < Pangea::Resources::BaseAttributes
        schema schema.strict

        # Name of the dataset
        attribute? :dataset_name, Resources::Types::String.optional

        # List of actions for dataset content generation
        attribute :actions, Resources::Types::Array.of(Action).default([].freeze)

        # Content delivery rules
        attribute :content_delivery_rules, Resources::Types::Array.of(ContentDeliveryRule).default([].freeze)

        # Triggers for dataset content generation
        attribute :triggers, Resources::Types::Array.of(Trigger).default([].freeze)

        # Optional data retention period
        class RetentionPeriod < Pangea::Resources::BaseAttributes
          schema schema.strict

          # Whether retention is unlimited
          attribute? :unlimited, Resources::Types::Bool.optional

          # Number of days to retain (if not unlimited)
          attribute? :number_of_days, Resources::Types::Integer.optional
        end

        attribute? :retention_period, RetentionPeriod.optional

        # Versioning configuration
        class VersioningConfiguration < Pangea::Resources::BaseAttributes
          schema schema.strict

          # Whether versioning is unlimited
          attribute? :unlimited, Resources::Types::Bool.optional

          # Maximum number of versions to keep
          attribute? :max_versions, Resources::Types::Integer.optional
        end

        attribute? :versioning_configuration, VersioningConfiguration.optional

        # Resource tags
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)
      end
      end

      # Output attributes from dataset resource
      unless const_defined?(:Outputs)
      class Outputs < Pangea::Resources::BaseAttributes
        schema schema.strict

        # The dataset ARN
        attribute? :arn, Resources::Types::String.optional

        # The dataset name
        attribute? :name, Resources::Types::String.optional
      end
      end
    end
  end
end
