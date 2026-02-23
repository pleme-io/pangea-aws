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
require 'pangea/resources/aws_ecs_service/types'
require 'pangea/resources/aws_ecs_service/dsl_builders'
require 'pangea/resources/aws_ecs_service/reference_builder'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Service with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS service attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_service(name, attributes = {})
        # Validate attributes using dry-struct
        service_attrs = Types::EcsServiceAttributes.new(attributes)

        # Build resource attributes as a hash
        resource_attrs = {
          name: service_attrs.name,
          cluster: service_attrs.cluster,
          task_definition: service_attrs.task_definition
        }

        # Scheduling
        resource_attrs[:desired_count] = service_attrs.desired_count unless service_attrs.scheduling_strategy == "DAEMON"
        resource_attrs[:scheduling_strategy] = service_attrs.scheduling_strategy if service_attrs.scheduling_strategy != "REPLICA"

        # Launch config
        if service_attrs.launch_type
          resource_attrs[:launch_type] = service_attrs.launch_type
          resource_attrs[:platform_version] = service_attrs.platform_version if service_attrs.launch_type == "FARGATE"
        end

        # Capacity provider strategy
        if service_attrs.capacity_provider_strategy.any?
          resource_attrs[:capacity_provider_strategy] = service_attrs.capacity_provider_strategy.map { |s|
            { capacity_provider: s.capacity_provider, weight: s.weight, base: s.base }
          }
        end

        # Load balancers
        if service_attrs.load_balancer.any?
          resource_attrs[:load_balancer] = service_attrs.load_balancer.map { |lb|
            { target_group_arn: lb.target_group_arn, container_name: lb.container_name, container_port: lb.container_port }
          }
        end

        # Network configuration
        if service_attrs.network_configuration
          nc = service_attrs.network_configuration
          net_hash = { subnets: nc.subnets, assign_public_ip: nc.assign_public_ip }
          net_hash[:security_groups] = nc.security_groups if nc.security_groups
          resource_attrs[:network_configuration] = net_hash
        end

        # Service registries
        if service_attrs.service_registries.any?
          resource_attrs[:service_registries] = service_attrs.service_registries.map { |reg|
            rh = { registry_arn: reg.registry_arn }
            rh[:port] = reg.port if reg.port
            rh[:container_port] = reg.container_port if reg.container_port
            rh[:container_name] = reg.container_name if reg.container_name
            rh
          }
        end

        # Deployment configuration
        resource_attrs[:deployment_configuration] = {
          deployment_circuit_breaker: {
            enable: service_attrs.deployment_configuration.deployment_circuit_breaker[:enable],
            rollback: service_attrs.deployment_configuration.deployment_circuit_breaker[:rollback]
          },
          maximum_percent: service_attrs.deployment_configuration.maximum_percent,
          minimum_healthy_percent: service_attrs.deployment_configuration.minimum_healthy_percent
        }

        resource_attrs[:deployment_controller] = service_attrs.deployment_controller

        # Placement constraints
        if service_attrs.placement_constraints.any?
          resource_attrs[:placement_constraints] = service_attrs.placement_constraints.map { |pc|
            ph = { type: pc.type }
            ph[:expression] = pc.expression if pc.expression
            ph
          }
        end

        # Placement strategy
        if service_attrs.placement_strategy.any?
          resource_attrs[:placement_strategy] = service_attrs.placement_strategy.map { |ps|
            ph = { type: ps.type }
            ph[:field] = ps.field if ps.field
            ph
          }
        end

        # Additional config
        resource_attrs[:health_check_grace_period_seconds] = service_attrs.health_check_grace_period_seconds if service_attrs.health_check_grace_period_seconds
        resource_attrs[:enable_ecs_managed_tags] = service_attrs.enable_ecs_managed_tags
        resource_attrs[:enable_execute_command] = service_attrs.enable_execute_command
        resource_attrs[:propagate_tags] = service_attrs.propagate_tags if service_attrs.propagate_tags != "NONE"

        # Service Connect configuration
        if service_attrs.service_connect_configuration
          sc = service_attrs.service_connect_configuration
          sc_hash = { enabled: sc[:enabled] }
          sc_hash[:namespace] = sc[:namespace] if sc[:namespace]

          if sc[:services]&.any?
            sc_hash[:service] = sc[:services].map { |svc|
              sh = { port_name: svc[:port_name] }
              sh[:discovery_name] = svc[:discovery_name] if svc[:discovery_name]
              sh[:ingress_port_override] = svc[:ingress_port_override] if svc[:ingress_port_override]

              if svc[:client_aliases]&.any?
                sh[:client_alias] = svc[:client_aliases].map { |ca|
                  cah = { port: ca[:port] }
                  cah[:dns_name] = ca[:dns_name] if ca[:dns_name]
                  cah
                }
              end

              if svc[:timeout]
                th = {}
                th[:idle_timeout_seconds] = svc[:timeout][:idle_timeout_seconds] if svc[:timeout][:idle_timeout_seconds]
                th[:per_request_timeout_seconds] = svc[:timeout][:per_request_timeout_seconds] if svc[:timeout][:per_request_timeout_seconds]
                sh[:timeout] = th
              end

              if svc[:tls]
                tlsh = {}
                if svc[:tls][:issuer_certificate_authority]
                  tlsh[:issuer_certificate_authority] = { aws_pca_authority_arn: svc[:tls][:issuer_certificate_authority][:aws_pca_authority_arn] }
                end
                tlsh[:kms_key] = svc[:tls][:kms_key] if svc[:tls][:kms_key]
                tlsh[:role_arn] = svc[:tls][:role_arn] if svc[:tls][:role_arn]
                sh[:tls] = tlsh
              end

              sh
            }
          end

          if sc[:log_configuration]
            lc = sc[:log_configuration]
            lch = { log_driver: lc[:log_driver] }
            lch[:options] = lc[:options] if lc[:options]
            if lc[:secret_options]&.any?
              lch[:secret_option] = lc[:secret_options].map { |s| { name: s[:name], value_from: s[:value_from] } }
            end
            sc_hash[:log_configuration] = lch
          end

          resource_attrs[:service_connect_configuration] = sc_hash
        end

        # Lifecycle config
        resource_attrs[:wait_for_steady_state] = service_attrs.wait_for_steady_state
        resource_attrs[:force_new_deployment] = service_attrs.force_new_deployment

        # Tags
        resource_attrs[:tags] = service_attrs.tags if service_attrs.tags.any?

        # Write to manifest: direct access for synthesizer, fall back to resource() for test mocks
        if is_a?(AbstractSynthesizer)
          translation[:manifest][:resource] ||= {}
          translation[:manifest][:resource][:aws_ecs_service] ||= {}
          translation[:manifest][:resource][:aws_ecs_service][name] = resource_attrs
        else
          resource(:aws_ecs_service, name, resource_attrs)
        end

        EcsServiceReferenceBuilder.build(name, service_attrs)
      end
    end
  end
end
