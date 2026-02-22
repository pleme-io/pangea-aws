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
    # AWS IoT CA Certificate Types
    # 
    # CA (Certificate Authority) certificates enable device certificate validation and just-in-time
    # registration (JITR) for large-scale IoT deployments. They establish trust chains for device
    # certificates and enable automated device onboarding.
    module AwsIotCaCertificateTypes
      # Registration configuration for just-in-time registration
      class RegistrationConfig < Dry::Struct
        schema schema.strict

        # IoT policy template for JITR devices
        attribute :template_body, Resources::Types::String.optional

        # Template name for the registration template
        attribute :template_name, Resources::Types::String.optional

        # IAM role ARN for provisioning operations
        attribute :role_arn, Resources::Types::String.optional
      end

      # Main attributes for IoT CA certificate resource

      # Output attributes from CA certificate resource
    end
  end
end