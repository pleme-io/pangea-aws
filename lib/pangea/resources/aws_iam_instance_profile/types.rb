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
        # Type-safe attributes for AWS IAM Instance Profile resources
        class IamInstanceProfileAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          # Instance profile name (optional, AWS will generate if not provided)
          attribute? :name, Resources::Types::String.optional

          # Instance profile name prefix (optional, alternative to name)
          attribute? :name_prefix, Resources::Types::String.optional

          # Path for the instance profile (default: "/")
          attribute :path, Resources::Types::String.default("/")

          # IAM role to associate with the instance profile
          # Can be a role name string or a Terraform reference
          attribute :role, Resources::Types::String

          # Tags to apply to the instance profile
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Cannot specify both name and name_prefix
            if attrs.name && attrs.name_prefix
              raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'"
            end

            attrs
          end
        end
      end
    end
  end
end
