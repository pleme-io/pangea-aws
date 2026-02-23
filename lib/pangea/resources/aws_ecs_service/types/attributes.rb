# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        class EcsServiceAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          attribute? :name, Pangea::Resources::Types::String.optional
          attribute? :cluster, Pangea::Resources::Types::String.optional
          attribute? :task_definition, Pangea::Resources::Types::String.optional
          attribute :desired_count, Pangea::Resources::Types::Integer.constrained(gteq: 0).default(1)
          attribute :scheduling_strategy, Pangea::Resources::Types::String.constrained(included_in: ["REPLICA", "DAEMON"]).default("REPLICA")
          attribute? :launch_type, Pangea::Resources::Types::String.constrained(included_in: ["EC2", "FARGATE", "EXTERNAL"]).optional
          attribute :capacity_provider_strategy, Pangea::Resources::Types::Array.of(EcsCapacityProviderStrategy).default([].freeze)
          attribute :platform_version, Pangea::Resources::Types::String.default("LATEST")
          attribute :load_balancer, Pangea::Resources::Types::Array.of(EcsLoadBalancer).default([].freeze)
          attribute? :network_configuration, EcsNetworkConfiguration.optional
          attribute :service_registries, Pangea::Resources::Types::Array.of(EcsServiceRegistries).default([].freeze)
          attribute :deployment_configuration, EcsDeploymentConfiguration.default(EcsDeploymentConfiguration.new)
          attribute :placement_constraints, Pangea::Resources::Types::Array.of(EcsPlacementConstraint).default([].freeze)
          attribute :placement_strategy, Pangea::Resources::Types::Array.of(EcsPlacementStrategy).default([].freeze)
          attribute? :health_check_grace_period_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 0).optional
          attribute :enable_ecs_managed_tags, Pangea::Resources::Types::Bool.default(true)
          attribute :enable_execute_command, Pangea::Resources::Types::Bool.default(false)
          attribute :propagate_tags, Pangea::Resources::Types::String.constrained(included_in: ["TASK_DEFINITION", "SERVICE", "NONE"]).default("NONE")
          attribute :deployment_controller, Pangea::Resources::Types::Hash.schema(type: Pangea::Resources::Types::String.constrained(included_in: ["ECS", "CODE_DEPLOY", "EXTERNAL"]).lax).default({ type: "ECS" })
          attribute? :service_connect_configuration, Pangea::Resources::Types::Hash.optional
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)
          attribute :wait_for_steady_state, Pangea::Resources::Types::Bool.default(false)
          attribute :force_new_deployment, Pangea::Resources::Types::Bool.default(false)

          def self.new(attributes = {})
            raw_attrs = attributes.is_a?(::Hash) ? attributes : {}
            attrs = super(attributes)
            raise Dry::Struct::Error, "Invalid task definition format" unless attrs.task_definition.match?(/\A(arn:aws:ecs:.+|[\w-]+:\d+)\z/)
            if attrs.scheduling_strategy == "DAEMON"
              # Only reject if desired_count was explicitly provided and is non-zero
              dc_explicitly_set = raw_attrs.key?(:desired_count) || raw_attrs.key?('desired_count')
              if dc_explicitly_set && attrs.desired_count != 0
                raise Dry::Struct::Error, "desired_count must be 0 or omitted for DAEMON scheduling"
              end
              raise Dry::Struct::Error, "placement_strategy cannot be used with DAEMON scheduling" if attrs.placement_strategy.any?
            end
            raise Dry::Struct::Error, "Cannot specify both launch_type and capacity_provider_strategy" if attrs.launch_type && attrs.capacity_provider_strategy.any?
            raise Dry::Struct::Error, "health_check_grace_period_seconds requires load_balancer configuration" if attrs.health_check_grace_period_seconds && attrs.load_balancer.empty?
            if attrs.service_connect_configuration&.dig(:enabled) && attrs.service_connect_configuration&.dig(:services).to_a.empty?
              raise Dry::Struct::Error, "Service Connect requires at least one service configuration"
            end
            attrs
          end
        end
      end
    end
  end
end
