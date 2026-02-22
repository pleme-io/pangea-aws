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
    # AWS IoT Role Alias Types
    # 
    # Role aliases allow IoT devices to assume IAM roles without embedding credentials.
    # This enables secure access to AWS services from IoT devices using X.509 certificate
    # authentication and temporary credentials via AWS STS.
    module AwsIotRoleAliasTypes
      # Main attributes for IoT role alias resource

      # Output attributes from role alias resource
    end
  end
end