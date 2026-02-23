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
        # AWS Config Stored Query resource attributes
        class ConfigStoredQueryAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          # Attributes
          attribute? :name, Resources::Types::String.optional
          attribute? :expression, Resources::Types::String.optional
          attribute? :description, Resources::Types::String.optional

          # Tags
          attribute? :tags, Resources::Types::AwsTags.optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}
            super(attrs)
          end

          def to_h
            hash = {
              name: name,
              expression: expression,
              tags: tags
            }

            hash[:description] = description if description

            hash.compact
          end
        end
      end
    end
  end
end
