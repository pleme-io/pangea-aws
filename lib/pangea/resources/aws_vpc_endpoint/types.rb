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

require 'pangea/resources/types'
require_relative 'types/configs'

module Pangea
  module Resources
    module AwsVpcEndpoint
      module Types
        # Type-safe attributes for AWS VPC Endpoint resources
        class VpcEndpointAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)
          # Required attributes
          attribute? :vpc_id, Resources::Types::String.optional
          attribute? :service_name, Resources::Types::String.optional
        
          # VPC Endpoint type ("Gateway" or "Interface")
          attribute :vpc_endpoint_type, Resources::Types::String.default("Gateway").constrained(included_in: ["Gateway", "Interface"])
        
          # Route table IDs for Gateway endpoints
          attribute? :route_table_ids, Resources::Types::Array.of(Resources::Types::String).optional
        
          # Subnet IDs for Interface endpoints
          attribute? :subnet_ids, Resources::Types::Array.of(Resources::Types::String).optional
        
          # Security group IDs for Interface endpoints
          attribute? :security_group_ids, Resources::Types::Array.of(Resources::Types::String).optional
        
          # Policy document (JSON string)
          attribute? :policy, Resources::Types::String.optional
        
          # Enable private DNS for Interface endpoints
          attribute? :private_dns_enabled, Resources::Types::Bool.default(true)
        
          # Auto accept endpoint connections
          attribute? :auto_accept, Resources::Types::Bool.default(false)
        
          # IP address type for Interface endpoints
          attribute? :ip_address_type, Resources::Types::String.optional

          # DNS options for Interface endpoints
          attribute? :dns_options, Resources::Types::Hash.optional

          # Tags to apply to the resource
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = attributes.is_a?(::Hash) ? attributes.transform_keys(&:to_sym) : (attributes ? attributes.to_h.transform_keys(&:to_sym) : {})

            # Validate required vpc_id
            unless attrs[:vpc_id] && !attrs[:vpc_id].to_s.empty?
              raise Dry::Struct::Error, "vpc_id is required for VPC endpoint"
            end

            # Validate required service_name
            unless attrs[:service_name] && !attrs[:service_name].to_s.empty?
              raise Dry::Struct::Error, "service_name is required for VPC endpoint"
            end

            endpoint_type = attrs[:vpc_endpoint_type] || "Gateway"

            # Validate service name format (allow com.amazonaws.* and com.example.* for PrivateLink)
            if attrs[:service_name] && !Pangea::Resources::BaseAttributes.terraform_reference?(attrs[:service_name])
              unless attrs[:service_name].match?(/\Acom\.[a-z0-9-]+\.[a-z0-9.${}*-]+\z/)
                raise Dry::Struct::Error, "Service name must match AWS service pattern (com.amazonaws.region.service)"
              end
            end

            # Validate Gateway endpoint requirements
            if endpoint_type == "Gateway"
              unless attrs[:route_table_ids] && !attrs[:route_table_ids].empty?
                raise Dry::Struct::Error, "Gateway endpoints require route_table_ids"
              end

              if (attrs[:subnet_ids] && !attrs[:subnet_ids].empty?) || (attrs[:security_group_ids] && !attrs[:security_group_ids].empty?)
                raise Dry::Struct::Error, "Gateway endpoints cannot have subnet_ids or security_group_ids"
              end
            end

            # Validate Interface endpoint requirements
            if endpoint_type == "Interface"
              unless attrs[:subnet_ids] && !attrs[:subnet_ids].empty?
                raise Dry::Struct::Error, "Interface endpoints require subnet_ids"
              end

              if attrs[:route_table_ids] && !attrs[:route_table_ids].empty?
                raise Dry::Struct::Error, "Interface endpoints cannot have route_table_ids"
              end
            end

            # Validate policy is valid JSON if provided
            if attrs[:policy] && !Pangea::Resources::BaseAttributes.terraform_reference?(attrs[:policy])
              begin
                require 'json'
                JSON.parse(attrs[:policy])
              rescue JSON::ParserError
                raise Dry::Struct::Error, "Policy must be valid JSON"
              end
            end

            # Validate DNS options
            if attrs[:dns_options] && attrs[:dns_options][:dns_record_ip_type]
              valid_dns_types = %w[ipv4 dualstack service-defined ipv6]
              unless valid_dns_types.include?(attrs[:dns_options][:dns_record_ip_type])
                raise Dry::Struct::Error, "dns_record_ip_type must be one of: #{valid_dns_types.join(', ')}"
              end
            end

            super(attrs)
          end

          # Check if this is a Gateway endpoint
          def gateway_endpoint?
          vpc_endpoint_type == "Gateway"
        end
          alias_method :is_gateway_endpoint?, :gateway_endpoint?
        
          # Check if this is an Interface endpoint
          def interface_endpoint?
          vpc_endpoint_type == "Interface"
        end
          alias_method :is_interface_endpoint?, :interface_endpoint?

          # Check if this endpoint type requires route tables
          def requires_route_tables?
            gateway_endpoint?
          end

          # Check if this endpoint type requires subnets
          def requires_subnets?
            interface_endpoint?
          end
        
          # Extract AWS service name from service_name
          def aws_service
          service_name.split('.').last
        end
          alias_method :service_type, :aws_service
        
          # Extract AWS region from service_name
          def aws_region
          parts = service_name.split('.')
          return nil unless parts.length >= 4
          parts[2]
        end
        
          # Check if endpoint has policy attached
          def has_policy?
          !policy.nil? && !policy.empty?
        end
        
          # Get the endpoint connectivity type
          def connectivity_type
          case vpc_endpoint_type
          when "Gateway"
            :gateway
          when "Interface"
            :interface
          end
        end

          # Validate configuration and return warnings
          def validate_configuration
            warnings = []
            if interface_endpoint?
              if security_group_ids.nil? || security_group_ids.empty?
                warnings << "Interface endpoint has no security groups - will use VPC default security group"
              end
              if private_dns_enabled == false
                warnings << "Interface endpoint has private DNS disabled - applications must use endpoint DNS names"
              end
            end
            warnings
          end
        end
      end
    end
  end
end
