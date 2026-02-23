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

module Pangea
  module Resources
    module AWS
      module Types
        class BatchJobDefinitionAttributes
          # Computed properties for batch job definitions
          module Computed
            def container_job?
              self[:type] == 'container'
            end

            alias is_container_job? container_job?

            def multinode_job?
              self[:type] == 'multinode'
            end

            alias is_multinode_job? multinode_job?

            def supports_ec2?
              platform_capabilities.nil? || platform_capabilities.include?('EC2')
            end

            def supports_fargate?
              platform_capabilities&.include?('FARGATE') || false
            end

            def has_retry_strategy?
              !retry_strategy.nil?
            end

            def has_timeout?
              !timeout.nil?
            end

            def estimated_memory_mb
              container_properties&.dig(:memory)
            end

            def estimated_vcpus
              container_properties&.dig(:vcpus)
            end
          end
        end
      end
    end
  end
end
