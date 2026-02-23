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
      # Block builders for AWS CodeBuild Project resource
      # Extracts complex nested block building logic for cleaner resource definition
      module CodeBuildBlockBuilders
        extend self

        def apply_source(ctx, source_attrs)
          ctx.source do
            ctx.type source_attrs[:type]
            ctx.location source_attrs[:location] if source_attrs[:location]
            ctx.git_clone_depth source_attrs[:git_clone_depth] if source_attrs[:git_clone_depth]
            ctx.buildspec source_attrs[:buildspec] if source_attrs[:buildspec]
            ctx.report_build_status source_attrs[:report_build_status] if source_attrs.key?(:report_build_status)
            ctx.insecure_ssl source_attrs[:insecure_ssl] if source_attrs.key?(:insecure_ssl)

            if source_attrs[:git_submodules_config]
              ctx.git_submodules_config do
                ctx.fetch_submodules source_attrs[:git_submodules_config][:fetch_submodules]
              end
            end

            if source_attrs[:auth]
              ctx.auth do
                ctx.type source_attrs[:auth][:type]
                ctx.resource source_attrs[:auth][:resource] if source_attrs[:auth][:resource]
              end
            end
          end
        end

        def apply_secondary_sources(ctx, secondary_sources)
          secondary_sources.each do |src|
            ctx.secondary_sources do
              ctx.source_identifier src[:source_identifier]
              ctx.type src[:type]
              ctx.location src[:location] if src[:location]
              ctx.git_clone_depth src[:git_clone_depth] if src[:git_clone_depth]
              ctx.buildspec src[:buildspec] if src[:buildspec]
              ctx.report_build_status src[:report_build_status] if src.key?(:report_build_status)
              ctx.insecure_ssl src[:insecure_ssl] if src.key?(:insecure_ssl)
            end
          end
        end

        def apply_artifacts(ctx, artifacts_attrs)
          ctx.artifacts do
            ctx.type artifacts_attrs[:type]
            ctx.location artifacts_attrs[:location] if artifacts_attrs[:location]
            ctx.name artifacts_attrs[:name] if artifacts_attrs[:name]
            ctx.namespace_type artifacts_attrs[:namespace_type] if artifacts_attrs[:namespace_type]
            ctx.packaging artifacts_attrs[:packaging] if artifacts_attrs[:packaging]
            ctx.path artifacts_attrs[:path] if artifacts_attrs[:path]
            ctx.encryption_disabled artifacts_attrs[:encryption_disabled] if artifacts_attrs.key?(:encryption_disabled)
            ctx.artifact_identifier artifacts_attrs[:artifact_identifier] if artifacts_attrs[:artifact_identifier]
            ctx.override_artifact_name artifacts_attrs[:override_artifact_name] if artifacts_attrs.key?(:override_artifact_name)
          end
        end

        def apply_secondary_artifacts(ctx, secondary_artifacts)
          secondary_artifacts.each do |art|
            ctx.secondary_artifacts do
              ctx.artifact_identifier art[:artifact_identifier]
              ctx.type art[:type]
              ctx.location art[:location] if art[:location]
              ctx.name art[:name] if art[:name]
              ctx.namespace_type art[:namespace_type] if art[:namespace_type]
              ctx.packaging art[:packaging] if art[:packaging]
              ctx.path art[:path] if art[:path]
              ctx.encryption_disabled art[:encryption_disabled] if art.key?(:encryption_disabled)
              ctx.override_artifact_name art[:override_artifact_name] if art.key?(:override_artifact_name)
            end
          end
        end

        def apply_environment(ctx, env_attrs)
          ctx.environment do
            ctx.type env_attrs[:type]
            ctx.image env_attrs[:image]
            ctx.compute_type env_attrs[:compute_type]
            ctx.privileged_mode env_attrs[:privileged_mode] if env_attrs.key?(:privileged_mode)
            ctx.certificate env_attrs[:certificate] if env_attrs[:certificate]
            ctx.image_pull_credentials_type env_attrs[:image_pull_credentials_type] if env_attrs[:image_pull_credentials_type]

            env_attrs[:environment_variables]&.each do |env_var|
              ctx.environment_variable do
                ctx.name env_var[:name]
                ctx.value env_var[:value]
                ctx.type env_var[:type] if env_var[:type]
              end
            end

            if env_attrs[:registry_credential]
              ctx.registry_credential do
                ctx.credential env_attrs[:registry_credential][:credential]
                ctx.credential_provider env_attrs[:registry_credential][:credential_provider]
              end
            end
          end
        end

        def apply_logs_config(ctx, logs_config)
          return unless logs_config&.any?

          ctx.logs_config do
            if logs_config[:cloudwatch_logs]
              cw = logs_config[:cloudwatch_logs]
              ctx.cloudwatch_logs do
                ctx.status cw[:status] if cw[:status]
                ctx.group_name cw[:group_name] if cw[:group_name]
                ctx.stream_name cw[:stream_name] if cw[:stream_name]
              end
            end

            if logs_config[:s3_logs]
              s3 = logs_config[:s3_logs]
              ctx.s3_logs do
                ctx.status s3[:status] if s3[:status]
                ctx.location s3[:location] if s3[:location]
                ctx.encryption_disabled s3[:encryption_disabled] if s3.key?(:encryption_disabled)
              end
            end
          end
        end

        def apply_build_batch_config(ctx, batch_config)
          return unless batch_config

          ctx.build_batch_config do
            ctx.service_role batch_config[:service_role]
            ctx.combine_artifacts batch_config[:combine_artifacts] if batch_config.key?(:combine_artifacts)
            ctx.timeout_in_mins batch_config[:timeout_in_mins] if batch_config[:timeout_in_mins]

            if batch_config[:restrictions]
              ctx.restrictions do
                r = batch_config[:restrictions]
                ctx.compute_types_allowed r[:compute_types_allowed] if r[:compute_types_allowed]
                ctx.maximum_builds_allowed r[:maximum_builds_allowed] if r[:maximum_builds_allowed]
              end
            end
          end
        end
      end
    end
  end
end
