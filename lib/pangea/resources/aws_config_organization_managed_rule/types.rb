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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Config Organization Managed Rule resource attributes
        class ConfigOrganizationManagedRuleAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          # Attributes
          attribute? :name, Resources::Types::String.optional
          attribute? :rule_identifier, Resources::Types::String.optional
          attribute? :description, Resources::Types::String.optional
          attribute? :excluded_accounts, Resources::Types::Array.optional
          attribute? :input_parameters, Resources::Types::String.optional
          attribute? :resource_types_scope, Resources::Types::Array.optional
          attribute? :maximum_execution_frequency, Resources::Types::String.optional
          attribute? :resource_id_scope, Resources::Types::String.optional
          attribute? :tag_key_scope, Resources::Types::String.optional
          attribute? :tag_value_scope, Resources::Types::String.optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}
            super(attrs)
          end

          def to_h
            hash = {
              name: name,
              rule_identifier: rule_identifier
            }

            hash[:description] = description if description
            hash[:excluded_accounts] = excluded_accounts if excluded_accounts
            hash[:input_parameters] = input_parameters if input_parameters
            hash[:resource_types_scope] = resource_types_scope if resource_types_scope
            hash[:maximum_execution_frequency] = maximum_execution_frequency if maximum_execution_frequency
            hash[:resource_id_scope] = resource_id_scope if resource_id_scope
            hash[:tag_key_scope] = tag_key_scope if tag_key_scope
            hash[:tag_value_scope] = tag_value_scope if tag_value_scope

            hash.compact
          end
        end
      end
    end
  end
end
