# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Password policy configuration for user pool
        class CognitoUserPoolPasswordPolicy < Pangea::Resources::BaseAttributes
          attribute :minimum_length, Resources::Types::Integer.default(8).constrained(gteq: 6, lteq: 99)
          attribute? :require_lowercase, Resources::Types::Bool.optional
          attribute? :require_numbers, Resources::Types::Bool.optional
          attribute? :require_symbols, Resources::Types::Bool.optional
          attribute? :require_uppercase, Resources::Types::Bool.optional
          attribute? :temporary_password_validity_days, Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 365)
        end

        # MFA configuration for user pool
        class CognitoUserPoolMfaConfiguration < Pangea::Resources::BaseAttributes
          attribute :mfa, Resources::Types::String.constrained(included_in: ['ON', 'OFF', 'OPTIONAL']).default('OFF')
          attribute? :sms_configuration, Resources::Types::Hash.schema(external_id?: Resources::Types::String.optional, sns_caller_arn: Resources::Types::String).lax.optional
          attribute? :software_token_mfa_configuration, Resources::Types::Hash.schema(enabled: Resources::Types::Bool).lax.optional
        end

        # User pool device configuration
        class CognitoUserPoolDeviceConfiguration < Pangea::Resources::BaseAttributes
          attribute? :challenge_required_on_new_device, Resources::Types::Bool.optional
          attribute? :device_only_remembered_on_user_prompt, Resources::Types::Bool.optional
        end

        # Email configuration for user pool
        class CognitoUserPoolEmailConfiguration < Pangea::Resources::BaseAttributes
          attribute? :configuration_set, Resources::Types::String.optional
          attribute :email_sending_account, Resources::Types::String.constrained(included_in: ['COGNITO_DEFAULT', 'DEVELOPER']).default('COGNITO_DEFAULT')
          attribute? :from_email_address, Resources::Types::String.optional
          attribute? :reply_to_email_address, Resources::Types::String.optional
          attribute? :source_arn, Resources::Types::String.optional
        end

        # SMS configuration for user pool
        class CognitoUserPoolSmsConfiguration < Pangea::Resources::BaseAttributes
          attribute? :external_id, Resources::Types::String.optional
          attribute? :sns_caller_arn, Resources::Types::String.optional
          attribute? :sns_region, Resources::Types::String.optional
        end

        # Lambda configuration triggers
        class CognitoUserPoolLambdaConfig < Pangea::Resources::BaseAttributes
          attribute? :create_auth_challenge, Resources::Types::String.optional
          attribute? :custom_message, Resources::Types::String.optional
          attribute? :define_auth_challenge, Resources::Types::String.optional
          attribute? :post_authentication, Resources::Types::String.optional
          attribute? :post_confirmation, Resources::Types::String.optional
          attribute? :pre_authentication, Resources::Types::String.optional
          attribute? :pre_sign_up, Resources::Types::String.optional
          attribute? :pre_token_generation, Resources::Types::String.optional
          attribute? :user_migration, Resources::Types::String.optional
          attribute? :verify_auth_challenge_response, Resources::Types::String.optional
          attribute? :kms_key_id, Resources::Types::String.optional
        end

        # User pool schema attribute
        class CognitoUserPoolSchemaAttribute < Pangea::Resources::BaseAttributes
          attribute? :attribute_data_type, Resources::Types::String.constrained(included_in: ['String', 'Number', 'DateTime', 'Boolean']).optional
          attribute? :name, Resources::Types::String.optional
          attribute? :developer_only_attribute, Resources::Types::Bool.optional
          attribute? :mutable, Resources::Types::Bool.optional
          attribute? :required, Resources::Types::Bool.optional
          attribute? :number_attribute_constraints, Resources::Types::Hash.schema(max_value?: Resources::Types::String.optional, min_value?: Resources::Types::String.optional).lax.optional
          attribute? :string_attribute_constraints, Resources::Types::Hash.schema(max_length?: Resources::Types::String.optional, min_length?: Resources::Types::String.optional).lax.optional
        end

        # User attribute update settings
        class CognitoUserPoolUserAttributeUpdateSettings < Pangea::Resources::BaseAttributes
          attribute? :attributes_require_verification_before_update, Resources::Types::Array.of(Resources::Types::String.constrained(included_in: ['phone_number', 'email'])).optional
        end

        # User pool verification message template
        class CognitoUserPoolVerificationMessageTemplate < Pangea::Resources::BaseAttributes
          attribute? :default_email_option, Resources::Types::String.constrained(included_in: ['CONFIRM_WITH_LINK', 'CONFIRM_WITH_CODE']).optional
          attribute? :email_message, Resources::Types::String.optional
          attribute? :email_message_by_link, Resources::Types::String.optional
          attribute? :email_subject, Resources::Types::String.optional
          attribute? :email_subject_by_link, Resources::Types::String.optional
          attribute? :sms_message, Resources::Types::String.optional
        end

        # Account recovery setting
        class CognitoUserPoolAccountRecoverySetting < Pangea::Resources::BaseAttributes
          attribute? :recovery_mechanisms, Resources::Types::Array.of(
            Resources::Types::Hash.schema(name: Resources::Types::String.constrained(included_in: ['verified_email', 'verified_phone_number', 'admin_only']).lax, priority: Resources::Types::Integer.constrained(gteq: 1, lteq: 2))
          ).constrained(min_size: 1, max_size: 2)
        end

        # Admin create user config
        class CognitoUserPoolAdminCreateUserConfig < Pangea::Resources::BaseAttributes
          attribute? :allow_admin_create_user_only, Resources::Types::Bool.optional
          attribute? :invite_message_template, Resources::Types::Hash.schema(email_message?: Resources::Types::String.optional, email_subject?: Resources::Types::String.optional, sms_message?: Resources::Types::String.optional).lax.optional
          attribute? :unused_account_validity_days, Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 365)
        end

        # User pool add-ons configuration
        class CognitoUserPoolUserPoolAddOns < Pangea::Resources::BaseAttributes
          attribute? :advanced_security_mode, Resources::Types::String.constrained(included_in: ['OFF', 'AUDIT', 'ENFORCED']).optional
        end
      end
    end
  end
end
