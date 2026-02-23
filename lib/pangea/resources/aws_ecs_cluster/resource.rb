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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ecs_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        cluster_attrs = Types::EcsClusterAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecs_cluster, name) do
          # Cluster name
          name cluster_attrs.name

          # Capacity providers
          capacity_providers cluster_attrs.capacity_providers if cluster_attrs.capacity_providers&.any?

          # Build settings array (pass as array of hashes, not repeated blocks)
          settings_array = cluster_attrs.setting.map { |s| { name: s[:name], value: s[:value] } }

          # Container Insights shorthand
          if !cluster_attrs.container_insights_enabled.nil? && cluster_attrs.setting.none? { |s| s[:name] == "containerInsights" }
            settings_array << {
              name: "containerInsights",
              value: cluster_attrs.container_insights_enabled ? "enabled" : "disabled"
            }
          end

          setting settings_array if settings_array.any?

          # Execute command configuration (pass as nested hash, not nested blocks)
          if cluster_attrs.configuration
            exec_cmd = cluster_attrs.configuration[:execute_command_configuration]
            if exec_cmd
              exec_hash = {}
              exec_hash[:kms_key_id] = exec_cmd[:kms_key_id] if exec_cmd[:kms_key_id]
              exec_hash[:logging] = exec_cmd[:logging] if exec_cmd[:logging]

              if exec_cmd[:log_configuration]
                log_cfg = exec_cmd[:log_configuration]
                log_hash = {}
                log_hash[:cloud_watch_encryption_enabled] = log_cfg[:cloud_watch_encryption_enabled] unless log_cfg[:cloud_watch_encryption_enabled].nil?
                log_hash[:cloud_watch_log_group_name] = log_cfg[:cloud_watch_log_group_name] if log_cfg[:cloud_watch_log_group_name]
                log_hash[:s3_bucket_name] = log_cfg[:s3_bucket_name] if log_cfg[:s3_bucket_name]
                log_hash[:s3_bucket_encryption_enabled] = log_cfg[:s3_bucket_encryption_enabled] unless log_cfg[:s3_bucket_encryption_enabled].nil?
                log_hash[:s3_key_prefix] = log_cfg[:s3_key_prefix] if log_cfg[:s3_key_prefix]
                exec_hash[:log_configuration] = log_hash
              end

              configuration({ execute_command_configuration: exec_hash })
            end
          end

          # Service Connect defaults (pass as hash, not block)
          if cluster_attrs.service_connect_defaults
            service_connect_defaults({ namespace: cluster_attrs.service_connect_defaults[:namespace] })
          end

          # Apply tags if present (pass as hash, not block)
          tags cluster_attrs.tags if cluster_attrs.tags&.any?
        end

        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_ecs_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: {
            id: "${aws_ecs_cluster.#{name}.id}",
            arn: "${aws_ecs_cluster.#{name}.arn}",
            name: "${aws_ecs_cluster.#{name}.name}",
            capacity_providers: "${aws_ecs_cluster.#{name}.capacity_providers}",
            tags_all: "${aws_ecs_cluster.#{name}.tags_all}",
            setting: "${aws_ecs_cluster.#{name}.setting}",
            configuration: "${aws_ecs_cluster.#{name}.configuration}",
            service_connect_defaults: "${aws_ecs_cluster.#{name}.service_connect_defaults}"
          }
        )

        # Add computed properties via method delegation
        ref.define_singleton_method(:using_fargate?) { cluster_attrs.using_fargate? }
        ref.define_singleton_method(:using_ec2?) { cluster_attrs.using_ec2? }
        ref.define_singleton_method(:insights_enabled?) { cluster_attrs.insights_enabled? }
        ref.define_singleton_method(:estimated_monthly_cost) { cluster_attrs.estimated_monthly_cost }
        ref.define_singleton_method(:arn_pattern) { |region = "*", account_id = "*"| cluster_attrs.arn_pattern(region, account_id) }

        ref
      end
    end
  end
end
