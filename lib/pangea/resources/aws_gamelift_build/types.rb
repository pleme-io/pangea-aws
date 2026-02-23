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
    module AwsGameliftBuild
      module Types
        # Storage location for game build files
        class StorageLocation < Pangea::Resources::BaseAttributes
          attribute? :bucket, Pangea::Resources::Types::String.optional
          attribute? :key, Pangea::Resources::Types::String.optional
          attribute? :role_arn, Pangea::Resources::Types::String.optional
          attribute :object_version?, Pangea::Resources::Types::String
        end

        # Main attributes for GameLift build

        # Reference for GameLift build resources
      end
    end
  end
end