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
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Lambda function attributes with validation
        class LambdaFunctionAttributes < Pangea::Resources::BaseAttributes
          include LambdaHelpers
          transform_keys(&:to_sym)

          attribute? :function_name, Pangea::Resources::Types::String.constrained(min_size: 1, max_size: 64, format: /\A[a-zA-Z0-9_-]+\z/).optional
          attribute? :role, Pangea::Resources::Types::String.optional
          attribute? :handler, Pangea::Resources::Types::String.optional
          attribute? :runtime, Pangea::Resources::Types::LambdaRuntime.optional
          attribute? :filename, Pangea::Resources::Types::String.optional
          attribute? :s3_bucket, Pangea::Resources::Types::String.optional
          attribute? :s3_key, Pangea::Resources::Types::String.optional
          attribute? :s3_object_version, Pangea::Resources::Types::String.optional
          attribute? :image_uri, Pangea::Resources::Types::String.optional
          attribute :description, Pangea::Resources::Types::String.optional.default(nil)
          attribute :timeout, Pangea::Resources::Types::LambdaTimeout.default(3)
          attribute :memory_size, Pangea::Resources::Types::LambdaMemory.default(128)
          attribute :publish, Pangea::Resources::Types::Bool.default(false)
          attribute? :reserved_concurrent_executions, Pangea::Resources::Types::LambdaReservedConcurrency.optional
          attribute :layers, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :architectures, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::LambdaArchitecture).default(['x86_64'].freeze)
          attribute :package_type, Pangea::Resources::Types::LambdaPackageType.default('Zip')
          attribute? :environment, Pangea::Resources::Types::Hash.schema(variables?: Pangea::Resources::Types::LambdaEnvironmentVariables.optional).lax.optional
          attribute? :vpc_config, Pangea::Resources::Types::LambdaVpcConfig.optional
          attribute? :dead_letter_config, Pangea::Resources::Types::LambdaDeadLetterConfig.optional
          attribute :file_system_config, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::LambdaFileSystemConfig).default([].freeze)
          attribute? :tracing_config, Pangea::Resources::Types::Hash.schema(mode: Pangea::Resources::Types::LambdaTracingMode).lax.optional
          attribute? :kms_key_arn, Pangea::Resources::Types::String.optional
          attribute? :image_config, Pangea::Resources::Types::LambdaImageConfig.optional
          attribute? :code_signing_config_arn, Pangea::Resources::Types::String.optional
          attribute? :ephemeral_storage, Pangea::Resources::Types::LambdaEphemeralStorage.optional
          attribute? :snap_start, Pangea::Resources::Types::LambdaSnapStart.optional
          attribute? :logging_config, Pangea::Resources::Types::Hash.schema(
            log_format?: Pangea::Resources::Types::String.constrained(included_in: %w[JSON Text]).optional,
            log_group?: Pangea::Resources::Types::String.optional,
            system_log_level?: Pangea::Resources::Types::String.constrained(included_in: %w[DEBUG INFO WARN]).optional,
            application_log_level?: Pangea::Resources::Types::String.constrained(included_in: %w[TRACE DEBUG INFO WARN ERROR FATAL]).optional
          ).lax.optional
          attribute? :tags, Pangea::Resources::Types::AwsTags.optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes.transform_keys(&:to_sym) : {}
            LambdaValidators.validate_package_type(attrs)
            LambdaValidators.validate_handler_format(attrs[:handler], attrs[:runtime]) if attrs[:handler] && attrs[:runtime]
            LambdaValidators.validate_snap_start(attrs)
            LambdaValidators.validate_architectures(attrs)

            # Validate tracing_config mode (bypasses .lax)
            if attrs[:tracing_config].is_a?(::Hash)
              mode = attrs[:tracing_config][:mode] || attrs[:tracing_config]['mode']
              if mode && !%w[Active PassThrough].include?(mode)
                raise Dry::Struct::Error, "Invalid tracing mode: #{mode}. Must be Active or PassThrough"
              end
            end

            # Validate logging_config log_format (bypasses .lax)
            if attrs[:logging_config].is_a?(::Hash)
              log_format = attrs[:logging_config][:log_format] || attrs[:logging_config]['log_format']
              if log_format && !%w[JSON Text].include?(log_format)
                raise Dry::Struct::Error, "Invalid log_format: #{log_format}. Must be JSON or Text"
              end
            end

            # Validate environment variable names (bypasses .lax)
            if attrs[:environment].is_a?(::Hash)
              variables = attrs[:environment][:variables] || attrs[:environment]['variables']
              if variables.is_a?(::Hash)
                variables.each_key do |key|
                  unless key.to_s.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
                    raise Dry::Struct::Error, "Invalid environment variable name: #{key}. Must start with a letter or underscore"
                  end
                end
              end
            end

            # Validate ephemeral_storage size (bypasses .lax)
            if attrs[:ephemeral_storage].is_a?(::Hash)
              size = attrs[:ephemeral_storage][:size] || attrs[:ephemeral_storage]['size']
              if size && (size < 512 || size > 10240)
                raise Dry::Struct::Error, "Ephemeral storage size must be between 512 and 10240 MB"
              end
            end

            # Validate dead_letter_config target_arn (bypasses .lax)
            if attrs[:dead_letter_config].is_a?(::Hash)
              target_arn = attrs[:dead_letter_config][:target_arn] || attrs[:dead_letter_config]['target_arn']
              if target_arn && !target_arn.match?(/\Aarn:aws:(sqs|sns):/)
                raise Dry::Struct::Error, "Dead letter target ARN must be a valid SQS or SNS ARN"
              end
            end

            # Validate file_system_config mount paths (bypasses .lax)
            if attrs[:file_system_config].is_a?(::Array)
              attrs[:file_system_config].each do |config|
                next unless config.is_a?(::Hash)
                mount_path = config[:local_mount_path] || config['local_mount_path']
                if mount_path && !mount_path.match?(/\A\/mnt\/[a-zA-Z0-9_-]+\z/)
                  raise Dry::Struct::Error, "File system local_mount_path must start with /mnt/ followed by alphanumeric characters"
                end
              end
            end

            super(attrs)
          end
        end
      end
    end
  end
end
