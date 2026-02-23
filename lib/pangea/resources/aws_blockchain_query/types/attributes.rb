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
        # Type-safe attributes for AWS Blockchain Query resources
        class BlockchainQueryAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          # Query name (required)
          attribute? :query_name, Resources::Types::String.optional

          # Blockchain network (required)
          attribute? :blockchain_network, Resources::Types::String.constrained(included_in: ['ETHEREUM_MAINNET',
            'ETHEREUM_GOERLI_TESTNET',
            'BITCOIN_MAINNET',
            'BITCOIN_TESTNET',
            'POLYGON_MAINNET',
            'POLYGON_MUMBAI_TESTNET'])

          # Query string (required)
          attribute? :query_string, Resources::Types::String.optional

          # Output configuration (required)
          attribute? :output_configuration, Resources::Types::Hash.schema(
            s3_configuration: Resources::Types::Hash.schema(
              bucket_name: Resources::Types::String,
              key_prefix: Resources::Types::String,
              encryption_configuration?: Resources::Types::Hash.schema(
                encryption_option: Resources::Types::String.constrained(included_in: ['SSE_S3', 'SSE_KMS']),
                kms_key?: Resources::Types::String.optional
              ).lax.optional
            )
          )

          # Query parameters (optional)
          attribute? :parameters, Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional

          # Schedule configuration (optional)
          attribute? :schedule_configuration, Resources::Types::Hash.schema(
            schedule_expression: Resources::Types::String,
            timezone?: Resources::Types::String.optional
          ).lax.optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional
        end
      end
    end
  end
end
