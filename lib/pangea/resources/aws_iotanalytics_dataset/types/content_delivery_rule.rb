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
      # Content delivery rules for dataset output
      class ContentDeliveryRule < Pangea::Resources::BaseAttributes
        schema schema.strict

        # Entry name for the rule
        attribute? :entry_name, Resources::Types::String.optional

        # S3 destination configuration
        unless const_defined?(:Destination)
        class Destination < Pangea::Resources::BaseAttributes
          schema schema.strict

          class S3DestinationConfiguration < Pangea::Resources::BaseAttributes
            schema schema.strict

            # S3 bucket name
            attribute? :bucket, Resources::Types::String.optional

            # Object key prefix
            attribute? :key, Resources::Types::String.optional

            # Glue database configuration
            class GlueConfiguration < Pangea::Resources::BaseAttributes
              schema schema.strict

              # Glue table name
              attribute? :table_name, Resources::Types::String.optional

              # Glue database name
              attribute? :database_name, Resources::Types::String.optional
            end

            attribute? :glue_configuration, GlueConfiguration.optional

            # IAM role ARN for S3 access
            attribute? :role_arn, Resources::Types::String.optional
          end

          attribute? :s3_destination_configuration, S3DestinationConfiguration.optional
        end
        end

        attribute? :destination, Destination.optional
      end
    end
  end
end
