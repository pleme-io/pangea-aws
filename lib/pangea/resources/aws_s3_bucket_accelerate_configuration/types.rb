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

module Pangea
  module Resources
    module AWS
      module S3BucketAccelerateConfiguration
        # Common types for S3 Bucket Accelerate Configuration
        module Types
          # Transfer acceleration status
          AccelerationStatus = Resources::Types::String.constrained(included_in: ['Enabled', 'Suspended'])
          
          # S3 Bucket Name constraint
          unless const_defined?(:BucketName)
          BucketName = Resources::Types::String.constrained(
            min_size: 3,
            max_size: 63,
            format: /\A[a-z0-9\-\.]+\z/
          )
          end
        end

        # S3 Bucket Accelerate Configuration attributes
        class S3BucketAccelerateConfigurationAttributes < Dry::Struct
          # Required attributes
          attribute :bucket, Types::BucketName
          attribute :status, Types::AccelerationStatus
          
          # Optional attributes
          attribute? :expected_bucket_owner, Resources::Types::String.constrained(format: /\A\d{12}\z/).optional
          
          # Computed properties
          def acceleration_enabled?
            status == 'Enabled'
          end
          
          def acceleration_suspended?
            status == 'Suspended'
          end
          
          def cross_account_bucket?
            !expected_bucket_owner.nil?
          end
        end
      end
    end
  end
end