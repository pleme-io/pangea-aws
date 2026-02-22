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
        # Input transformation validation
        unless const_defined?(:InputTransformer)
        InputTransformer = Resources::Types::Hash.schema(input_paths?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional, input_template: Resources::Types::String)
          .constructor { |value|
            template = value[:input_template]
            raise Dry::Types::ConstraintError, 'Input template must contain substitution patterns or be empty JSON object' unless template.match?(/\{.*\}/) || template == '"{}"'
            value
          }
        end


        unless const_defined?(:RetryPolicy)
        RetryPolicy = Resources::Types::Hash.schema(maximum_retry_attempts?: Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 185),
                                         maximum_event_age_in_seconds?: Resources::Types::Integer.optional.constrained(gteq: 60, lteq: 86_400))

        end
        unless const_defined?(:DeadLetterConfig)
        DeadLetterConfig = Resources::Types::Hash.schema(arn?: Resources::Types::String.optional.constrained(format: /\Aarn:aws:sqs:/))
        end
        HttpParameters = Resources::Types::Hash.schema(path_parameter_values?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional,
                                            header_parameters?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional,
                                            query_string_parameters?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional)
        KinesisParameters = Resources::Types::Hash.schema(partition_key_path?: Resources::Types::String.optional)
        SqsParameters = Resources::Types::Hash.schema(message_group_id?: Resources::Types::String.optional)

        EcsParameters = Resources::Types::Hash.schema(
          task_definition_arn: Resources::Types::String.constrained(format: /\Aarn:aws:ecs:/),
          task_count?: Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 10),
          launch_type?: Resources::Types::String.constrained(included_in: ['EC2', 'FARGATE', 'EXTERNAL']).optional,
          network_configuration?: Resources::Types::Hash.schema(awsvpc_configuration?: Resources::Types::Hash.optional).optional,
          platform_version?: Resources::Types::String.optional, group?: Resources::Types::String.optional,
          capacity_provider_strategy?: Resources::Types::Array.of(Resources::Types::Hash).optional,
          placement_constraint?: Resources::Types::Array.of(Resources::Types::Hash).optional,
          placement_strategy?: Resources::Types::Array.of(Resources::Types::Hash).optional,
          tags?: Resources::Types::AwsTags.optional
        )

        BatchParameters = Resources::Types::Hash.schema(
          job_definition: Resources::Types::String, job_name: Resources::Types::String,
          array_properties?: Resources::Types::Hash.schema(size?: Resources::Types::Integer.optional.constrained(gteq: 2, lteq: 10_000)).optional,
          retry_strategy?: Resources::Types::Hash.schema(attempts?: Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 10)).optional
        )
      end
    end
  end
end
