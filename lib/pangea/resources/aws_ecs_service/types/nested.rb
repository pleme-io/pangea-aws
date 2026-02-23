# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        class EcsLoadBalancer < Pangea::Resources::BaseAttributes
          attribute? :target_group_arn, Pangea::Resources::Types::String.optional
          attribute? :container_name, Pangea::Resources::Types::String.optional
          attribute? :container_port, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Invalid target group ARN format" unless attrs.target_group_arn.match?(/^arn:aws/)
            attrs
          end
        end

        class EcsNetworkConfiguration < Pangea::Resources::BaseAttributes
          attribute? :subnets, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).constrained(min_size: 1).optional
          attribute? :security_groups, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
          attribute :assign_public_ip, Pangea::Resources::Types::Bool.default(false)
        end

        class EcsServiceRegistries < Pangea::Resources::BaseAttributes
          attribute? :registry_arn, Pangea::Resources::Types::String.optional
          attribute? :port, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional
          attribute? :container_port, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional
          attribute? :container_name, Pangea::Resources::Types::String.optional
        end

        class EcsDeploymentConfiguration < Pangea::Resources::BaseAttributes
          attribute? :deployment_circuit_breaker, Pangea::Resources::Types::Hash.schema(
            enable: Pangea::Resources::Types::Bool, rollback: Pangea::Resources::Types::Bool
          ).lax.default({ enable: false, rollback: false })
          attribute :maximum_percent, Pangea::Resources::Types::Integer.constrained(gteq: 100).default(200)
          attribute :minimum_healthy_percent, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).default(100)
        end

        class EcsPlacementConstraint < Pangea::Resources::BaseAttributes
          attribute? :type, Pangea::Resources::Types::String.constrained(included_in: ["distinctInstance", "memberOf"]).optional
          attribute? :expression, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Expression is required for memberOf constraint type" if attrs.type == "memberOf" && attrs.expression.nil?
            attrs
          end
        end

        class EcsPlacementStrategy < Pangea::Resources::BaseAttributes
          attribute? :type, Pangea::Resources::Types::String.constrained(included_in: ["random", "spread", "binpack"]).optional
          attribute? :field, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Field is required for #{attrs.type} strategy" if attrs.type != "random" && attrs.field.nil?
            attrs
          end
        end

        unless const_defined?(:EcsCapacityProviderStrategy)
        class EcsCapacityProviderStrategy < Pangea::Resources::BaseAttributes
          attribute? :capacity_provider, Pangea::Resources::Types::String.optional
          attribute :weight, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 1000).default(1)
          attribute :base, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100000).default(0)
        end
        end
      end
    end
  end
end
