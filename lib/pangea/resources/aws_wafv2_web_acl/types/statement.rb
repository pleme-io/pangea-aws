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
        # WAF v2 Rule statement configuration
        class WafV2Statement < Pangea::Resources::BaseAttributes
          STATEMENT_TYPES = %i[
            byte_match_statement sqli_match_statement xss_match_statement
            size_constraint_statement geo_match_statement ip_set_reference_statement
            rule_group_reference_statement managed_rule_group_statement
            rate_based_statement and_statement or_statement not_statement
          ].freeze

          transform_keys(&:to_sym)

          attribute? :byte_match_statement, Resources::Types::Hash.schema(
            field_to_match: Resources::Types::Hash.schema(
              all_query_arguments?: Resources::Types::Hash.schema({}).lax.optional,
              body?: Resources::Types::Hash.schema(oversize_handling?: Resources::Types::String.constrained(included_in: ['CONTINUE', 'MATCH', 'NO_MATCH']).lax.optional).optional,
              method?: Resources::Types::Hash.schema({}).lax.optional,
              query_string?: Resources::Types::Hash.schema({}).lax.optional,
              single_header?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              single_query_argument?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              uri_path?: Resources::Types::Hash.schema({}).lax.optional,
              json_body?: Resources::Types::Hash.schema(
                match_pattern: Resources::Types::WafV2JsonBodyMatchPattern,
                match_scope: Resources::Types::String.constrained(included_in: ['ALL', 'KEY', 'VALUE']),
                invalid_fallback_behavior?: Resources::Types::String.constrained(included_in: ['MATCH', 'NO_MATCH', 'EVALUATE_AS_STRING']).optional,
                oversize_handling?: Resources::Types::String.constrained(included_in: ['CONTINUE', 'MATCH', 'NO_MATCH']).optional
              ).lax.optional
            ),
            positional_constraint: Resources::Types::WafV2PositionalConstraint,
            search_string: Resources::Types::String,
            text_transformations: Resources::Types::Array.of(Resources::Types::Hash.schema(
                                             priority: Resources::Types::Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1).lax
          ).optional

          attribute? :sqli_match_statement, Resources::Types::Hash.schema(
            field_to_match: Resources::Types::Hash.schema(
              all_query_arguments?: Resources::Types::Hash.schema({}).lax.optional,
              body?: Resources::Types::Hash.schema(oversize_handling?: Resources::Types::String.constrained(included_in: ['CONTINUE', 'MATCH', 'NO_MATCH']).lax.optional).optional,
              method?: Resources::Types::Hash.schema({}).lax.optional,
              query_string?: Resources::Types::Hash.schema({}).lax.optional,
              single_header?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              single_query_argument?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              uri_path?: Resources::Types::Hash.schema({}).lax.optional
            ),
            text_transformations: Resources::Types::Array.of(Resources::Types::Hash.schema(
                                             priority: Resources::Types::Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1).lax
          ).optional

          attribute? :xss_match_statement, Resources::Types::Hash.schema(
            field_to_match: Resources::Types::Hash.schema(
              all_query_arguments?: Resources::Types::Hash.schema({}).lax.optional,
              body?: Resources::Types::Hash.schema(oversize_handling?: Resources::Types::String.constrained(included_in: ['CONTINUE', 'MATCH', 'NO_MATCH']).lax.optional).optional,
              method?: Resources::Types::Hash.schema({}).lax.optional,
              query_string?: Resources::Types::Hash.schema({}).lax.optional,
              single_header?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              single_query_argument?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              uri_path?: Resources::Types::Hash.schema({}).lax.optional
            ),
            text_transformations: Resources::Types::Array.of(Resources::Types::Hash.schema(
                                             priority: Resources::Types::Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1).lax
          ).optional

          attribute? :size_constraint_statement, Resources::Types::Hash.schema(
            field_to_match: Resources::Types::Hash.schema(
              all_query_arguments?: Resources::Types::Hash.schema({}).lax.optional,
              body?: Resources::Types::Hash.schema(oversize_handling?: Resources::Types::String.constrained(included_in: ['CONTINUE', 'MATCH', 'NO_MATCH']).lax.optional).optional,
              method?: Resources::Types::Hash.schema({}).lax.optional,
              query_string?: Resources::Types::Hash.schema({}).lax.optional,
              single_header?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              single_query_argument?: Resources::Types::Hash.schema(name: Resources::Types::String).lax.optional,
              uri_path?: Resources::Types::Hash.schema({}).lax.optional
            ),
            comparison_operator: Resources::Types::WafV2ComparisonOperator,
            size: Resources::Types::Integer.constrained(gteq: 0, lteq: 21_474_836_480),
            text_transformations: Resources::Types::Array.of(Resources::Types::Hash.schema(
                                             priority: Resources::Types::Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1).lax
          ).optional

          attribute? :geo_match_statement, Resources::Types::Hash.schema(
            country_codes: Resources::Types::Array.of(Resources::Types::String.constrained(format: /\A[A-Z]{2}\z/)).constrained(min_size: 1),
            forwarded_ip_config?: Resources::Types::Hash.schema(
              header_name: Resources::Types::String,
              fallback_behavior: Resources::Types::String.constrained(included_in: ['MATCH', 'NO_MATCH'])
            ).lax.optional
          ).optional

          attribute? :ip_set_reference_statement, Resources::Types::Hash.schema(
            arn: Resources::Types::String.constrained(format: /\Aarn:aws:wafv2:/),
            ip_set_forwarded_ip_config?: Resources::Types::Hash.schema(
              header_name: Resources::Types::String,
              fallback_behavior: Resources::Types::String.constrained(included_in: ['MATCH', 'NO_MATCH']),
              position: Resources::Types::String.constrained(included_in: ['FIRST', 'LAST', 'ANY'])
            ).lax.optional
          ).optional

          attribute? :rule_group_reference_statement, Resources::Types::Hash.schema(
            arn: Resources::Types::String.constrained(format: /\Aarn:aws:wafv2:/),
            excluded_rules?: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String).lax).optional
          ).optional

          attribute? :managed_rule_group_statement, Resources::Types::Hash.schema(
            vendor_name: Resources::Types::String,
            name: Resources::Types::String,
            version?: Resources::Types::String.optional,
            excluded_rules?: Resources::Types::Array.of(Resources::Types::Hash.schema(name: Resources::Types::String).lax).optional,
            scope_down_statement?: Resources::Types::Hash.optional,
            managed_rule_group_configs?: Resources::Types::Array.of(Resources::Types::Hash).optional
          ).optional

          attribute? :rate_based_statement, Resources::Types::Hash.schema(
            limit: Resources::Types::WafV2RateLimit,
            aggregate_key_type: Resources::Types::String.constrained(included_in: ['IP', 'FORWARDED_IP']),
            forwarded_ip_config?: Resources::Types::Hash.schema(
              header_name: Resources::Types::String,
              fallback_behavior: Resources::Types::String.constrained(included_in: ['MATCH', 'NO_MATCH'])
            ).lax.optional,
            scope_down_statement?: Resources::Types::Hash.optional
          ).optional

          attribute? :and_statement, Resources::Types::Hash.schema(
            statements: Resources::Types::Array.of(Resources::Types::Hash).constrained(min_size: 2)
          ).lax.optional

          attribute? :or_statement, Resources::Types::Hash.schema(
            statements: Resources::Types::Array.of(Resources::Types::Hash).constrained(min_size: 2)
          ).lax.optional

          attribute? :not_statement, Resources::Types::Hash.schema(
            statement: Resources::Types::Hash
          ).lax.optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}
            provided_statements = STATEMENT_TYPES.select { |type| attrs.key?(type) }

            raise Dry::Struct::Error, 'WAF v2 statement must specify exactly one statement type' if provided_statements.empty?

            raise Dry::Struct::Error, "WAF v2 statement must specify exactly one statement type, got: #{provided_statements.join(', ')}" if provided_statements.size > 1

            super(attrs)
          end
        end
      end
    end
  end
end
