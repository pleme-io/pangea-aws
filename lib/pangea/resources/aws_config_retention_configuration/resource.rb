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
require 'pangea/resources/aws_config_retention_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Retention Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Retention Configuration attributes
      # @option attributes [Integer] :retention_period_in_days Number of days to retain configuration items
      # @return [ResourceReference] Reference object with outputs
      def aws_config_retention_configuration(name, attributes = {})
        retention_attrs = Types::ConfigRetentionConfigurationAttributes.new(attributes)

        resource(:aws_config_retention_configuration, name) do
          retention_period_in_days retention_attrs.retention_period_in_days if retention_attrs.retention_period_in_days
        end

        ResourceReference.new(
          type: 'aws_config_retention_configuration',
          name: name,
          resource_attributes: retention_attrs.to_h,
          outputs: {
            id: "${aws_config_retention_configuration.#{name}.id}",
            arn: "${aws_config_retention_configuration.#{name}.arn}",
            retention_period_in_days: "${aws_config_retention_configuration.#{name}.retention_period_in_days}"
          }
        )
      end
    end
  end
end
