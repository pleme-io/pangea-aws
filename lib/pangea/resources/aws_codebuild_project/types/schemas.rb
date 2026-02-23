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
        class CodeBuildProjectAttributes
          # Schema definitions for CodeBuild Project nested types
          module Schemas
            T = Resources::Types

            # Source configuration schema
            SOURCE = T::Hash.schema(
              type: T::String.constrained(included_in: ['CODECOMMIT', 'CODEPIPELINE', 'GITHUB', 'GITHUB_ENTERPRISE', 'BITBUCKET', 'S3', 'NO_SOURCE']),
              location?: T::String.optional,
              git_clone_depth?: T::Integer.constrained(gteq: 0).optional,
              buildspec?: T::String.optional,
              report_build_status?: T::Bool.optional,
              insecure_ssl?: T::Bool.optional,
              git_submodules_config?: T::Hash.schema(
                fetch_submodules: T::Bool
              ).lax.optional,
              auth?: T::Hash.schema(
                type: T::String.constrained(included_in: ['OAUTH']),
                resource?: T::String.optional
              ).lax.optional
            )

            # Artifacts configuration schema
            ARTIFACTS = T::Hash.schema(
              type: T::String.constrained(included_in: ['CODEPIPELINE', 'S3', 'NO_ARTIFACTS']),
              location?: T::String.optional,
              name?: T::String.optional,
              namespace_type?: T::String.constrained(included_in: ['NONE', 'BUILD_ID']).optional,
              packaging?: T::String.constrained(included_in: ['NONE', 'ZIP']).optional,
              path?: T::String.optional,
              encryption_disabled?: T::Bool.optional,
              artifact_identifier?: T::String.optional,
              override_artifact_name?: T::Bool.optional
            ).lax

            # Secondary source schema
            SECONDARY_SOURCE = T::Hash.schema(
              source_identifier: T::String,
              type: T::String.constrained(included_in: ['CODECOMMIT', 'CODEPIPELINE', 'GITHUB', 'S3']),
              location?: T::String.optional,
              git_clone_depth?: T::Integer.optional,
              buildspec?: T::String.optional,
              report_build_status?: T::Bool.optional,
              insecure_ssl?: T::Bool.optional
            ).lax

            # Secondary artifact schema
            SECONDARY_ARTIFACT = T::Hash.schema(
              artifact_identifier: T::String,
              type: T::String.constrained(included_in: ['S3']),
              location?: T::String.optional,
              name?: T::String.optional,
              namespace_type?: T::String.constrained(included_in: ['NONE', 'BUILD_ID']).optional,
              packaging?: T::String.constrained(included_in: ['NONE', 'ZIP']).optional,
              path?: T::String.optional,
              encryption_disabled?: T::Bool.optional,
              override_artifact_name?: T::Bool.optional
            ).lax

            # Environment configuration schema
            ENVIRONMENT = T::Hash.schema(
              type: T::String.constrained(included_in: ['LINUX_CONTAINER', 'LINUX_GPU_CONTAINER', 'WINDOWS_CONTAINER', 'WINDOWS_SERVER_2019_CONTAINER', 'ARM_CONTAINER']),
              image: T::String,
              compute_type: T::String.constrained(included_in: ['BUILD_GENERAL1_SMALL', 'BUILD_GENERAL1_MEDIUM', 'BUILD_GENERAL1_LARGE', 'BUILD_GENERAL1_2XLARGE']),
              environment_variables?: T::Array.of(
                T::Hash.schema(
                  name: T::String,
                  value: T::String,
                  type?: T::String.constrained(included_in: ['PLAINTEXT', 'PARAMETER_STORE', 'SECRETS_MANAGER']).optional
                ).lax
              ).optional,
              privileged_mode?: T::Bool.optional,
              certificate?: T::String.optional,
              registry_credential?: T::Hash.schema(
                credential: T::String,
                credential_provider: T::String.constrained(included_in: ['SECRETS_MANAGER'])
              ).lax.optional,
              image_pull_credentials_type?: T::String.constrained(included_in: ['CODEBUILD', 'SERVICE_ROLE']).optional
            )

            # Cache configuration schema
            CACHE = T::Hash.schema(
              type: T::String.constrained(included_in: ['NO_CACHE', 'S3', 'LOCAL']),
              location?: T::String.optional,
              modes?: T::Array.of(
                T::String.constrained(included_in: ['LOCAL_DOCKER_LAYER_CACHE', 'LOCAL_SOURCE_CACHE', 'LOCAL_CUSTOM_CACHE'])
              ).optional
            ).lax

            # VPC configuration schema
            VPC_CONFIG = T::Hash.schema(
              vpc_id: T::String,
              subnets: T::Array.of(T::String).constrained(min_size: 1),
              security_group_ids: T::Array.of(T::String).constrained(min_size: 1)
            ).lax

            # Logs configuration schema
            LOGS_CONFIG = T::Hash.schema(
              cloudwatch_logs?: T::Hash.schema(
                status?: T::String.constrained(included_in: ['ENABLED', 'DISABLED']).optional,
                group_name?: T::String.optional,
                stream_name?: T::String.optional
              ).lax.optional,
              s3_logs?: T::Hash.schema(
                status?: T::String.constrained(included_in: ['ENABLED', 'DISABLED']).optional,
                location?: T::String.optional,
                encryption_disabled?: T::Bool.optional
              ).lax.optional
            )

            # Build batch configuration schema
            BUILD_BATCH_CONFIG = T::Hash.schema(
              service_role: T::String,
              combine_artifacts?: T::Bool.optional,
              restrictions?: T::Hash.schema(
                compute_types_allowed?: T::Array.of(T::String).optional,
                maximum_builds_allowed?: T::Integer.optional
              ).lax.optional,
              timeout_in_mins?: T::Integer.optional
            )

            # File system location schema
            FILE_SYSTEM_LOCATION = T::Hash.schema(
              type: T::String.constrained(included_in: ['EFS']),
              location: T::String,
              mount_point: T::String,
              identifier: T::String,
              mount_options?: T::String.optional
            ).lax
          end
        end
      end
    end
  end
end
