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

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cognito_user_pool/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User Pool with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user pool attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user_pool(name, attributes = {})
        user_pool_attrs = Types::CognitoUserPoolAttributes.new(attributes)

        # Build resource attributes as a hash
        resource_attrs = {}

        resource_attrs[:pool_name] = user_pool_attrs.name if user_pool_attrs.name
        resource_attrs[:auto_verified_attributes] = user_pool_attrs.auto_verified_attributes if user_pool_attrs.auto_verified_attributes

        # Username config
        resource_attrs[:alias_attributes] = user_pool_attrs.alias_attributes if user_pool_attrs.alias_attributes
        resource_attrs[:username_attributes] = user_pool_attrs.username_attributes if user_pool_attrs.username_attributes
        if user_pool_attrs.username_configuration
          resource_attrs[:username_configuration] = {
            case_sensitive: user_pool_attrs.username_configuration[:case_sensitive]
          }
        end

        # Password policy
        if user_pool_attrs.password_policy
          policy = user_pool_attrs.password_policy
          pp = { minimum_length: policy.minimum_length }
          pp[:require_lowercase] = policy.require_lowercase if policy.require_lowercase
          pp[:require_numbers] = policy.require_numbers if policy.require_numbers
          pp[:require_symbols] = policy.require_symbols if policy.require_symbols
          pp[:require_uppercase] = policy.require_uppercase if policy.require_uppercase
          pp[:temporary_password_validity_days] = policy.temporary_password_validity_days if policy.temporary_password_validity_days
          resource_attrs[:password_policy] = pp
        end

        # MFA config
        resource_attrs[:mfa_configuration] = user_pool_attrs.mfa_configuration
        resource_attrs[:sms_authentication_message] = user_pool_attrs.sms_authentication_message if user_pool_attrs.sms_authentication_message

        if user_pool_attrs.sms_configuration
          config = user_pool_attrs.sms_configuration
          sms = {}
          sms[:external_id] = config.external_id if config.external_id
          sms[:sns_caller_arn] = config.sns_caller_arn if config.sns_caller_arn
          sms[:sns_region] = config.sns_region if config.sns_region
          resource_attrs[:sms_configuration] = sms
        end

        if user_pool_attrs.software_token_mfa_configuration
          resource_attrs[:software_token_mfa_configuration] = {
            enabled: user_pool_attrs.software_token_mfa_configuration[:enabled]
          }
        end

        # Device configuration
        if user_pool_attrs.device_configuration
          config = user_pool_attrs.device_configuration
          dc = {}
          dc[:challenge_required_on_new_device] = config.challenge_required_on_new_device if config.challenge_required_on_new_device
          dc[:device_only_remembered_on_user_prompt] = config.device_only_remembered_on_user_prompt if config.device_only_remembered_on_user_prompt
          resource_attrs[:device_configuration] = dc
        end

        # Email configuration
        if user_pool_attrs.email_configuration
          config = user_pool_attrs.email_configuration
          ec = { email_sending_account: config.email_sending_account }
          ec[:configuration_set] = config.configuration_set if config.configuration_set
          ec[:from_email_address] = config.from_email_address if config.from_email_address
          ec[:reply_to_email_address] = config.reply_to_email_address if config.reply_to_email_address
          ec[:source_arn] = config.source_arn if config.source_arn
          resource_attrs[:email_configuration] = ec
        end

        resource_attrs[:email_verification_message] = user_pool_attrs.email_verification_message if user_pool_attrs.email_verification_message
        resource_attrs[:email_verification_subject] = user_pool_attrs.email_verification_subject if user_pool_attrs.email_verification_subject
        resource_attrs[:sms_verification_message] = user_pool_attrs.sms_verification_message if user_pool_attrs.sms_verification_message

        # Lambda config
        if user_pool_attrs.lambda_config
          config = user_pool_attrs.lambda_config
          lc = {}
          lc[:create_auth_challenge] = config.create_auth_challenge if config.create_auth_challenge
          lc[:custom_message] = config.custom_message if config.custom_message
          lc[:define_auth_challenge] = config.define_auth_challenge if config.define_auth_challenge
          lc[:post_authentication] = config.post_authentication if config.post_authentication
          lc[:post_confirmation] = config.post_confirmation if config.post_confirmation
          lc[:pre_authentication] = config.pre_authentication if config.pre_authentication
          lc[:pre_sign_up] = config.pre_sign_up if config.pre_sign_up
          lc[:pre_token_generation] = config.pre_token_generation if config.pre_token_generation
          lc[:user_migration] = config.user_migration if config.user_migration
          lc[:verify_auth_challenge_response] = config.verify_auth_challenge_response if config.verify_auth_challenge_response
          lc[:kms_key_id] = config.kms_key_id if config.kms_key_id
          resource_attrs[:lambda_config] = lc
        end

        # Schema attributes
        if user_pool_attrs.schema.any?
          resource_attrs[:schema] = user_pool_attrs.schema.map do |schema_attr|
            sa = {}
            sa[:attribute_data_type] = schema_attr.attribute_data_type if schema_attr.attribute_data_type
            sa[:name] = schema_attr.name if schema_attr.name
            sa[:developer_only_attribute] = schema_attr.developer_only_attribute if schema_attr.developer_only_attribute
            sa[:mutable] = schema_attr.mutable if schema_attr.mutable
            sa[:required] = schema_attr.required if schema_attr.required
            if schema_attr.number_attribute_constraints
              nc = {}
              nc[:max_value] = schema_attr.number_attribute_constraints[:max_value] if schema_attr.number_attribute_constraints[:max_value]
              nc[:min_value] = schema_attr.number_attribute_constraints[:min_value] if schema_attr.number_attribute_constraints[:min_value]
              sa[:number_attribute_constraints] = nc
            end
            if schema_attr.string_attribute_constraints
              sc = {}
              sc[:max_length] = schema_attr.string_attribute_constraints[:max_length] if schema_attr.string_attribute_constraints[:max_length]
              sc[:min_length] = schema_attr.string_attribute_constraints[:min_length] if schema_attr.string_attribute_constraints[:min_length]
              sa[:string_attribute_constraints] = sc
            end
            sa
          end
        end

        # User settings
        if user_pool_attrs.user_attribute_update_settings
          resource_attrs[:user_attribute_update_settings] = {
            attributes_require_verification_before_update: user_pool_attrs.user_attribute_update_settings.attributes_require_verification_before_update
          }
        end

        if user_pool_attrs.verification_message_template
          template = user_pool_attrs.verification_message_template
          vmt = {}
          vmt[:default_email_option] = template.default_email_option if template.default_email_option
          vmt[:email_message] = template.email_message if template.email_message
          vmt[:email_message_by_link] = template.email_message_by_link if template.email_message_by_link
          vmt[:email_subject] = template.email_subject if template.email_subject
          vmt[:email_subject_by_link] = template.email_subject_by_link if template.email_subject_by_link
          vmt[:sms_message] = template.sms_message if template.sms_message
          resource_attrs[:verification_message_template] = vmt
        end

        if user_pool_attrs.account_recovery_setting
          resource_attrs[:account_recovery_setting] = {
            recovery_mechanism: user_pool_attrs.account_recovery_setting.recovery_mechanisms.map do |mechanism|
              { name: mechanism[:name], priority: mechanism[:priority] }
            end
          }
        end

        if user_pool_attrs.admin_create_user_config
          config = user_pool_attrs.admin_create_user_config
          acuc = {}
          acuc[:allow_admin_create_user_only] = config.allow_admin_create_user_only if config.allow_admin_create_user_only
          acuc[:unused_account_validity_days] = config.unused_account_validity_days if config.unused_account_validity_days
          if config.invite_message_template
            imt = {}
            imt[:email_message] = config.invite_message_template[:email_message] if config.invite_message_template[:email_message]
            imt[:email_subject] = config.invite_message_template[:email_subject] if config.invite_message_template[:email_subject]
            imt[:sms_message] = config.invite_message_template[:sms_message] if config.invite_message_template[:sms_message]
            acuc[:invite_message_template] = imt
          end
          resource_attrs[:admin_create_user_config] = acuc
        end

        if user_pool_attrs.user_pool_add_ons
          resource_attrs[:user_pool_add_ons] = {
            advanced_security_mode: user_pool_attrs.user_pool_add_ons.advanced_security_mode
          }
        end

        resource_attrs[:deletion_protection] = user_pool_attrs.deletion_protection
        resource_attrs[:tags] = user_pool_attrs.tags if user_pool_attrs.tags.any?

        # Write to manifest: direct access for synthesizer, fall back to resource() for test mocks
        if is_a?(AbstractSynthesizer)
          translation[:manifest][:resource] ||= {}
          translation[:manifest][:resource][:aws_cognito_user_pool] ||= {}
          translation[:manifest][:resource][:aws_cognito_user_pool][name] = resource_attrs
        else
          resource(:aws_cognito_user_pool, name, resource_attrs)
        end

        build_cognito_resource_reference(name, user_pool_attrs)
      end

      private

      def build_cognito_resource_reference(name, attrs)
        ResourceReference.new(
          type: 'aws_cognito_user_pool',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: cognito_outputs(name),
          computed_properties: cognito_computed_properties(attrs)
        )
      end

      def cognito_outputs(name)
        {
          id: "${aws_cognito_user_pool.#{name}.id}",
          arn: "${aws_cognito_user_pool.#{name}.arn}",
          creation_date: "${aws_cognito_user_pool.#{name}.creation_date}",
          custom_domain: "${aws_cognito_user_pool.#{name}.custom_domain}",
          domain: "${aws_cognito_user_pool.#{name}.domain}",
          endpoint: "${aws_cognito_user_pool.#{name}.endpoint}",
          estimated_number_of_users: "${aws_cognito_user_pool.#{name}.estimated_number_of_users}",
          last_modified_date: "${aws_cognito_user_pool.#{name}.last_modified_date}",
          name: "${aws_cognito_user_pool.#{name}.name}"
        }
      end

      def cognito_computed_properties(attrs)
        {
          uses_email_auth: attrs.uses_email_auth?,
          uses_phone_auth: attrs.uses_phone_auth?,
          mfa_enabled: attrs.mfa_enabled?,
          mfa_optional: attrs.mfa_optional?,
          primary_auth_method: attrs.primary_auth_method,
          advanced_security_enabled: attrs.advanced_security_enabled?
        }
      end
    end
  end
end
