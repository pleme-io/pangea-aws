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
        # AppSync resolver kind
        unless const_defined?(:AppSyncResolverKind)
        AppSyncResolverKind = Resources::Types::String.constrained(included_in: ['UNIT', 'PIPELINE'])
        end

        # AppSync runtime configuration
        unless const_defined?(:AppSyncRuntime)
        AppSyncRuntime = Resources::Types::Hash.schema(
          name: Resources::Types::String.constrained(included_in: ['APPSYNC_JS']),
          runtime_version: Resources::Types::String.constrained(format: /\A\d+\.\d+\.\d+\z/)
        ).lax
        end

        # AppSync pipeline config
        AppSyncPipelineConfig = Resources::Types::Hash.schema(
          functions: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)
        ).lax

        # AppSync caching config
        AppSyncCachingConfig = Resources::Types::Hash.schema(
          caching_keys?: Resources::Types::Array.of(Resources::Types::String).optional,
          ttl?: Resources::Types::Integer.constrained(gteq: 1, lteq: 3600).optional
        ).lax

        # AppSync sync config for subscriptions
        AppSyncSyncConfig = Resources::Types::Hash.schema(
          conflict_detection?: Resources::Types::String.constrained(included_in: ['VERSION', 'NONE']).optional,
          conflict_handler?: Resources::Types::String.constrained(included_in: ['OPTIMISTIC_CONCURRENCY', 'LAMBDA', 'AUTOMERGE', 'NONE']).optional,
          lambda_conflict_handler_config?: Resources::Types::Hash.schema(
            lambda_conflict_handler_arn?: Resources::Types::String.constrained(format: /\Aarn:aws:lambda:/).optional
          ).lax.optional
        )

        # AppSync Resolver resource attributes
        class AppSyncResolverAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          attribute? :api_id, Resources::Types::String.optional
          
          attribute? :type, Resources::Types::String.constrained(
            format: /\A[A-Z][a-zA-Z0-9_]*\z/,
            size: 1..65
          )
          
          attribute? :field, Resources::Types::String.constrained(
            format: /\A[a-zA-Z][a-zA-Z0-9_]*\z/,
            size: 1..65
          )
          
          attribute? :code, Resources::Types::String.optional
          
          attribute? :data_source, Resources::Types::String.optional
          
          attribute? :kind, AppSyncResolverKind.default('UNIT')
          
          attribute? :max_batch_size, Resources::Types::Integer.constrained(
            gteq: 1, lteq: 2000
          ).optional
          
          attribute? :pipeline_config, AppSyncPipelineConfig.optional
          
          attribute? :request_template, Resources::Types::String.optional
          
          attribute? :response_template, Resources::Types::String.optional
          
          attribute? :runtime, AppSyncRuntime.optional
          
          attribute? :caching_config, AppSyncCachingConfig.optional
          
          attribute? :sync_config, AppSyncSyncConfig.optional

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}

            # Validate resolver configuration based on kind
            if attrs[:kind] == 'PIPELINE'
              unless attrs[:pipeline_config]
                raise Dry::Struct::Error, "pipeline_config is required when kind is PIPELINE"
              end
              if attrs[:data_source]
                raise Dry::Struct::Error, "data_source should not be specified for PIPELINE resolvers"
              end
            else # UNIT resolver
              unless attrs[:data_source]
                raise Dry::Struct::Error, "data_source is required for UNIT resolvers"
              end
              if attrs[:pipeline_config]
                raise Dry::Struct::Error, "pipeline_config should not be specified for UNIT resolvers"
              end
            end

            # Validate runtime and template configuration
            if attrs[:runtime] && (attrs[:request_template] || attrs[:response_template])
              raise Dry::Struct::Error, "runtime and templates (request_template/response_template) are mutually exclusive"
            end

            if attrs[:runtime] && !attrs[:code]
              raise Dry::Struct::Error, "code is required when using runtime"
            end

            # Validate conflict handler configuration
            if attrs[:sync_config] && attrs[:sync_config][:conflict_handler] == 'LAMBDA'
              unless attrs[:sync_config][:lambda_conflict_handler_config]
                raise Dry::Struct::Error, "lambda_conflict_handler_config is required when conflict_handler is LAMBDA"
              end
            end

            super(attrs)
          end
        end
      end
    end
  end
end