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
        # API Gateway Resource attributes with validation
        class ApiGatewayResourceAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute? :rest_api_id, Pangea::Resources::Types::String.optional
          attribute? :parent_id, Pangea::Resources::Types::String.optional
          attribute? :path_part, Pangea::Resources::Types::String.optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes.transform_keys(&:to_sym) : (attributes.nil? ? {} : attributes.to_h.transform_keys(&:to_sym))

            # Validate required attributes
            unless attrs[:rest_api_id] && !attrs[:rest_api_id].to_s.empty?
              raise Dry::Struct::Error, "rest_api_id is required"
            end

            unless attrs[:parent_id] && !attrs[:parent_id].to_s.empty?
              raise Dry::Struct::Error, "parent_id is required"
            end

            unless attrs[:path_part] && !attrs[:path_part].to_s.empty?
              raise Dry::Struct::Error, "path_part is required"
            end

            # Validate path_part doesn't contain slashes
            if attrs[:path_part]
              if attrs[:path_part].include?('/')
                raise Dry::Struct::Error, "Path part cannot contain slashes. Use separate resources for nested paths."
              end

              # Check for greedy path variable first (must be the full segment, e.g. {proxy+})
              if attrs[:path_part].include?('+}') && !attrs[:path_part].match?(/^\{[\w\-]+\+\}$/)
                raise Dry::Struct::Error, "Greedy path variables (+) must use the full segment: {proxy+}"
              end

              # Validate path_part follows API Gateway constraints
              # Must be alphanumeric, hyphens, underscores, or parameter brackets
              unless attrs[:path_part].match?(/^([\w\-]+|\{[\w\-]+\+?\})$/)
                raise Dry::Struct::Error, "Path part must be alphanumeric with hyphens/underscores or a parameter in brackets like {id} or {proxy+}"
              end
            end

            super(attrs)
          end
          
          # Computed properties
          def is_path_parameter?
            path_part.start_with?('{') && path_part.end_with?('}')
          end
          
          def is_greedy_parameter?
            path_part.end_with?('+}')
          end
          
          def parameter_name
            return nil unless is_path_parameter?
            path_part.gsub(/[{}+]/, '')
          end
          
          def requires_request_validator?
            is_path_parameter?
          end
          
          # Common path patterns
          def self.common_path_parts
            {
              items: "items",                    # Collection resource
              item_id: "{id}",                  # Single item by ID
              users: "users",                   # Users collection
              user_id: "{userId}",             # Single user
              version: "v1",                   # API version
              proxy: "{proxy+}",               # Proxy all sub-paths
              action: "{action}",              # Dynamic action
              resource: "{resource}",          # Dynamic resource type
              search: "search",                # Search endpoint
              health: "health",                # Health check
              metrics: "metrics",              # Metrics endpoint
              webhooks: "webhooks",            # Webhook receiver
              batch: "batch",                  # Batch operations
              export: "export",                # Export endpoint
              import: "import"                 # Import endpoint
            }
          end
          
          # Path validation helpers
          def self.validate_path_hierarchy(resources)
            # Validate that parent resources exist before children
            path_map = {}
            
            resources.each do |resource|
              if resource[:parent_id] && !path_map[resource[:parent_id]]
                raise "Parent resource #{resource[:parent_id]} not found for #{resource[:path_part]}"
              end
              path_map[resource[:id]] = resource
            end
            
            true
          end
          
          # Generate full path from resource hierarchy
          def self.build_full_path(resource_id, resource_map)
            path_parts = []
            current = resource_map[resource_id]
            
            while current
              # Skip empty path parts (like root resource)
              path_parts.unshift(current[:path_part]) unless current[:path_part].empty?
              current = current[:parent_id] ? resource_map[current[:parent_id]] : nil
            end
            
            "/#{path_parts.join('/')}"
          end
        end
      end
    end
  end
end