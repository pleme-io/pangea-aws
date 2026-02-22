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
      module S3MultiRegionAccessPoint
        # Common types for S3 Multi-Region Access Point configurations
        module Types
          # S3 Multi-Region Access Point Name constraint  
          MultiRegionAccessPointName = Resources::Types::String.constrained(
            min_size: 3, 
            max_size: 50,
            format: /\A[a-z0-9\-]+\z/
          )
          
          # AWS Region constraint
          AwsRegion = Resources::Types::String.constrained(
            format: /\A[a-z]{2}-[a-z]+-\d\z/
          )
          
          # Region Configuration for Multi-Region Access Point
          RegionConfiguration = Resources::Types::Hash.schema({
            bucket: Resources::Types::String,
            region: Resources::Types::AwsRegion,
            bucket_account_id?: Resources::Types::String.constrained(format: /\A\d{12}\z/)
          })
          
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

        # S3 Multi-Region Access Point attributes with comprehensive validation
        class S3MultiRegionAccessPointAttributes < Dry::Struct
          # Required attributes
          attribute :details, Resources::Types::Hash.schema({
            name: Types::MultiRegionAccessPointName,
            public_access_block_configuration?: Types::PublicAccessBlockConfiguration.default({}.freeze),
            region: Resources::Types::Array.of(Types::RegionConfiguration).constrained(min_size: 1, max_size: 20)
          })
          
          # Optional attributes
          attribute? :account_id, Resources::Types::String.constrained(format: /\A\d{12}\z/).optional
          
          # Computed properties
          def access_point_name
            details[:name]
          end
          
          def regions
            details[:region]
          end
          
          def region_count
            regions.length
          end
          
          def has_public_access_block?
            details[:public_access_block_configuration].any?
          end
          
          def cross_account_buckets?
            regions.any? { |region| region[:bucket_account_id] }
          end
          
          def bucket_names
            regions.map { |region| region[:bucket] }
          end
          
          def region_names
            regions.map { |region| region[:region] }
          end
        end
      end
    end
  end
end