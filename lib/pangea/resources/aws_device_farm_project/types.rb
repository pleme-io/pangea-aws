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

require "dry-struct"
require 'pangea/resources/types'

module Pangea
  module Resources
    module AwsDeviceFarmProject
      module Types
        # Main attributes for Device Farm project
        unless const_defined?(:Attributes)
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Resources::Types::String
          
          # Optional attributes
          attribute :default_job_timeout_minutes?, Pangea::Resources::Types::Integer.constrained(gteq: 5, lteq: 150)
          attribute :tags?, Pangea::Resources::Types::Hash.map(Pangea::Resources::Types::String, Pangea::Resources::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Resources::Types::Hash[d]
            new(
              name: d.fetch(:name),
              default_job_timeout_minutes: d[:default_job_timeout_minutes],
              tags: d[:tags]
            )
          end
        end

        # Reference for Device Farm project resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Resources::Types::String
          attribute :arn, Pangea::Resources::Types::String
        end
      end
        end
    end
  end
end