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
require_relative 'types'
require_relative 'synthesis/synthesizer'

module Pangea
  module Resources
    module AWS
      # AWS Batch Job Definition implementation
      # Provides type-safe function for creating job definitions
      def aws_batch_job_definition(name, attributes = {})
        validated_attrs = Types::BatchJobDefinitionAttributes.new(attributes)

        ref = ResourceReference.new(
          type: 'aws_batch_job_definition',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_batch_job_definition.#{name}.id}",
            arn: "${aws_batch_job_definition.#{name}.arn}",
            name: "${aws_batch_job_definition.#{name}.name}",
            revision: "${aws_batch_job_definition.#{name}.revision}",
            tags_all: "${aws_batch_job_definition.#{name}.tags_all}"
          }
        )

        attrs = validated_attrs.to_h

        resource :aws_batch_job_definition, name do
          job_definition_name attrs[:job_definition_name]
          type attrs[:type]

          container_properties(attrs[:container_properties]) if attrs[:container_properties]
          node_properties(attrs[:node_properties]) if attrs[:node_properties]

          if attrs[:retry_strategy]
            retry_strategy(attrs[:retry_strategy])
          end

          if attrs[:timeout]
            timeout(attrs[:timeout])
          end

          platform_capabilities attrs[:platform_capabilities] if attrs[:platform_capabilities]
          propagate_tags attrs[:propagate_tags] unless attrs[:propagate_tags].nil?
          tags attrs[:tags] if attrs[:tags]
        end

        ref
      end
    end
  end
end
