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
require 'pangea/resources/aws_ecs_task_definition/types'
require 'pangea/resources/aws_ecs_task_definition/container_definitions'
require 'pangea/resource_registry'
require 'json'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Task Definition with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS task definition attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_task_definition(name, attributes = {})
        task_attrs = Types::EcsTaskDefinitionAttributes.new(attributes)

        resource_attrs = {
          family: task_attrs.family,
          container_definitions: ::JSON.pretty_generate(
            EcsTaskDefinition::ContainerDefinitions.build(task_attrs.container_definitions)
          ),
          network_mode: task_attrs.network_mode,
          requires_compatibilities: task_attrs.requires_compatibilities
        }

        # Task roles
        resource_attrs[:task_role_arn] = task_attrs.task_role_arn if task_attrs.task_role_arn
        resource_attrs[:execution_role_arn] = task_attrs.execution_role_arn if task_attrs.execution_role_arn

        # Compute
        resource_attrs[:cpu] = task_attrs.cpu if task_attrs.cpu
        resource_attrs[:memory] = task_attrs.memory if task_attrs.memory

        # Volumes
        if task_attrs.volumes.any?
          resource_attrs[:volume] = task_attrs.volumes.map { |vol| build_volume(vol) }
        end

        # Placement constraints
        if task_attrs.placement_constraints.any?
          resource_attrs[:placement_constraints] = task_attrs.placement_constraints.map do |constraint|
            pc = { type: constraint[:type] }
            pc[:expression] = constraint[:expression] if constraint[:expression]
            pc
          end
        end

        # Process modes
        resource_attrs[:ipc_mode] = task_attrs.ipc_mode if task_attrs.ipc_mode
        resource_attrs[:pid_mode] = task_attrs.pid_mode if task_attrs.pid_mode

        # Inference accelerators
        if task_attrs.inference_accelerators.any?
          resource_attrs[:inference_accelerator] = task_attrs.inference_accelerators.map do |acc|
            { device_name: acc[:device_name], device_type: acc[:device_type] }
          end
        end

        # Proxy configuration
        if task_attrs.proxy_configuration
          proxy = {
            container_name: task_attrs.proxy_configuration[:container_name]
          }
          proxy[:type] = task_attrs.proxy_configuration[:type] if task_attrs.proxy_configuration[:type]
          if task_attrs.proxy_configuration[:properties]
            props = {}
            task_attrs.proxy_configuration[:properties].each do |prop|
              props[prop[:name]] = prop[:value]
            end
            proxy[:properties] = props
          end
          resource_attrs[:proxy_configuration] = proxy
        end

        # Runtime platform
        if task_attrs.runtime_platform
          rp = {}
          rp[:operating_system_family] = task_attrs.runtime_platform[:operating_system_family] if task_attrs.runtime_platform[:operating_system_family]
          rp[:cpu_architecture] = task_attrs.runtime_platform[:cpu_architecture] if task_attrs.runtime_platform[:cpu_architecture]
          resource_attrs[:runtime_platform] = rp
        end

        # Ephemeral storage
        if task_attrs.ephemeral_storage
          resource_attrs[:ephemeral_storage] = {
            size_in_gib: task_attrs.ephemeral_storage[:size_in_gib]
          }
        end

        # Tags
        resource_attrs[:tags] = task_attrs.tags if task_attrs.tags&.any?

        # Write to manifest
        if is_a?(AbstractSynthesizer)
          translation[:manifest][:resource] ||= {}
          translation[:manifest][:resource][:aws_ecs_task_definition] ||= {}
          translation[:manifest][:resource][:aws_ecs_task_definition][name] = resource_attrs
        else
          resource(:aws_ecs_task_definition, name, resource_attrs)
        end

        create_resource_reference(name, task_attrs)
      end

      private

      def build_volume(vol)
        v = { name: vol[:name] }

        if vol[:host]
          host = {}
          host[:source_path] = vol[:host][:source_path] if vol[:host][:source_path]
          v[:host] = host
        end

        if vol[:docker_volume_configuration]
          dvc = vol[:docker_volume_configuration]
          docker = {}
          docker[:scope] = dvc[:scope] if dvc[:scope]
          docker[:autoprovision] = dvc[:autoprovision] unless dvc[:autoprovision].nil?
          docker[:driver] = dvc[:driver] if dvc[:driver]
          docker[:driver_opts] = dvc[:driver_opts] if dvc[:driver_opts]
          docker[:labels] = dvc[:labels] if dvc[:labels]
          v[:docker_volume_configuration] = docker
        end

        if vol[:efs_volume_configuration]
          evc = vol[:efs_volume_configuration]
          efs = { file_system_id: evc[:file_system_id] }
          efs[:root_directory] = evc[:root_directory] if evc[:root_directory]
          efs[:transit_encryption] = evc[:transit_encryption] if evc[:transit_encryption]
          efs[:transit_encryption_port] = evc[:transit_encryption_port] if evc[:transit_encryption_port]
          if evc[:authorization_config]
            auth = {}
            auth[:access_point_id] = evc[:authorization_config][:access_point_id] if evc[:authorization_config][:access_point_id]
            auth[:iam] = evc[:authorization_config][:iam] if evc[:authorization_config][:iam]
            efs[:authorization_config] = auth
          end
          v[:efs_volume_configuration] = efs
        end

        if vol[:fsx_windows_file_server_volume_configuration]
          fsx = vol[:fsx_windows_file_server_volume_configuration]
          fsx_config = {
            file_system_id: fsx[:file_system_id],
            root_directory: fsx[:root_directory],
            authorization_config: {
              credentials_parameter: fsx[:authorization_config][:credentials_parameter],
              domain: fsx[:authorization_config][:domain]
            }
          }
          v[:fsx_windows_file_server_volume_configuration] = fsx_config
        end

        v
      end

      def create_resource_reference(name, task_attrs)
        ref = ResourceReference.new(
          type: 'aws_ecs_task_definition',
          name: name,
          resource_attributes: task_attrs.to_h,
          outputs: {
            arn: "${aws_ecs_task_definition.#{name}.arn}",
            arn_without_revision: "${aws_ecs_task_definition.#{name}.arn_without_revision}",
            family: "${aws_ecs_task_definition.#{name}.family}",
            revision: "${aws_ecs_task_definition.#{name}.revision}",
            tags_all: "${aws_ecs_task_definition.#{name}.tags_all}",
            id: "${aws_ecs_task_definition.#{name}.id}"
          }
        )

        add_computed_methods(ref, task_attrs)
        ref
      end

      def add_computed_methods(ref, task_attrs)
        ref.define_singleton_method(:fargate_compatible?) { task_attrs.fargate_compatible? }
        ref.define_singleton_method(:uses_efs?) { task_attrs.uses_efs? }
        ref.define_singleton_method(:total_memory_mb) { task_attrs.total_memory_mb }
        ref.define_singleton_method(:estimated_hourly_cost) { task_attrs.estimated_hourly_cost }
        ref.define_singleton_method(:main_container_name) { task_attrs.main_container.name }
        ref.define_singleton_method(:container_names) { task_attrs.container_definitions.map(&:name) }
        ref.define_singleton_method(:essential_container_count) { task_attrs.container_definitions.count(&:is_essential?) }
      end
    end
  end
end
