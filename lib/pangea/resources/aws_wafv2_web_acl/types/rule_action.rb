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
        # WAF v2 Rule action configuration
        class WafV2RuleAction < Pangea::Resources::BaseAttributes
          ACTION_TYPES = %i[allow block count captcha challenge].freeze

          transform_keys(&:to_sym)

          attribute? :allow, Resources::Types::Hash.schema(
            custom_request_handling?: Resources::Types::Hash.schema(
              insert_headers: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String, value: Resources::Types::String).lax)
            ).optional
          ).optional

          attribute? :block, Resources::Types::Hash.schema(
            custom_response?: Resources::Types::Hash.schema(
              response_code: Resources::Types::Integer.constrained(gteq: 200, lteq: 599),
              custom_response_body_key?: Resources::Types::String.optional,
              response_headers?: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String, value: Resources::Types::String).lax).optional
            ).optional
          ).optional

          attribute? :count, Resources::Types::Hash.schema(
            custom_request_handling?: Resources::Types::Hash.schema(
              insert_headers: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String, value: Resources::Types::String).lax)
            ).optional
          ).optional

          attribute? :captcha, Resources::Types::Hash.schema(
            custom_request_handling?: Resources::Types::Hash.schema(
              insert_headers: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String, value: Resources::Types::String).lax)
            ).optional
          ).optional

          attribute? :challenge, Resources::Types::Hash.schema(
            custom_request_handling?: Resources::Types::Hash.schema(
              insert_headers: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String, value: Resources::Types::String).lax)
            ).optional
          ).optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}
            provided_actions = ACTION_TYPES.select { |type| attrs.key?(type) }

            raise Dry::Struct::Error, 'WAF v2 rule action must specify exactly one action type' if provided_actions.empty?

            raise Dry::Struct::Error, "WAF v2 rule action must specify exactly one action type, got: #{provided_actions.join(', ')}" if provided_actions.size > 1

            super(attrs)
          end
        end
      end
    end
  end
end
