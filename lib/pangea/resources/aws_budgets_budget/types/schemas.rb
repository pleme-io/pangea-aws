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

require_relative 'enums'

module Pangea
  module Resources
    module AWS
      module Types
        # Budget spend definition
        BudgetSpend = Resources::Types::Hash.schema(
          amount: Resources::Types::String.constrained(format: /\A\d+(\.\d{1,2})?\z/).constructor { |value|
            amount_float = value.to_f
            if amount_float <= 0
              raise Dry::Types::ConstraintError, "Budget amount must be positive"
            end
            if amount_float > 1_000_000_000
              raise Dry::Types::ConstraintError, "Budget amount cannot exceed 1 billion"
            end
            value
          },
          unit: BudgetCurrency
        )

        # Time period for budget
        BudgetTimePeriod = Resources::Types::Hash.schema(
          start?: Resources::Types::String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional,
          end?: Resources::Types::String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional
        ).constructor do |value|
          if value[:start] && value[:end]
            start_date = Date.parse(value[:start])
            end_date = Date.parse(value[:end])

            if end_date <= start_date
              raise Dry::Types::ConstraintError, "Budget end date must be after start date"
            end

            months_diff = (end_date.year - start_date.year) * 12 + end_date.month - start_date.month
            if months_diff < 1
              raise Dry::Types::ConstraintError, "Budget must span at least 1 month"
            end
          end

          value
        rescue Date::Error
          raise Dry::Types::ConstraintError, "Budget time period dates must be in YYYY-MM-DD format"
        end

        # Cost filter for budget
        BudgetCostFilter = Resources::Types::Hash.schema(
          dimension_key: CostDimensionKey,
          values: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 1000),
          match_options?: Resources::Types::Array.of(
            Resources::Types::String.constrained(included_in: ['EQUALS', 'ABSENT', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS',
                        'CASE_SENSITIVE', 'CASE_INSENSITIVE'])
          ).optional
        )

        # Tag filter for budget costs
        BudgetTagFilter = Resources::Types::Hash.schema(
          key: Resources::Types::String.constrained(min_size: 1, max_size: 128),
          values?: Resources::Types::Array.of(Resources::Types::String).constrained(max_size: 1000).optional,
          match_options?: Resources::Types::Array.of(
            Resources::Types::String.constrained(included_in: ['EQUALS', 'ABSENT', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS',
                        'CASE_SENSITIVE', 'CASE_INSENSITIVE'])
          ).optional
        )

        # Cost filters for budget
        BudgetCostFilters = Resources::Types::Hash.schema(
          and?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              dimensions?: Resources::Types::Hash.map(CostDimensionKey, Resources::Types::Array.of(Resources::Types::String)).optional,
              tags?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::Array.of(Resources::Types::String)).optional,
              cost_categories?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::Array.of(Resources::Types::String)).optional
            )
          ).optional,
          dimensions?: Resources::Types::Hash.map(CostDimensionKey, Resources::Types::Array.of(Resources::Types::String)).optional,
          tags?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::Array.of(Resources::Types::String)).optional,
          cost_categories?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::Array.of(Resources::Types::String)).optional,
          not?: Resources::Types::Hash.schema(
            dimensions?: Resources::Types::Hash.map(CostDimensionKey, Resources::Types::Array.of(Resources::Types::String)).optional,
            tags?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::Array.of(Resources::Types::String)).optional,
            cost_categories?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::Array.of(Resources::Types::String)).optional
          ).optional
        )

        # Budget notification subscriber
        BudgetSubscriber = Resources::Types::Hash.schema(
          subscription_type: BudgetSubscriberProtocol,
          address: Resources::Types::String.constructor { |value, context|
            protocol = context[:subscription_type] rescue nil

            case protocol
            when 'EMAIL'
              unless value.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
                raise Dry::Types::ConstraintError, "Email address format is invalid"
              end
            when 'SNS'
              unless value.match?(/\Aarn:aws:sns:[a-z0-9-]+:\d{12}:[a-zA-Z0-9-_]+\z/)
                raise Dry::Types::ConstraintError, "SNS topic ARN format is invalid"
              end
            end

            value
          }
        )

        # Budget notification configuration
        BudgetNotification = Resources::Types::Hash.schema(
          notification_type: BudgetNotificationType,
          comparison_operator: BudgetComparisonOperator,
          threshold: Resources::Types::Float.constructor { |value|
            if value <= 0
              raise Dry::Types::ConstraintError, "Budget notification threshold must be positive"
            end
            if value > 1_000_000
              raise Dry::Types::ConstraintError, "Budget notification threshold cannot exceed 1,000,000"
            end
            value
          },
          threshold_type?: BudgetThresholdType.default('PERCENTAGE').optional,
          subscribers?: Resources::Types::Array.of(BudgetSubscriber).constrained(max_size: 11).optional
        )

        # Planned budget limits for cost budgets
        BudgetPlannedBudgetLimits = Resources::Types::Hash.map(
          Resources::Types::String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/),
          BudgetSpend
        ).constructor do |value|
          dates = value.keys.sort
          dates.each_cons(2) do |prev_date, curr_date|
            prev_parsed = Date.parse(prev_date)
            curr_parsed = Date.parse(curr_date)

            if curr_parsed <= prev_parsed
              raise Dry::Types::ConstraintError, "Planned budget limit dates must be in chronological order"
            end
          end

          value
        rescue Date::Error
          raise Dry::Types::ConstraintError, "Planned budget limit dates must be in YYYY-MM-DD format"
        end

        # Auto-adjust data configuration
        BudgetAutoAdjustData = Resources::Types::Hash.schema(
          auto_adjust_type: Resources::Types::String.constrained(included_in: ['HISTORICAL', 'FORECAST']),
          historical_options?: Resources::Types::Hash.schema(
            budget_adjustment_period: Resources::Types::Integer.constrained(gteq: 1, lteq: 60),
            lookback_available_periods?: Resources::Types::Integer.constrained(gteq: 1, lteq: 60).optional
          ).optional
        ).constructor { |value|
          if value[:auto_adjust_type] == 'HISTORICAL' && !value[:historical_options]
            raise Dry::Types::ConstraintError, "Historical auto-adjust type requires historical_options"
          end
          value
        }
      end
    end
  end
end
