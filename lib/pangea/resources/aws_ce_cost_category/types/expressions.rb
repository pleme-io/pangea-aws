# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS

      module Types
        # Cost category rule types
        CostCategoryRuleType = Resources::Types::String.constrained(included_in: ['REGULAR', 'INHERITED'])

        # Cost category split charge rule methods
        SplitChargeMethod = Resources::Types::String.constrained(included_in: ['FIXED', 'PROPORTIONAL', 'EVEN'])

        # Cost category dimension key types
        CostCategoryDimensionKey = Resources::Types::String.constrained(included_in: ['AZ', 'INSTANCE_TYPE', 'LINKED_ACCOUNT', 'LINKED_ACCOUNT_NAME', 'OPERATION',
          'PURCHASE_TYPE', 'REGION', 'SERVICE', 'SERVICE_CODE', 'USAGE_TYPE',
          'USAGE_TYPE_GROUP', 'RECORD_TYPE', 'OPERATING_SYSTEM', 'TENANCY',
          'SCOPE', 'PLATFORM', 'SUBSCRIPTION_ID', 'LEGAL_ENTITY_NAME',
          'DEPLOYMENT_OPTION', 'DATABASE_ENGINE', 'CACHE_ENGINE',
          'INSTANCE_TYPE_FAMILY', 'BILLING_ENTITY', 'RESERVATION_ID',
          'RESOURCE_ID', 'RIGHTSIZING_TYPE', 'SAVINGS_PLANS_TYPE',
          'SAVINGS_PLAN_ARN', 'PAYMENT_OPTION'])

        # Match options for cost category filters
        CostCategoryMatchOptions = Resources::Types::String.constrained(included_in: ['EQUALS', 'ABSENT', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS',
          'CASE_SENSITIVE', 'CASE_INSENSITIVE'])

        # Cost category dimension filter
        CostCategoryDimensionFilter = Resources::Types::Hash.schema(
          key: CostCategoryDimensionKey,
          values: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 10000),
          match_options?: Resources::Types::Array.of(CostCategoryMatchOptions).constrained(max_size: 1).optional
        ).lax

        # Cost category tag filter
        CostCategoryTagFilter = Resources::Types::Hash.schema(
          key: Resources::Types::String.constrained(min_size: 1, max_size: 128),
          values?: Resources::Types::Array.of(Resources::Types::String).constrained(max_size: 1000).optional,
          match_options?: Resources::Types::Array.of(CostCategoryMatchOptions).constrained(max_size: 1).optional
        ).lax

        # Cost category cost category filter (for nested categories)
        CostCategoryCostCategoryFilter = Resources::Types::Hash.schema(
          key: Resources::Types::String.constrained(min_size: 1, max_size: 50),
          values: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 20),
          match_options?: Resources::Types::Array.of(CostCategoryMatchOptions).constrained(max_size: 1).optional
        ).lax

        # Cost category expression for complex filtering
        CostCategoryExpression = Resources::Types::Hash.schema(
          and?: Resources::Types::Array.of(Resources::Types::Hash).optional,
          or?: Resources::Types::Array.of(Resources::Types::Hash).optional,
          not?: Resources::Types::Hash.optional,
          dimension?: CostCategoryDimensionFilter.optional,
          tags?: CostCategoryTagFilter.optional,
          cost_category?: CostCategoryCostCategoryFilter.optional
        ).constructor { |value|
          expression_types = [:and, :or, :not, :dimension, :tags, :cost_category]
          specified_types = expression_types.select { |type| value.key?(type) && value[type] }

          if specified_types.empty?
            raise Dry::Types::ConstraintError, "Cost category expression must specify at least one condition"
          end

          if value[:and] && value[:and].size < 2
            raise Dry::Types::ConstraintError, "AND expression must have at least 2 conditions"
          end

          if value[:or] && value[:or].size < 2
            raise Dry::Types::ConstraintError, "OR expression must have at least 2 conditions"
          end

          value
        }

        # Cost category rule definition

        # Cost category split charge rule
        CostCategorySplitChargeRule = Resources::Types::Hash.schema(
          source: Resources::Types::String.constrained(min_size: 1, max_size: 50),
          targets: Resources::Types::Array.of(Resources::Types::String.constrained(min_size: 1, max_size: 50)).constrained(min_size: 1, max_size: 500),
          method: SplitChargeMethod,
          parameters?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              type: Resources::Types::String.constrained(included_in: ['ALLOCATION_PERCENTAGES']),
              values: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)
            ).lax
          ).constrained(max_size: 10).optional
        ).constructor { |value|
          case value[:method]
          when 'FIXED', 'PROPORTIONAL'
            if value[:parameters].nil? || value[:parameters].empty?
              raise Dry::Types::ConstraintError, "#{value[:method]} split charge method requires parameters"
            end

            if value[:method] == 'FIXED'
              percentages = value[:parameters].first[:values].map(&:to_f)
              total_percentage = percentages.sum

              unless (total_percentage - 100.0).abs < 0.01
                raise Dry::Types::ConstraintError, "FIXED split charge percentages must sum to 100%"
              end

              if percentages.size != value[:targets].size
                raise Dry::Types::ConstraintError, "FIXED split charge must have one percentage per target"
              end
            end

          when 'EVEN'
            if value[:parameters] && !value[:parameters].empty?
              raise Dry::Types::ConstraintError, "EVEN split charge method should not have parameters"
            end
          end

          if value[:targets].include?(value[:source])
            raise Dry::Types::ConstraintError, "Split charge source cannot be in targets list"
          end

          if value[:targets].size != value[:targets].uniq.size
            raise Dry::Types::ConstraintError, "Split charge targets must be unique"
          end

          value
        }

        # Cost category rule definition
        CostCategoryRule = Resources::Types::Hash.schema(
          value: Resources::Types::String.constrained(min_size: 1, max_size: 50).constructor { |value|
            unless value.match?(/\A[a-zA-Z0-9\s\-_\.]+\z/)
              raise Dry::Types::ConstraintError, "Cost category value must contain only alphanumeric characters, spaces, hyphens, underscores, and periods"
            end
            value.strip
          },
          rule: CostCategoryExpression,
          type?: CostCategoryRuleType.default('REGULAR').optional,
          inherited_value?: Resources::Types::Hash.schema(
            dimension_key?: CostCategoryDimensionKey.optional,
            dimension_name?: Resources::Types::String.optional
          ).lax.optional
        ).constructor { |value|
          if value[:type] == 'INHERITED' && !value[:inherited_value]
            raise Dry::Types::ConstraintError, "INHERITED rule type requires inherited_value configuration"
          end

          if value[:type] == 'REGULAR' && value[:inherited_value]
            raise Dry::Types::ConstraintError, "REGULAR rule type cannot have inherited_value configuration"
          end

          value
        }

      end
    end
  end
end
