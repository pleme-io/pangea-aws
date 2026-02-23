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
        # WAF v2 Rule configuration
        class WafV2Rule < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          attribute? :name, Resources::Types::String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/).optional
          attribute? :priority, Resources::Types::Integer.constrained(gteq: 0).optional
          attribute? :action, WafV2RuleAction.optional
          attribute? :statement, WafV2Statement.optional
          attribute? :visibility_config, WafV2VisibilityConfig.optional
          attribute? :rule_labels, Resources::Types::Array.of(Resources::Types::Hash.schema(
                                             name: Resources::Types::String.constrained(format: /\A[a-zA-Z0-9_:-]{1,1024}\z/)
                                           )).lax.default([].freeze)
          attribute? :captcha_config, Resources::Types::Hash.schema(
            immunity_time_property: Resources::Types::Hash.schema(
              immunity_time: Resources::Types::Integer.constrained(gteq: 60, lteq: 259_200)
            ).lax
          ).optional
          attribute? :challenge_config, Resources::Types::Hash.schema(
            immunity_time_property: Resources::Types::Hash.schema(
              immunity_time: Resources::Types::Integer.constrained(gteq: 60, lteq: 259_200)
            ).lax
          ).optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}

            raise Dry::Struct::Error, 'captcha_config can only be specified with captcha action' if attrs[:captcha_config] && (!attrs[:action] || !attrs[:action][:captcha])

            raise Dry::Struct::Error, 'challenge_config can only be specified with challenge action' if attrs[:challenge_config] && (!attrs[:action] || !attrs[:action][:challenge])

            super(attrs)
          end
        end
      end
    end
  end
end
