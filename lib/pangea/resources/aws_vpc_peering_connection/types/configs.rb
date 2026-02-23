# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    # Common VPC peering connection configurations
    module VpcPeeringConfigs
      module_function

      # Same-region, same-account peering with optional DNS resolution
      #
      # @param vpc_id [String] The requester VPC ID
      # @param peer_vpc_id [String] The accepter VPC ID
      # @param auto_accept [Boolean] Whether to auto-accept the connection
      # @param enable_dns [Boolean] Whether to enable DNS resolution across the peering
      # @return [Hash] Configuration hash for VpcPeeringConnectionAttributes
      def same_region_peering(vpc_id, peer_vpc_id, auto_accept: true, enable_dns: false)
        config = {
          vpc_id: vpc_id,
          peer_vpc_id: peer_vpc_id,
          auto_accept: auto_accept
        }

        if enable_dns
          config[:requester] = { allow_remote_vpc_dns_resolution: true }
          config[:accepter] = { allow_remote_vpc_dns_resolution: true }
        else
          config[:requester] = {}
          config[:accepter] = {}
        end

        config
      end

      # Cross-region peering (auto_accept is always false for cross-region)
      #
      # @param vpc_id [String] The requester VPC ID
      # @param peer_vpc_id [String] The accepter VPC ID
      # @param peer_region [String] The region of the accepter VPC
      # @param enable_dns [Boolean] Whether to enable DNS resolution across the peering
      # @return [Hash] Configuration hash for VpcPeeringConnectionAttributes
      def cross_region_peering(vpc_id, peer_vpc_id, peer_region, enable_dns: false)
        config = {
          vpc_id: vpc_id,
          peer_vpc_id: peer_vpc_id,
          peer_region: peer_region,
          auto_accept: false
        }

        if enable_dns
          config[:requester] = { allow_remote_vpc_dns_resolution: true }
          config[:accepter] = { allow_remote_vpc_dns_resolution: true }
        else
          config[:requester] = {}
        end

        config
      end

      # Cross-account peering (auto_accept is always false for cross-account)
      #
      # @param vpc_id [String] The requester VPC ID
      # @param peer_vpc_id [String] The accepter VPC ID
      # @param peer_owner_id [String] The AWS account ID that owns the accepter VPC
      # @param region [String, nil] The region of the accepter VPC (nil for same-region)
      # @return [Hash] Configuration hash for VpcPeeringConnectionAttributes
      def cross_account_peering(vpc_id, peer_vpc_id, peer_owner_id, region: nil)
        config = {
          vpc_id: vpc_id,
          peer_vpc_id: peer_vpc_id,
          peer_owner_id: peer_owner_id,
          auto_accept: false
        }

        config[:peer_region] = region if region

        config
      end

      # Hub-spoke peering pattern (hub VPC to spoke VPC, same account)
      #
      # @param hub_vpc_id [String] The hub VPC ID
      # @param spoke_vpc_id [String] The spoke VPC ID
      # @param spoke_name [String] A descriptive name for the spoke
      # @return [Hash] Configuration hash for VpcPeeringConnectionAttributes
      def hub_spoke_peering(hub_vpc_id, spoke_vpc_id, spoke_name: "spoke")
        {
          vpc_id: hub_vpc_id,
          peer_vpc_id: spoke_vpc_id,
          auto_accept: true,
          tags: {
            Name: "hub-to-#{spoke_name}",
            Pattern: "hub-spoke"
          }
        }
      end

      # Transit peering pattern (VPC to transit/shared-services VPC)
      #
      # @param vpc_id [String] The VPC ID connecting to transit
      # @param transit_vpc_id [String] The transit VPC ID
      # @param enable_dns [Boolean] Whether to enable DNS resolution across the peering
      # @return [Hash] Configuration hash for VpcPeeringConnectionAttributes
      def transit_peering(vpc_id, transit_vpc_id, enable_dns: false)
        config = {
          vpc_id: vpc_id,
          peer_vpc_id: transit_vpc_id,
          auto_accept: true,
          tags: {
            Purpose: "transit-connectivity"
          }
        }

        if enable_dns
          config[:requester] = { allow_remote_vpc_dns_resolution: true }
          config[:accepter] = { allow_remote_vpc_dns_resolution: true }
        end

        config
      end
    end
  end
end
