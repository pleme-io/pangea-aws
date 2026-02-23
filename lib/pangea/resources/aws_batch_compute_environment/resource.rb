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
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS Batch Compute Environment implementation
      # Provides type-safe function for creating compute environments
      def aws_batch_compute_environment(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::BatchComputeEnvironmentAttributes.new(attributes)

        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_batch_compute_environment',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_batch_compute_environment.#{name}.id}",
            arn: "${aws_batch_compute_environment.#{name}.arn}",
            name: "${aws_batch_compute_environment.#{name}.name}",
            ecs_cluster_arn: "${aws_batch_compute_environment.#{name}.ecs_cluster_arn}",
            status: "${aws_batch_compute_environment.#{name}.status}",
            status_reason: "${aws_batch_compute_environment.#{name}.status_reason}",
            tags_all: "${aws_batch_compute_environment.#{name}.tags_all}"
          }
        )

        # Build resource attributes hash
        resource_attrs = {
          compute_environment_name: validated_attrs.compute_environment_name,
          type: validated_attrs.type
        }

        resource_attrs[:state] = validated_attrs.state if validated_attrs.state
        resource_attrs[:service_role] = validated_attrs.service_role if validated_attrs.service_role

        # Compute resources for managed environments
        if validated_attrs.compute_resources
          cr = validated_attrs.compute_resources
          cr_attrs = { type: cr[:type] }

          cr_attrs[:allocation_strategy] = cr[:allocation_strategy] if cr[:allocation_strategy]
          cr_attrs[:min_vcpus] = cr[:min_vcpus] if cr[:min_vcpus]
          cr_attrs[:max_vcpus] = cr[:max_vcpus] if cr[:max_vcpus]
          cr_attrs[:desired_vcpus] = cr[:desired_vcpus] if cr[:desired_vcpus]
          cr_attrs[:instance_types] = cr[:instance_types] if cr[:instance_types]
          cr_attrs[:instance_role] = cr[:instance_role] if cr[:instance_role]
          cr_attrs[:spot_iam_fleet_request_role] = cr[:spot_iam_fleet_request_role] if cr[:spot_iam_fleet_request_role]
          cr_attrs[:bid_percentage] = cr[:bid_percentage] if cr[:bid_percentage]
          cr_attrs[:subnets] = cr[:subnets] if cr[:subnets]
          cr_attrs[:security_group_ids] = cr[:security_group_ids] if cr[:security_group_ids]
          cr_attrs[:platform_capabilities] = cr[:platform_capabilities] if cr[:platform_capabilities]
          cr_attrs[:ec2_key_pair] = cr[:ec2_key_pair] if cr[:ec2_key_pair]
          cr_attrs[:image_id] = cr[:image_id] if cr[:image_id]

          if cr[:launch_template]
            lt = {}
            lt[:launch_template_id] = cr[:launch_template][:launch_template_id] if cr[:launch_template][:launch_template_id]
            lt[:launch_template_name] = cr[:launch_template][:launch_template_name] if cr[:launch_template][:launch_template_name]
            lt[:version] = cr[:launch_template][:version] if cr[:launch_template][:version]
            cr_attrs[:launch_template] = lt
          end

          cr_attrs[:tags] = cr[:tags] if cr[:tags]

          resource_attrs[:compute_resources] = cr_attrs
        end

        resource_attrs[:tags] = validated_attrs.tags if validated_attrs.tags&.any?

        # Dual-path write
        if defined?(AbstractSynthesizer) && is_a?(AbstractSynthesizer)
          translation[:manifest][:resource] ||= {}
          translation[:manifest][:resource][:aws_batch_compute_environment] ||= {}
          translation[:manifest][:resource][:aws_batch_compute_environment][name] = resource_attrs
        else
          resource(:aws_batch_compute_environment, name, resource_attrs)
        end

        # Return the reference
        ref
      end
    end
  end
end
