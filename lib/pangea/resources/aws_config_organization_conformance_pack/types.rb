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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Config Organization Conformance Pack resource attributes
        class ConfigOrganizationConformancePackAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          # Attributes
          attribute? :name, Resources::Types::String.optional
          attribute? :template_s3_uri, Resources::Types::String.optional
          attribute? :template_body, Resources::Types::String.optional
          attribute? :delivery_s3_bucket, Resources::Types::String.optional
          attribute? :delivery_s3_key_prefix, Resources::Types::String.optional
          attribute? :excluded_accounts, Resources::Types::Array.optional
          attribute? :conformance_pack_input_parameters, Resources::Types::Array.optional

          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}
            super(attrs)
          end

          # Computed properties
          def template_source
            if template_s3_uri && !template_s3_uri.empty?
              's3'
            elsif template_body && !template_body.empty?
              'inline'
            end
          end

          def parameter_count
            if conformance_pack_input_parameters.is_a?(Array)
              conformance_pack_input_parameters.length
            else
              0
            end
          end

          def to_h
            hash = {
              name: name
            }

            hash[:template_s3_uri] = template_s3_uri if template_s3_uri
            hash[:template_body] = template_body if template_body
            hash[:delivery_s3_bucket] = delivery_s3_bucket if delivery_s3_bucket
            hash[:delivery_s3_key_prefix] = delivery_s3_key_prefix if delivery_s3_key_prefix
            hash[:excluded_accounts] = excluded_accounts if excluded_accounts
            hash[:conformance_pack_input_parameters] = conformance_pack_input_parameters if conformance_pack_input_parameters

            hash.compact
          end
        end
      end
    end
  end
end
