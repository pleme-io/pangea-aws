# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AwsVpcEndpoint
      module Types
        # Common VPC endpoint configurations
        module VpcEndpointConfigs
          module_function

          # S3 Gateway endpoint configuration
          #
          # @param vpc_id [String] The VPC ID
          # @param route_table_ids [Array<String>] Route table IDs to associate
          # @param tags [Hash] Optional tags to apply
          # @return [Hash] Configuration hash for VpcEndpointAttributes
          def s3_gateway(vpc_id, route_table_ids, tags: {})
            {
              vpc_id: vpc_id,
              service_name: "com.amazonaws.${data.aws_region.current.name}.s3",
              vpc_endpoint_type: "Gateway",
              route_table_ids: route_table_ids,
              tags: tags
            }
          end

          # DynamoDB Gateway endpoint configuration
          #
          # @param vpc_id [String] The VPC ID
          # @param route_table_ids [Array<String>] Route table IDs to associate
          # @param tags [Hash] Optional tags to apply
          # @return [Hash] Configuration hash for VpcEndpointAttributes
          def dynamodb_gateway(vpc_id, route_table_ids, tags: {})
            {
              vpc_id: vpc_id,
              service_name: "com.amazonaws.${data.aws_region.current.name}.dynamodb",
              vpc_endpoint_type: "Gateway",
              route_table_ids: route_table_ids,
              tags: tags
            }
          end

          # Interface endpoint configuration for any AWS service
          #
          # @param vpc_id [String] The VPC ID
          # @param service [String] The AWS service name (e.g., "ec2", "ssm", "logs")
          # @param subnet_ids [Array<String>] Subnet IDs to place the endpoint in
          # @param security_group_ids [Array<String>] Security group IDs to attach
          # @param private_dns [Boolean] Whether to enable private DNS
          # @param tags [Hash] Optional tags to apply
          # @return [Hash] Configuration hash for VpcEndpointAttributes
          def interface_endpoint(vpc_id, service, subnet_ids, security_group_ids: [], private_dns: true, tags: {})
            config = {
              vpc_id: vpc_id,
              service_name: "com.amazonaws.${data.aws_region.current.name}.#{service}",
              vpc_endpoint_type: "Interface",
              subnet_ids: subnet_ids,
              private_dns_enabled: private_dns,
              tags: tags
            }

            config[:security_group_ids] = security_group_ids unless security_group_ids.empty?

            config
          end

          # PrivateLink endpoint configuration for custom or third-party services
          #
          # @param vpc_id [String] The VPC ID
          # @param service_name [String] The full PrivateLink service name
          # @param subnet_ids [Array<String>] Subnet IDs to place the endpoint in
          # @param security_group_ids [Array<String>] Security group IDs to attach
          # @param private_dns [Boolean] Whether to enable private DNS
          # @param tags [Hash] Optional tags to apply
          # @return [Hash] Configuration hash for VpcEndpointAttributes
          def privatelink_endpoint(vpc_id, service_name, subnet_ids, security_group_ids: [], private_dns: true, tags: {})
            config = {
              vpc_id: vpc_id,
              service_name: service_name,
              vpc_endpoint_type: "Interface",
              subnet_ids: subnet_ids,
              private_dns_enabled: private_dns,
              tags: tags
            }

            config[:security_group_ids] = security_group_ids unless security_group_ids.empty?

            config
          end
        end
      end
    end
  end
end
