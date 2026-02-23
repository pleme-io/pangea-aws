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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types

      # Pre-configured user templates
      module UserTemplates
        module_function
        # Standard user with email
        def email_user(username, user_pool_id, email, name = nil, temporary_password = nil)
          attrs = {
            'email' => email,
            'email_verified' => 'true'
          }
          attrs['name'] = name if name

          {
            username: username,
            user_pool_id: user_pool_id,
            attributes: attrs,
            temporary_password: temporary_password,
            desired_delivery_mediums: ['EMAIL']
          }
        end

        # Admin user with elevated attributes
        def admin_user(username, user_pool_id, email, name, temporary_password = nil)
          {
            username: username,
            user_pool_id: user_pool_id,
            attributes: {
              'email' => email,
              'email_verified' => 'true',
              'name' => name,
              'custom:role' => 'admin',
              'custom:created_by' => 'system'
            },
            temporary_password: temporary_password,
            desired_delivery_mediums: ['EMAIL'],
            force_alias_creation: true
          }
        end
      end

      # User attribute configuration
      class CognitoUserAttribute < Pangea::Resources::BaseAttributes
        attribute? :name, Resources::Types::String.optional
        attribute? :value, Resources::Types::String.optional
      end

      # Type-safe attributes for AWS Cognito User resources
      class CognitoUserAttributes < Pangea::Resources::BaseAttributes
          extend Pangea::Resources::AWS::Types::UserTemplates
        # Username (required)
        attribute? :username, Resources::Types::String.optional

        # User pool ID (required)
        attribute? :user_pool_id, Resources::Types::String.optional

        # User attributes
        attribute :attributes, Resources::Types::Hash.default({}.freeze)

        # Temporary password for user
        attribute? :temporary_password, Resources::Types::String.optional

        # Whether to force password change on first login
        attribute :force_alias_creation, Resources::Types::Bool.default(false)

        # Message action for user creation
        attribute? :message_action, Resources::Types::String.constrained(included_in: ['RESEND', 'SUPPRESS']).optional

        # Desired delivery mediums
        attribute? :desired_delivery_mediums, Resources::Types::Array.of(Resources::Types::String.constrained(included_in: ['SMS', 'EMAIL'])).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate username format
          unless attrs.username.match?(/\A[\w\.\-@]+\z/)
            raise Dry::Struct::Error, "Username can only contain word characters, periods, hyphens, and at symbols"
          end

          # Validate email format if provided in attributes
          user_attrs = attrs[:attributes]
          if user_attrs && user_attrs.dig('email')
            email = user_attrs.dig('email')
            unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
              raise Dry::Struct::Error, "Invalid email format in user attributes"
            end
          end

          attrs
        end

        # Access the user attributes hash (avoid conflict with Dry::Struct#attributes)
        def user_attributes
          self[:attributes]
        end

        # Check if user has email attribute
        def has_email?
          user_attributes&.key?('email')
        end

        # Check if user has phone number
        def has_phone_number?
          user_attributes&.key?('phone_number')
        end

        # Check if user has custom attributes
        def has_custom_attributes?
          return false unless user_attributes

          user_attributes.keys.any? { |key| key.to_s.start_with?('custom:') }
        end

        # Get custom attributes only
        def custom_attributes
          return {} unless user_attributes

          user_attributes.select { |key, _| key.to_s.start_with?('custom:') }
        end

        # Get standard attributes only
        def standard_attributes
          return {} unless user_attributes

          user_attributes.reject { |key, _| key.to_s.start_with?('custom:') }
        end
      end

    end
      end
    end
  end
