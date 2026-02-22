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
    module AwsGameliftFleet
      module Types
        # IP permission configuration for the fleet
        class IpPermission < Dry::Struct
          attribute :from_port, Pangea::Resources::Types::Integer
          attribute :to_port, Pangea::Resources::Types::Integer
          attribute :ip_range, Pangea::Resources::Types::String
          attribute :protocol, Pangea::Resources::Types::String.constrained(included_in: ["TCP", "UDP"])
        end

        # Runtime configuration for fleet instances
        class ServerProcess < Dry::Struct
          attribute :concurrent_executions, Pangea::Resources::Types::Integer
          attribute :launch_path, Pangea::Resources::Types::String
          attribute :parameters?, Pangea::Resources::Types::String
        end

        class RuntimeConfiguration < Dry::Struct
          attribute :game_session_activation_timeout_seconds?, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 600)
          attribute :max_concurrent_game_session_activations?, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 2147483647)
          attribute :server_process?, Pangea::Resources::Types::Array.of(ServerProcess)
        end

        # Resource creation limit policy
        class ResourceCreationLimitPolicy < Dry::Struct
          attribute :new_game_sessions_per_creator?, Pangea::Resources::Types::Integer
          attribute :policy_period_in_minutes?, Pangea::Resources::Types::Integer
        end

        # Certificate configuration for TLS
        class CertificateConfiguration < Dry::Struct
          attribute :certificate_type, Pangea::Resources::Types::String.constrained(included_in: ["DISABLED", "GENERATED"])
        end

        # Main attributes for GameLift fleet

        # Reference for GameLift fleet resources
      end
    end
  end
end