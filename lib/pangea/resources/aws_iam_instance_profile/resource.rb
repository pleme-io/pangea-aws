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
require 'pangea/resources/aws_iam_instance_profile/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IAM Instance Profile with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Instance profile attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iam_instance_profile(name, attributes = {})
        # Validate attributes using dry-struct
        profile_attrs = Types::IamInstanceProfileAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iam_instance_profile, name) do
          name profile_attrs.name if profile_attrs.name
          name_prefix profile_attrs.name_prefix if profile_attrs.name_prefix
          path profile_attrs.path if profile_attrs.path != "/"
          role profile_attrs.role

          # Apply tags if present
          if profile_attrs.tags&.any?
            tags do
              profile_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_iam_instance_profile',
          name: name,
          resource_attributes: profile_attrs.to_h,
          outputs: {
            id: "${aws_iam_instance_profile.#{name}.id}",
            arn: "${aws_iam_instance_profile.#{name}.arn}",
            name: "${aws_iam_instance_profile.#{name}.name}",
            unique_id: "${aws_iam_instance_profile.#{name}.unique_id}",
            create_date: "${aws_iam_instance_profile.#{name}.create_date}"
          }
        )
      end
    end
  end
end
