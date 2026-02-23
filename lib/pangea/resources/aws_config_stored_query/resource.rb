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
require 'pangea/resources/aws_config_stored_query/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Stored Query with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Stored Query attributes
      # @option attributes [String] :name The name of the stored query
      # @option attributes [String] :expression The SQL expression for the query
      # @option attributes [String] :description The description of the query
      # @option attributes [Hash] :tags A map of tags to assign to the resource
      # @return [ResourceReference] Reference object with outputs
      def aws_config_stored_query(name, attributes = {})
        query_attrs = Types::ConfigStoredQueryAttributes.new(attributes)

        resource(:aws_config_stored_query, name) do
          self.name query_attrs.name if query_attrs.name
          expression query_attrs.expression if query_attrs.expression
          description query_attrs.description if query_attrs.description

          if query_attrs.tags&.any?
            tags do
              query_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'aws_config_stored_query',
          name: name,
          resource_attributes: query_attrs.to_h,
          outputs: {
            id: "${aws_config_stored_query.#{name}.id}",
            arn: "${aws_config_stored_query.#{name}.arn}",
            name: "${aws_config_stored_query.#{name}.name}",
            tags_all: "${aws_config_stored_query.#{name}.tags_all}"
          }
        )
      end
    end
  end
end
