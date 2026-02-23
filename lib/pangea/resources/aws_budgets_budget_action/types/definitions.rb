# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        BudgetActionType = Resources::Types::String.constrained(included_in: ['APPLY_IAM_POLICY', 'APPLY_SCP_POLICY', 'RUN_SSM_DOCUMENTS'])
        BudgetActionStatus = Resources::Types::String.constrained(included_in: ['STANDBY', 'PENDING', 'EXECUTION_IN_PROGRESS', 'EXECUTION_SUCCESS', 'EXECUTION_FAILURE', 'REVERSE_IN_PROGRESS', 'REVERSE_SUCCESS', 'REVERSE_FAILURE', 'RESET'])
        ActionNotificationType = Resources::Types::String.constrained(included_in: ['ACTUAL', 'FORECASTED'])
        BudgetActionApprovalModel = Resources::Types::String.constrained(included_in: ['AUTOMATIC', 'MANUAL'])

        ActionSubscriber = Resources::Types::Hash.schema(
          subscription_type: Resources::Types::String.constrained(included_in: ['EMAIL', 'SNS']),
          address: Resources::Types::String
        ).lax

        BudgetIamPolicyDefinition = Resources::Types::Hash.schema(
          policy_arn: Resources::Types::String,
          roles?: Resources::Types::Array.of(Resources::Types::String).optional,
          groups?: Resources::Types::Array.of(Resources::Types::String).optional,
          users?: Resources::Types::Array.of(Resources::Types::String).optional
        ).lax

        BudgetScpPolicyDefinition = Resources::Types::Hash.schema(
          policy_id: Resources::Types::String,
          target_ids: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 20)
        ).lax

        BudgetSsmParameter = Resources::Types::Hash.schema(
          name: Resources::Types::String.constrained(format: /\A[a-zA-Z0-9_.-]{1,128}\z/),
          value: Resources::Types::String.constrained(max_size: 4096)
        ).lax

        BudgetSsmDocumentDefinition = Resources::Types::Hash.schema(
          ssm_action_type: Resources::Types::String.constrained(included_in: ['START_EC2_INSTANCES', 'STOP_EC2_INSTANCES', 'START_RDS_INSTANCES', 'STOP_RDS_INSTANCES']),
          region: Resources::Types::AwsRegion,
          instance_ids?: Resources::Types::Array.of(Resources::Types::String).constrained(max_size: 50).optional,
          parameters?: Resources::Types::Array.of(BudgetSsmParameter).constrained(max_size: 100).optional
        ).lax

        BudgetActionDefinition = Resources::Types::Hash.schema(
          iam_action_definition?: BudgetIamPolicyDefinition.optional,
          scp_action_definition?: BudgetScpPolicyDefinition.optional,
          ssm_action_definition?: BudgetSsmDocumentDefinition.optional
        ).lax

        BudgetActionExecutionRole = Resources::Types::String.constrained(format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9+=,.@_-]+\z/)
      end
    end
  end
end
