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
    # AWS IoT Authorizer Types
    # 
    # Custom authorizers enable authentication and authorization using custom logic,
    # tokens, or third-party identity providers beyond X.509 certificates. This enables
    # flexible authentication patterns for diverse IoT use cases.
    module AwsIotAuthorizerTypes
      # Token key name configuration for custom tokens
      class TokenKeyName < Dry::Struct
        schema schema.strict

        # Name of the key to extract from the token
        attribute :key, Resources::Types::String
      end

      # Main attributes for IoT authorizer resource

      # Output attributes from authorizer resource
      unless const_defined?(:Outputs)
      class Outputs < Dry::Struct
        schema schema.strict

        # The authorizer ARN
        attribute :arn, Resources::Types::String

        # The authorizer name
        attribute :name, Resources::Types::String

        # The unique authorizer ID
        attribute :id, Resources::Types::String
      end
    end
      end
  end
end