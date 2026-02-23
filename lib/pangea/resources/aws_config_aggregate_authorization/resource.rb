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
require 'pangea/resources/aws_config_aggregate_authorization/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Aggregate Authorization with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Aggregate Authorization attributes
      # @option attributes [String] :account_id The account ID of the account to authorize
      # @option attributes [String] :region The region to authorize
      # @option attributes [Hash] :tags A map of tags to assign to the resource
      # @return [ResourceReference] Reference object with outputs
      def aws_config_aggregate_authorization(name, attributes = {})
        auth_attrs = Types::ConfigAggregateAuthorizationAttributes.new(attributes)

        resource(:aws_config_aggregate_authorization, name) do
          account_id auth_attrs.account_id if auth_attrs.account_id
          region auth_attrs.region if auth_attrs.region

          if auth_attrs.tags&.any?
            tags do
              auth_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'aws_config_aggregate_authorization',
          name: name,
          resource_attributes: auth_attrs.to_h,
          outputs: {
            id: "${aws_config_aggregate_authorization.#{name}.id}",
            arn: "${aws_config_aggregate_authorization.#{name}.arn}",
            account_id: "${aws_config_aggregate_authorization.#{name}.account_id}",
            region: "${aws_config_aggregate_authorization.#{name}.region}",
            tags_all: "${aws_config_aggregate_authorization.#{name}.tags_all}"
          }
        )
      end
    end
  end
end
