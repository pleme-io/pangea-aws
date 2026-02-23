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
require 'pangea/resources/aws_cloudfront_distribution/types'
require 'pangea/resource_registry'
require_relative 'builders/origin_builder'
require_relative 'builders/cache_behavior_builder'
require_relative 'builders/settings_builder'
require_relative 'builders/reference_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Distribution with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront distribution attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_distribution(name, attributes = {})
        distribution_attrs = Types::CloudFrontDistributionAttributes.new(attributes)

        resource(:aws_cloudfront_distribution, name) do
          # Origins (array of hashes)
          origin build_cf_origins(distribution_attrs.origin)

          # Default cache behavior (single hash)
          default_cache_behavior build_cf_cache_behavior(distribution_attrs.default_cache_behavior)

          # Ordered cache behaviors (array of hashes)
          if distribution_attrs.ordered_cache_behavior.any?
            ordered_cache_behavior distribution_attrs.ordered_cache_behavior.map { |b|
              build_cf_ordered_cache_behavior(b)
            }
          end

          # Basic settings
          comment distribution_attrs.comment
          default_root_object distribution_attrs.default_root_object if distribution_attrs.default_root_object
          enabled distribution_attrs.enabled
          http_version distribution_attrs.http_version
          is_ipv6_enabled distribution_attrs.is_ipv6_enabled
          price_class distribution_attrs.price_class
          aliases distribution_attrs.aliases if distribution_attrs.aliases.any?
          web_acl_id distribution_attrs.web_acl_id if distribution_attrs.web_acl_id
          retain_on_delete distribution_attrs.retain_on_delete
          wait_for_deployment distribution_attrs.wait_for_deployment

          # Custom error responses (array of hashes)
          if distribution_attrs.custom_error_response.any?
            custom_error_response distribution_attrs.custom_error_response.map { |er|
              build_cf_custom_error_response(er)
            }
          end

          # Restrictions
          if distribution_attrs.restrictions
            restrictions build_cf_restrictions(distribution_attrs.restrictions)
          end

          # Viewer certificate
          if distribution_attrs.viewer_certificate
            viewer_certificate build_cf_viewer_certificate(distribution_attrs.viewer_certificate)
          end

          # Tags
          tags distribution_attrs.tags if distribution_attrs.tags&.any?
        end

        CloudFrontDistribution::ReferenceBuilder.build_reference(name, distribution_attrs)
      end

      private

      def build_cf_origins(origins)
        origins.map { |origin_config| build_cf_origin(origin_config) }
      end

      def build_cf_origin(origin_config)
        origin_hash = {
          domain_name: origin_config[:domain_name],
          origin_id: origin_config[:origin_id]
        }
        origin_hash[:origin_path] = origin_config[:origin_path] if origin_config[:origin_path]
        origin_hash[:connection_attempts] = origin_config[:connection_attempts] if origin_config[:connection_attempts]
        origin_hash[:connection_timeout] = origin_config[:connection_timeout] if origin_config[:connection_timeout]

        if origin_config[:s3_origin_config]
          s3_cfg = origin_config[:s3_origin_config]
          s3_hash = {}
          s3_hash[:origin_access_identity] = s3_cfg[:origin_access_identity] if s3_cfg[:origin_access_identity]
          s3_hash[:origin_access_control_id] = s3_cfg[:origin_access_control_id] if s3_cfg[:origin_access_control_id]
          origin_hash[:s3_origin_config] = s3_hash
        end

        if origin_config[:custom_origin_config]
          custom_cfg = origin_config[:custom_origin_config]
          custom_hash = {}
          custom_hash[:http_port] = custom_cfg[:http_port] if custom_cfg[:http_port]
          custom_hash[:https_port] = custom_cfg[:https_port] if custom_cfg[:https_port]
          custom_hash[:origin_protocol_policy] = custom_cfg[:origin_protocol_policy] if custom_cfg[:origin_protocol_policy]
          custom_hash[:origin_ssl_protocols] = custom_cfg[:origin_ssl_protocols] if custom_cfg[:origin_ssl_protocols]
          custom_hash[:origin_keepalive_timeout] = custom_cfg[:origin_keepalive_timeout] if custom_cfg[:origin_keepalive_timeout]
          custom_hash[:origin_read_timeout] = custom_cfg[:origin_read_timeout] if custom_cfg[:origin_read_timeout]
          origin_hash[:custom_origin_config] = custom_hash
        end

        if origin_config[:origin_shield]
          shield = origin_config[:origin_shield]
          shield_hash = { enabled: shield[:enabled] }
          shield_hash[:origin_shield_region] = shield[:origin_shield_region] if shield[:origin_shield_region]
          origin_hash[:origin_shield] = shield_hash
        end

        if origin_config[:custom_header]&.any?
          origin_hash[:custom_header] = origin_config[:custom_header].map { |h|
            { name: h[:name], value: h[:value] }
          }
        end

        origin_hash
      end

      def build_cf_cache_behavior(behavior)
        bh = {
          target_origin_id: behavior[:target_origin_id],
          viewer_protocol_policy: behavior[:viewer_protocol_policy]
        }
        bh[:allowed_methods] = behavior[:allowed_methods] if behavior[:allowed_methods]
        bh[:cached_methods] = behavior[:cached_methods] if behavior[:cached_methods]
        bh[:cache_policy_id] = behavior[:cache_policy_id] if behavior[:cache_policy_id]
        bh[:origin_request_policy_id] = behavior[:origin_request_policy_id] if behavior[:origin_request_policy_id]
        bh[:response_headers_policy_id] = behavior[:response_headers_policy_id] if behavior[:response_headers_policy_id]
        bh[:realtime_log_config_arn] = behavior[:realtime_log_config_arn] if behavior[:realtime_log_config_arn]
        bh[:smooth_streaming] = behavior[:smooth_streaming] if behavior[:smooth_streaming]
        bh[:trusted_signers] = behavior[:trusted_signers] if behavior[:trusted_signers]&.any?
        bh[:trusted_key_groups] = behavior[:trusted_key_groups] if behavior[:trusted_key_groups]&.any?
        bh[:compress] = behavior[:compress] if behavior.key?(:compress)
        bh[:field_level_encryption_id] = behavior[:field_level_encryption_id] if behavior[:field_level_encryption_id]

        if behavior[:function_association]&.any?
          bh[:function_association] = behavior[:function_association].map { |fa|
            { event_type: fa[:event_type], function_arn: fa[:function_arn] }
          }
        end

        if behavior[:lambda_function_association]&.any?
          bh[:lambda_function_association] = behavior[:lambda_function_association].map { |la|
            lh = { event_type: la[:event_type], lambda_arn: la[:lambda_arn] }
            lh[:include_body] = la[:include_body] if la.key?(:include_body)
            lh
          }
        end

        bh
      end

      def build_cf_ordered_cache_behavior(behavior)
        bh = build_cf_cache_behavior(behavior)
        bh[:path_pattern] = behavior[:path_pattern]
        bh
      end

      def build_cf_custom_error_response(error_response)
        er = { error_code: error_response[:error_code] }
        er[:response_code] = error_response[:response_code] if error_response[:response_code]
        er[:response_page_path] = error_response[:response_page_path] if error_response[:response_page_path]
        er[:error_caching_min_ttl] = error_response[:error_caching_min_ttl] if error_response[:error_caching_min_ttl]
        er
      end

      def build_cf_restrictions(restrictions)
        return unless restrictions

        geo = restrictions[:geo_restriction]
        return unless geo

        rh = { geo_restriction: { restriction_type: geo[:restriction_type] } }
        rh[:geo_restriction][:locations] = geo[:locations] if geo[:locations]&.any?
        rh
      end

      def build_cf_viewer_certificate(cert)
        vc = {}
        vc[:acm_certificate_arn] = cert[:acm_certificate_arn] if cert[:acm_certificate_arn]
        vc[:iam_certificate_id] = cert[:iam_certificate_id] if cert[:iam_certificate_id]
        vc[:cloudfront_default_certificate] = cert[:cloudfront_default_certificate] if cert.key?(:cloudfront_default_certificate)
        vc[:ssl_support_method] = cert[:ssl_support_method] if cert[:ssl_support_method]
        vc[:minimum_protocol_version] = cert[:minimum_protocol_version] if cert[:minimum_protocol_version]
        vc
      end
    end
  end
end
