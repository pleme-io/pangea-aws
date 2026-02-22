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
      module S3AccessPoint
        # Common types for S3 Access Point configurations
        module Types
          # S3 Access Point Account Owner ID constraint
          AccessPointAccountId = Resources::Types::String.constrained(format: /\A\d{12}\z/)
          
          # S3 Access Point Name constraint  
          AccessPointName = Resources::Types::String.constrained(min_size: 3, max_size: 63, format: /\A[a-z0-9\-]+\z/)
          
          # S3 Access Point Network Origin
          NetworkOrigin = Resources::Types::String.constrained(included_in: ['Internet', 'VPC'])
          
          # VPC Configuration for Access Point
          unless const_defined?(:VpcConfiguration)
          VpcConfiguration = Resources::Types::Hash.schema({
            vpc_id: Resources::Types::String
          })
          end
          
          # Public Access Block Configuration
          unless const_defined?(:PublicAccessBlockConfiguration)
          PublicAccessBlockConfiguration = Resources::Types::Hash.schema({
            block_public_acls?: Resources::Types::Bool,
            block_public_policy?: Resources::Types::Bool,
            ignore_public_acls?: Resources::Types::Bool,
            restrict_public_buckets?: Resources::Types::Bool
          })
          end
        end

        # S3 Access Point attributes with comprehensive validation
        class S3AccessPointAttributes < Dry::Struct
          # Required attributes
          attribute :account_id, Types::AccessPointAccountId
          attribute :bucket, Resources::Types::String
          attribute :name, Types::AccessPointName
          
          # Optional attributes
          attribute? :bucket_account_id, Types::AccessPointAccountId
          attribute? :network_origin, Types::NetworkOrigin.default('Internet')
          attribute? :policy, Resources::Types::String.optional
          attribute? :vpc_configuration, Types::VpcConfiguration.optional
          attribute? :public_access_block_configuration, Types::PublicAccessBlockConfiguration.default({}.freeze)
          
          # Computed properties
          def vpc_access_point?
            network_origin == 'VPC'
          end
          
          def internet_access_point?
            network_origin == 'Internet'
          end
          
          def has_public_access_block?
            public_access_block_configuration.any?
          end
          
          def cross_account_access?
            bucket_account_id && bucket_account_id != account_id
          end
        end
      end
    end
  end
end