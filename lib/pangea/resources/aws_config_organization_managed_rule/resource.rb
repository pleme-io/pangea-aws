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
require 'pangea/resources/aws_config_organization_managed_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Organization Managed Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Organization Managed Rule attributes
      # @option attributes [String] :name The name of the rule
      # @option attributes [String] :rule_identifier The AWS Config managed rule identifier
      # @option attributes [String] :description The description of the rule
      # @option attributes [Array] :excluded_accounts Account IDs to exclude
      # @option attributes [String] :input_parameters JSON string of input parameters
      # @option attributes [Array] :resource_types_scope Resource types in scope
      # @option attributes [String] :maximum_execution_frequency Maximum execution frequency
      # @option attributes [String] :tag_key_scope Tag key for scope
      # @option attributes [String] :tag_value_scope Tag value for scope
      # @return [ResourceReference] Reference object with outputs
      def aws_config_organization_managed_rule(name, attributes = {})
        rule_attrs = Types::ConfigOrganizationManagedRuleAttributes.new(attributes)

        resource(:aws_config_organization_managed_rule, name) do
          self.name rule_attrs.name if rule_attrs.name
          rule_identifier rule_attrs.rule_identifier if rule_attrs.rule_identifier
          description rule_attrs.description if rule_attrs.description
          input_parameters rule_attrs.input_parameters if rule_attrs.input_parameters
          maximum_execution_frequency rule_attrs.maximum_execution_frequency if rule_attrs.maximum_execution_frequency
          resource_id_scope rule_attrs.resource_id_scope if rule_attrs.resource_id_scope
          tag_key_scope rule_attrs.tag_key_scope if rule_attrs.tag_key_scope
          tag_value_scope rule_attrs.tag_value_scope if rule_attrs.tag_value_scope

          if rule_attrs.excluded_accounts.is_a?(Array) && rule_attrs.excluded_accounts.any?
            excluded_accounts rule_attrs.excluded_accounts
          end

          if rule_attrs.resource_types_scope.is_a?(Array) && rule_attrs.resource_types_scope.any?
            resource_types_scope rule_attrs.resource_types_scope
          end
        end

        ResourceReference.new(
          type: 'aws_config_organization_managed_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${aws_config_organization_managed_rule.#{name}.id}",
            arn: "${aws_config_organization_managed_rule.#{name}.arn}",
            name: "${aws_config_organization_managed_rule.#{name}.name}",
            tags_all: "${aws_config_organization_managed_rule.#{name}.tags_all}"
          }
        )
      end
    end
  end
end
