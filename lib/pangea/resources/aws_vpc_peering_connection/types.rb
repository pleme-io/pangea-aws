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
    # Type-safe attributes for AWS VPC Peering Connection resources
    # Provides private connectivity between two VPCs in the same or different regions/accounts
    class VpcPeeringConnectionAttributes < Pangea::Resources::BaseAttributes
      # Required VPC configuration
      attribute? :vpc_id, Resources::Types::String.optional
      attribute? :peer_vpc_id, Resources::Types::String.optional
      
      # Cross-account/region configuration (optional)
      attribute? :peer_owner_id, Resources::Types::String.optional
      attribute? :peer_region, Resources::Types::String.optional
      
      # Auto-accept the peering connection (only works for same account)
      attribute :auto_accept, Resources::Types::Bool.optional.default(false)
      
      # Accepter configuration block
      attribute? :accepter, Resources::Types::Hash.schema(
        allow_remote_vpc_dns_resolution?: Resources::Types::Bool.optional.default(false)
      ).lax.optional
      
      # Requester configuration block
      attribute? :requester, Resources::Types::Hash.schema(
        allow_remote_vpc_dns_resolution?: Resources::Types::Bool.optional.default(false)
      ).lax.optional
      
      # Tags to apply to the resource
      attribute :tags, Resources::Types::AwsTags.default({}.freeze)

      # Custom validation
      def self.new(attributes = {})
        attrs = super(attributes)

        # Validate required attributes
        unless attrs.vpc_id && attrs.peer_vpc_id
          raise Dry::Struct::Error, "vpc_id and peer_vpc_id are required for VPC peering connection"
        end

        # auto_accept only works for same-account connections
        if attrs.auto_accept && attrs.peer_owner_id
          raise Dry::Struct::Error, "auto_accept cannot be true for cross-account peering connections"
        end

        # peer_region validation - cannot be same as default when using auto_accept
        # This is a simplified check - in real usage, current region should be determined
        if attrs.auto_accept && attrs.peer_region
          # Note: This is a basic validation. In practice, you'd want to check against the current region
          # from provider configuration or AWS metadata
        end

        attrs
      end

      # Check if this is a cross-account peering connection
      def cross_account?
        !peer_owner_id.nil?
      end
      alias_method :is_cross_account?, :cross_account?

      # Check if this is a cross-region peering connection
      def cross_region?
        !peer_region.nil?
      end
      alias_method :is_cross_region?, :cross_region?

      # Check if DNS resolution is enabled on accepter side
      def accepter_dns_resolution?
        accepter&.dig(:allow_remote_vpc_dns_resolution) == true
      end

      # Check if DNS resolution is enabled on requester side
      def requester_dns_resolution?
        requester&.dig(:allow_remote_vpc_dns_resolution) == true
      end

      # Check if the peering connection requires manual acceptance
      def requires_manual_acceptance?
        cross_account? || cross_region?
      end

      # Check if DNS resolution is supported (only when auto_accept is true)
      def supports_dns_resolution?
        accepter_dns_resolution? || requester_dns_resolution?
      end

      # Determine peering connection type
      def connection_type
        if cross_account? && cross_region?
          :cross_account_cross_region
        elsif cross_account?
          :cross_account_same_region
        elsif cross_region?
          :same_account_cross_region
        else
          :same_account_same_region
        end
      end

      # Get descriptive peering type string
      def peering_type
        if cross_region? && cross_account?
          "cross-region-cross-account"
        elsif cross_region?
          "cross-region-same-account"
        elsif cross_account?
          "same-region-cross-account"
        else
          "same-region-same-account"
        end
      end

      # Get descriptive name for the connection type
      def connection_type_description
        case connection_type
        when :cross_account_cross_region
          "Cross-account, Cross-region VPC Peering"
        when :cross_account_same_region
          "Cross-account, Same-region VPC Peering"
        when :same_account_cross_region
          "Same-account, Cross-region VPC Peering"
        else
          "Same-account, Same-region VPC Peering"
        end
      end

      # Configuration validation warnings
      def validate_configuration
        warnings = []

        if (requester_dns_resolution? || accepter_dns_resolution?) && !auto_accept
          warnings << "DNS resolution is configured but auto_accept is false - accepter must manually configure DNS resolution"
        end

        if cross_account?
          warnings << "Cross-account peering requires manual acceptance in peer account"
        end

        warnings
      end
    end
  end
end
