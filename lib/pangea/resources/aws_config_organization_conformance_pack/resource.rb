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
require 'pangea/resources/aws_config_organization_conformance_pack/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Organization Conformance Pack with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Organization Conformance Pack attributes
      # @option attributes [String] :name The name of the conformance pack
      # @option attributes [String] :template_s3_uri S3 URI of the conformance pack template
      # @option attributes [String] :template_body Inline template body
      # @option attributes [String] :delivery_s3_bucket S3 bucket for delivery
      # @option attributes [String] :delivery_s3_key_prefix S3 key prefix for delivery
      # @option attributes [Array] :excluded_accounts Account IDs to exclude
      # @option attributes [Array] :conformance_pack_input_parameters Input parameters
      # @return [ResourceReference] Reference object with outputs
      def aws_config_organization_conformance_pack(name, attributes = {})
        pack_attrs = Types::ConfigOrganizationConformancePackAttributes.new(attributes)

        resource(:aws_config_organization_conformance_pack, name) do
          self.name pack_attrs.name if pack_attrs.name
          template_s3_uri pack_attrs.template_s3_uri if pack_attrs.template_s3_uri
          template_body pack_attrs.template_body if pack_attrs.template_body
          delivery_s3_bucket pack_attrs.delivery_s3_bucket if pack_attrs.delivery_s3_bucket
          delivery_s3_key_prefix pack_attrs.delivery_s3_key_prefix if pack_attrs.delivery_s3_key_prefix

          if pack_attrs.excluded_accounts.is_a?(Array) && pack_attrs.excluded_accounts.any?
            excluded_accounts pack_attrs.excluded_accounts
          end

          if pack_attrs.conformance_pack_input_parameters.is_a?(Array) && pack_attrs.conformance_pack_input_parameters.any?
            pack_attrs.conformance_pack_input_parameters.each do |param|
              conformance_pack_input_parameters do
                parameter_name param[:parameter_name] if param[:parameter_name]
                parameter_value param[:parameter_value] if param[:parameter_value]
              end
            end
          end
        end

        ResourceReference.new(
          type: 'aws_config_organization_conformance_pack',
          name: name,
          resource_attributes: pack_attrs.to_h,
          outputs: {
            id: "${aws_config_organization_conformance_pack.#{name}.id}",
            arn: "${aws_config_organization_conformance_pack.#{name}.arn}",
            name: "${aws_config_organization_conformance_pack.#{name}.name}",
            tags_all: "${aws_config_organization_conformance_pack.#{name}.tags_all}"
          },
          computed_properties: {
            template_source: pack_attrs.template_source,
            parameter_count: pack_attrs.parameter_count
          }
        )
      end
    end
  end
end
