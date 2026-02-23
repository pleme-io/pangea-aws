# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'json'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS IAM Policy resources
        class IamPolicyAttributes < Pangea::Resources::BaseAttributes
          extend Pangea::Resources::AWS::Types::PolicyTemplates
          transform_keys(&:to_sym)

          attribute? :name, Resources::Types::String.optional
          attribute :path, Resources::Types::String.default('/')
          attribute? :description, Resources::Types::String.optional
          attribute? :policy, Resources::Types::Hash.schema(
            Version: Resources::Types::String.default('2012-10-17'),
            Statement: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                Sid?: Resources::Types::String.optional,
                Effect: Resources::Types::String.constrained(included_in: ['Allow', 'Deny']),
                Action: Resources::Types::String | Resources::Types::Array.of(Resources::Types::String),
                Resource: Resources::Types::String | Resources::Types::Array.of(Resources::Types::String),
                Condition?: Resources::Types::Hash.optional,
                Principal?: Resources::Types::Hash.optional,
                NotAction?: Resources::Types::String | Resources::Types::Array.of(Resources::Types::String),
                NotResource?: Resources::Types::String | Resources::Types::Array.of(Resources::Types::String),
                NotPrincipal?: Resources::Types::Hash.optional
              ).lax
            )
          )
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'Policy name cannot exceed 128 characters' if attrs.name.length > 128
            raise Dry::Struct::Error, "Path must start and end with '/' and contain only valid characters" unless attrs.path.match?(/\A\/[\w+=,.@-]*\/?\z/)
            raise Dry::Struct::Error, 'Path cannot exceed 512 characters' if attrs.path.length > 512
            raise Dry::Struct::Error, 'Policy document must have at least one statement' if attrs.policy&.dig(:Statement).empty?

            attrs.validate_policy_security!
            policy_json = ::JSON.generate(attrs.policy)
            raise Dry::Struct::Error, 'Policy document cannot exceed 6144 characters' if policy_json.length > 6144

            attrs
          end

          def uses_reserved_name? = name.start_with?('AWS') || name.include?('Amazon')

          def all_actions
            policy&.dig(:Statement).flat_map { |s| Array(s[:Action]) }.uniq
          end

          def all_resources
            policy&.dig(:Statement).flat_map { |s| Array(s[:Resource]) }.uniq
          end

          def allows_action?(action)
            policy&.dig(:Statement).any? do |s|
              s[:Effect] == 'Allow' &&
                (s[:Action] == action || Array(s[:Action]).include?(action) || s[:Action] == '*' ||
                 (s[:Action].is_a?(String) && s[:Action].end_with?('*') && action.start_with?(s[:Action][0...-1])))
            end
          end

          def has_wildcard_permissions?
            policy&.dig(:Statement).any? { |s| s[:Effect] == 'Allow' && (s[:Action] == '*' || s[:Resource] == '*') }
          end

          def security_level
            return :high_risk if has_wildcard_permissions?
            return :medium_risk if allows_action?('iam:*') || allows_action?('sts:AssumeRole')

            :low_risk
          end

          def validate_policy_security!
            warnings = []
            warnings << 'Policy contains wildcard (*) permissions - consider principle of least privilege' if has_wildcard_permissions?
            %w[iam:* iam:CreateRole iam:AttachRolePolicy iam:PutRolePolicy].each do |action|
              warnings << "Policy allows potentially dangerous action: #{action}" if allows_action?(action)
            end
            warnings << 'Policy grants access to root resources - review necessity' if all_resources.any? { |r| r.end_with?(':root') || r == '*' }

            return if warnings.empty?

            puts "IAM Policy Security Warnings for '#{name}':"
            warnings.each { |warning| puts "  - #{warning}" }
          end

          def complexity_score
            statements_count = policy&.dig(:Statement).length
            actions_count = all_actions.length
            resources_count = all_resources.length
            conditions_count = policy&.dig(:Statement).count { |s| s[:Condition] }
            statements_count + actions_count + resources_count + (conditions_count * 2)
          end

          def service_role_policy?
            all_actions.any? { |action| action.start_with?('sts:AssumeRole') }
          end
        end

        # Common IAM policy document structure
        class IamPolicyDocument < Pangea::Resources::BaseAttributes
          attribute :Version, Resources::Types::String.default('2012-10-17')
          attribute? :Statement, Resources::Types::Array.of(
            Resources::Types::Hash.schema(Sid?: Resources::Types::String.optional, Effect: Resources::Types::String.constrained(included_in: ['Allow', 'Deny']).lax, Action: Resources::Types::String | Resources::Types::Array.of(Resources::Types::String), Resource: Resources::Types::String | Resources::Types::Array.of(Resources::Types::String), Condition?: Resources::Types::Hash.optional)
          )
        end
      end
    end
  end
end
