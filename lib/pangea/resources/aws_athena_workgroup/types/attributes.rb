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
        # Type-safe attributes for AWS Athena Workgroup resources
        class AthenaWorkgroupAttributes < Pangea::Resources::BaseAttributes
          extend AthenaWorkgroupClassMethods
          extend AthenaWorkgroupValidation
          include AthenaWorkgroupInstanceMethods

          # Workgroup name (required)
          attribute? :name, Resources::Types::String.optional

          # Workgroup description
          attribute? :description, Resources::Types::String.optional

          # State of the workgroup
          attribute :state, Resources::Types::String.constrained(included_in: ['ENABLED', 'DISABLED']).default('ENABLED')

          # Force destroy workgroup and contents
          attribute :force_destroy, Resources::Types::Bool.default(false)

          # Workgroup configuration
          attribute? :configuration, Resources::Types::Hash.schema(
            # Query result configuration
            result_configuration?: Resources::Types::Hash.schema(
              output_location?: Resources::Types::String.optional,
              encryption_configuration?: Resources::Types::Hash.schema(
                encryption_option: Resources::Types::String.constrained(included_in: ['SSE_S3', 'SSE_KMS', 'CSE_KMS']),
                kms_key_id?: Resources::Types::String.optional
              ).lax.optional,
              expected_bucket_owner?: Resources::Types::String.optional,
              acl_configuration?: Resources::Types::Hash.schema(
                s3_acl_option: Resources::Types::String.constrained(included_in: ['BUCKET_OWNER_FULL_CONTROL'])
              ).lax.optional
            ).optional,

            # Execution configuration
            enforce_workgroup_configuration?: Resources::Types::Bool.optional,
            publish_cloudwatch_metrics_enabled?: Resources::Types::Bool.optional,
            bytes_scanned_cutoff_per_query?: Resources::Types::Integer.optional,
            requester_pays_enabled?: Resources::Types::Bool.optional,

            # Engine version
            engine_version?: Resources::Types::Hash.schema(
              selected_engine_version?: Resources::Types::String.optional,
              effective_engine_version?: Resources::Types::String.optional
            ).lax.optional,

            # Result configuration override
            result_configuration_updates?: Resources::Types::Hash.schema(
              output_location?: Resources::Types::String.optional,
              remove_output_location?: Resources::Types::Bool.optional,
              encryption_configuration?: Resources::Types::Hash.schema(
                encryption_option: Resources::Types::String.constrained(included_in: ['SSE_S3', 'SSE_KMS', 'CSE_KMS']),
                kms_key_id?: Resources::Types::String.optional
              ).lax.optional,
              remove_encryption_configuration?: Resources::Types::Bool.optional
            ).optional,

            # Execution role
            execution_role?: Resources::Types::String.optional,

            # Customer content encryption
            customer_content_encryption_configuration?: Resources::Types::Hash.schema(
              kms_key_id: Resources::Types::String
            ).lax.optional
          ).optional

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_workgroup_name(attrs.name)
            validate_kms_encryption(attrs.configuration)
            validate_bytes_cutoff(attrs.configuration)
            attrs
          end
        end
      end
    end
  end
end
