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
      module LambdaFunctionUrl
        # Common types for Lambda Function URL configurations
        module Types
          # Lambda Function Name constraint
          FunctionName = Resources::Types::String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z0-9\-_]+\z/
          )
          
          # Authorization type for function URL
          AuthorizationType = Resources::Types::String.constrained(included_in: ['AWS_IAM', 'NONE'])
          
          # HTTP method
          HttpMethod = Resources::Types::String.constrained(included_in: ['*', 'GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH'])
          
          # Origin for CORS
          Origin = Resources::Types::String.constrained(format: /\A\*|https?:\/\/.+\z/)
          
          # CORS Configuration
          CorsConfiguration = Resources::Types::Hash.schema({
            allow_credentials?: Resources::Types::Bool.optional,
            allow_headers?: Resources::Types::Array.of(Resources::Types::String).optional,
            allow_methods?: Resources::Types::Array.of(Resources::Types::HttpMethod).optional,
            allow_origins?: Resources::Types::Array.of(Origin).optional,
            expose_headers?: Resources::Types::Array.of(Resources::Types::String).optional,
            max_age?: Resources::Types::Integer.constrained(gteq: 0, lteq: 86400).optional
          }).lax
        end

        # Lambda Function URL attributes with comprehensive validation
        class LambdaFunctionUrlAttributes < Pangea::Resources::BaseAttributes
          # Required attributes
          attribute? :authorization_type, Types::AuthorizationType.optional
          attribute? :function_name, Types::FunctionName.optional
          
          # Optional attributes
          attribute? :cors, Types::CorsConfiguration.optional
          attribute? :qualifier, Resources::Types::String.optional
          attribute? :invoke_mode, Resources::Types::String.constrained(included_in: ['BUFFERED', 'RESPONSE_STREAM']).optional
          
          # Computed properties
          def has_cors_configuration?
            !cors.nil?
          end
          
          def allows_credentials?
            cors && cors&.dig(:allow_credentials) == true
          end
          
          def public_access?
            authorization_type == 'NONE'
          end
          
          def iam_protected?
            authorization_type == 'AWS_IAM'
          end
          
          def has_qualifier?
            !qualifier.nil?
          end
          
          def streaming_enabled?
            invoke_mode == 'RESPONSE_STREAM'
          end
          
          def cors_methods
            cors&.dig(:allow_methods) || []
          end
          
          def cors_origins
            cors&.dig(:allow_origins) || []
          end
        end
      end
    end
  end
end