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
require 'pangea/resources/aws_lb_listener/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Load Balancer Listener with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Listener attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lb_listener(name, attributes = {})
        # Validate attributes using dry-struct
        listener_attrs = Types::LoadBalancerListenerAttributes.new(attributes)
        
        # Build resource attributes as a hash
        resource_attrs = {
          load_balancer_arn: listener_attrs.load_balancer_arn,
          port: listener_attrs.port,
          protocol: listener_attrs.protocol
        }

        # SSL configuration for HTTPS/TLS listeners
        if %w[HTTPS TLS].include?(listener_attrs.protocol)
          resource_attrs[:ssl_policy] = listener_attrs.ssl_policy
          resource_attrs[:certificate_arn] = listener_attrs.certificate_arn
        end

        resource_attrs[:alpn_policy] = listener_attrs.alpn_policy if listener_attrs.alpn_policy

        # Build default actions as array of hashes
        resource_attrs[:default_action] = listener_attrs.default_action.map do |action|
          build_listener_action(action)
        end

        resource_attrs[:tags] = listener_attrs.tags if listener_attrs.tags&.any?

        # Write to manifest: direct access for synthesizer (supports arrays/hashes),
        # fall back to resource() for test mocks
        if is_a?(AbstractSynthesizer)
          translation[:manifest][:resource] ||= {}
          translation[:manifest][:resource][:aws_lb_listener] ||= {}
          translation[:manifest][:resource][:aws_lb_listener][name] = resource_attrs
        else
          resource(:aws_lb_listener, name, resource_attrs)
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_lb_listener',
          name: name,
          resource_attributes: listener_attrs.to_h,
          outputs: {
            id: "${aws_lb_listener.#{name}.id}",
            arn: "${aws_lb_listener.#{name}.arn}",
            load_balancer_arn: "${aws_lb_listener.#{name}.load_balancer_arn}",
            port: "${aws_lb_listener.#{name}.port}",
            protocol: "${aws_lb_listener.#{name}.protocol}",
            ssl_policy: "${aws_lb_listener.#{name}.ssl_policy}",
            certificate_arn: "${aws_lb_listener.#{name}.certificate_arn}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_secure?) { ['HTTPS', 'TLS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:requires_ssl?) { ['HTTPS', 'TLS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:is_http_based?) { ['HTTP', 'HTTPS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:is_tcp_based?) { ['TCP', 'TLS', 'TCP_UDP'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:supports_rules?) { ['HTTP', 'HTTPS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:action_count) { listener_attrs.default_action.size }
        ref.define_singleton_method(:has_authentication?) do
          listener_attrs.default_action&.any? { |a| ['authenticate-cognito', 'authenticate-oidc'].include?(a[:type]) }
        end
        ref.define_singleton_method(:has_weighted_routing?) do
          listener_attrs.default_action&.any? { |a| a[:type] == 'forward' && a[:forward] }
        end
        
        ref
      end

      private

      def build_listener_action(action)
        result = { type: action[:type] }
        result[:order] = action[:order] if action[:order]

        case action[:type]
        when 'forward'
          if action[:target_group_arn]
            result[:target_group_arn] = action[:target_group_arn]
          elsif action[:forward]
            result[:forward] = action[:forward].dup
          end
        when 'redirect'
          result[:redirect] = action[:redirect].slice(:protocol, :port, :host, :path, :query, :status_code).compact
        when 'fixed-response'
          result[:fixed_response] = action[:fixed_response].slice(:content_type, :message_body, :status_code).compact
        when 'authenticate-cognito'
          result[:authenticate_cognito] = action[:authenticate_cognito].dup
        when 'authenticate-oidc'
          result[:authenticate_oidc] = action[:authenticate_oidc].dup
        end

        result
      end
    end
  end
end
