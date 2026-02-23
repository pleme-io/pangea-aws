# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'validation'
require_relative 'instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Route53 Record resources
        class Route53RecordAttributes < Pangea::Resources::BaseAttributes
          include Route53RecordValidation
          include Route53RecordInstanceMethods

          transform_keys(&:to_sym)
          # Hosted zone ID where the record will be created
          attribute? :zone_id, Pangea::Resources::Types::String.optional

          # DNS record name (FQDN)
          attribute? :name, Pangea::Resources::Types::String.optional

          # DNS record type
          attribute? :type, Pangea::Resources::Types::String.constrained(included_in: ["A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"]).optional

          # Time To Live (TTL) in seconds (required for simple records)
          attribute :ttl?, Pangea::Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 2147483647)

          # DNS record values (for simple records)
          attribute :records?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional.default(proc { [] }.freeze)

          # Set identifier for weighted/latency-based/failover/geolocation routing
          attribute :set_identifier?, Pangea::Resources::Types::String.optional

          # Health check ID for failover routing
          attribute :health_check_id?, Pangea::Resources::Types::String.optional

          # Multivalue answer routing
          attribute :multivalue_answer?, Pangea::Resources::Types::Bool.optional.default(false)

          # Allow DNS record overwrite
          attribute :allow_overwrite?, Pangea::Resources::Types::Bool.optional.default(false)

          # Weighted routing policy
          attribute :weighted_routing_policy?, Pangea::Resources::Types::Hash.schema(
            weight: Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 255)
          ).lax.optional

          # Latency routing policy
          attribute :latency_routing_policy?, Pangea::Resources::Types::Hash.schema(
            region: Pangea::Resources::Types::String
          ).lax.optional

          # Failover routing policy
          attribute :failover_routing_policy?, Pangea::Resources::Types::Hash.schema(
            type: Pangea::Resources::Types::String.constrained(included_in: ["PRIMARY", "SECONDARY"])
          ).lax.optional

          # Geolocation routing policy
          attribute :geolocation_routing_policy?, Pangea::Resources::Types::Hash.schema(
            continent?: Pangea::Resources::Types::String.optional,
            country?: Pangea::Resources::Types::String.optional,
            subdivision?: Pangea::Resources::Types::String.optional
          ).lax.optional

          # Geoproximity routing policy (requires Route53 Traffic Flow)
          attribute :geoproximity_routing_policy?, Pangea::Resources::Types::Hash.schema(
            aws_region?: Pangea::Resources::Types::String.optional,
            bias?: Pangea::Resources::Types::Integer.optional.constrained(gteq: -99, lteq: 99),
            coordinates?: Pangea::Resources::Types::Hash.schema(
              latitude: Pangea::Resources::Types::String,
              longitude: Pangea::Resources::Types::String
            ).lax.optional
          ).optional

          # Alias record configuration
          attribute :alias?, Pangea::Resources::Types::Hash.schema(
            name: Pangea::Resources::Types::String,
            zone_id: Pangea::Resources::Types::String,
            evaluate_target_health: Pangea::Resources::Types::Bool.default(false)
          ).lax.optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate zone ID format (skip for terraform references)
            unless Pangea::Resources::BaseAttributes.terraform_reference?(attrs.zone_id) || attrs.zone_id.match?(/\A[A-Z0-9]+\z/)
              raise Dry::Struct::Error, "Invalid hosted zone ID format: #{attrs.zone_id}"
            end

            # Validate record name format (skip for terraform references)
            unless Pangea::Resources::BaseAttributes.terraform_reference?(attrs.name) || attrs.valid_record_name?
              raise Dry::Struct::Error, "Invalid DNS record name format: #{attrs.name}"
            end

            # Alias records and regular records are mutually exclusive
            if attrs.alias && (attrs.ttl || attrs.records.any?)
              raise Dry::Struct::Error, "Alias records cannot have TTL or records values"
            end

            # Non-alias records need TTL and records
            if !attrs.alias
              if attrs.records.empty?
                raise Dry::Struct::Error, "Non-alias records must have at least one record value"
              end
              unless attrs.ttl
                raise Dry::Struct::Error, "Non-alias records must have a TTL value"
              end
            end

            # Validate record type specific constraints
            attrs.validate_record_type_constraints

            # Routing policy validations
            routing_policies = [
              attrs.weighted_routing_policy,
              attrs.latency_routing_policy,
              attrs.failover_routing_policy,
              attrs.geolocation_routing_policy,
              attrs.geoproximity_routing_policy
            ].compact

            if routing_policies.length > 1
              raise Dry::Struct::Error, "Only one routing policy can be specified per record"
            end

            # Set identifier required for routing policies (except multivalue)
            if routing_policies.any? && !attrs.multivalue_answer && !attrs.set_identifier
              raise Dry::Struct::Error, "set_identifier is required when using routing policies"
            end

            # Validate weight range (lax schema doesn't enforce constraints)
            if attrs.weighted_routing_policy
              weight = attrs.weighted_routing_policy[:weight]
              if weight && (weight < 0 || weight > 255)
                raise Dry::Struct::Error, "Weighted routing policy weight must be between 0 and 255, got: #{weight}"
              end
            end

            # Health check validation (skip for terraform references)
            if attrs.health_check_id
              unless Pangea::Resources::BaseAttributes.terraform_reference?(attrs.health_check_id) || attrs.health_check_id.match?(/\A[a-z0-9\-]+\z/)
                raise Dry::Struct::Error, "Invalid health check ID format: #{attrs.health_check_id}"
              end
            end

            attrs
          end
        end
      end
    end
  end
end
