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
        # Type-safe attributes for AWS IAM User resources
        class IamUserAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          # User name (required)
          attribute? :name, Resources::Types::String.optional

          # Path for the user (default: "/")
          attribute :path, Resources::Types::String.default('/')

          # Permissions boundary ARN
          attribute? :permissions_boundary, Resources::Types::String.optional

          # Force destroy user on deletion (removes dependencies)
          attribute :force_destroy, Resources::Types::Bool.default(false)

          # Tags to apply to the user
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes.transform_keys(&:to_sym) : attributes.to_h.transform_keys(&:to_sym)

            # Validate name format (alphanumeric, hyphens, underscores, dots, @, +, =, comma)
            if attrs[:name] && !Pangea::Resources::BaseAttributes.terraform_reference?(attrs[:name])
              unless attrs[:name] =~ /\A[\w+=,.@-]+\z/
                raise Dry::Struct::Error, "IAM user name must contain only alphanumeric characters, plus (+), equal (=), comma (,), period (.), at (@), underscore (_), and hyphen (-)"
              end

              if attrs[:name].length > 64
                raise Dry::Struct::Error, "IAM user name cannot exceed 64 characters"
              end
            end

            # Validate path format
            if attrs[:path] && !Pangea::Resources::BaseAttributes.terraform_reference?(attrs[:path])
              unless attrs[:path].start_with?('/')
                raise Dry::Struct::Error, "IAM user path must start with /"
              end

              if attrs[:path].length > 512
                raise Dry::Struct::Error, "IAM user path cannot exceed 512 characters"
              end
            end

            # Validate permissions boundary ARN format
            if attrs[:permissions_boundary] && !Pangea::Resources::BaseAttributes.terraform_reference?(attrs[:permissions_boundary])
              unless attrs[:permissions_boundary] =~ /\Aarn:aws:iam::[0-9]*:policy\//
                raise Dry::Struct::Error, "permissions_boundary must be a valid IAM policy ARN"
              end
            end

            instance = super(attrs)

            # Security warnings
            if instance.name
              # Warn about admin users without permissions boundary
              if instance.name =~ /admin/i && instance.permissions_boundary.nil?
                $stdout.puts "[WARN] IAM user '#{instance.name}' should have a permissions boundary"
              end

              # Warn about unsafe user names
              if %w[root administrator].include?(instance.name.downcase)
                $stdout.puts "[WARN] IAM user '#{instance.name}' matches common attack targets"
              end

              # Warn about users in root path
              if instance.path == '/' && instance.permissions_boundary.nil? && !instance.name.downcase.include?('admin') && !%w[root administrator].include?(instance.name.downcase)
                $stdout.puts "[WARN] IAM user '#{instance.name}' - consider organizational path structure"
              end
            end

            instance
          end
        end
      end
    end
  end
end
