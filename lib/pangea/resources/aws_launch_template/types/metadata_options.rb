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
        # Instance metadata options for launch template (IMDSv2 enforcement)
        class MetadataOptions < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          attribute :http_endpoint, Resources::Types::String.default('enabled').enum('enabled', 'disabled')
          attribute :http_tokens, Resources::Types::String.default('optional').enum('optional', 'required')
          attribute :http_put_response_hop_limit, Resources::Types::Integer.default(1)
          attribute :instance_metadata_tags, Resources::Types::String.default('disabled').enum('enabled', 'disabled')

          def to_h
            {
              http_endpoint: http_endpoint,
              http_tokens: http_tokens,
              http_put_response_hop_limit: http_put_response_hop_limit,
              instance_metadata_tags: instance_metadata_tags
            }
          end
        end
      end
    end
  end
end
