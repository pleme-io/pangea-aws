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
require 'pangea/resources/reference'
require 'pangea/resources/aws_eventbridge_target/types'
require 'pangea/resource_registry'
require_relative 'ecs_target_builder'
require_relative 'batch_target_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS EventBridge Target with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EventBridge target attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eventbridge_target(name, attributes = {})
        # Validate attributes using dry-struct
        target_attrs = Types::EventBridgeTargetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_event_target, name) do
          rule target_attrs.rule
          event_bus_name target_attrs.event_bus_name
          target_id target_attrs.target_id
          arn target_attrs.arn
          
          # Role ARN for target invocation
          role_arn target_attrs.role_arn if target_attrs.role_arn
          
          # Input configuration (mutually exclusive)
          input target_attrs.input if target_attrs.input
          input_path target_attrs.input_path if target_attrs.input_path
          
          # Input transformer
          if target_attrs.input_transformer
            transformer_data = target_attrs.input_transformer.is_a?(Hash) ? target_attrs.input_transformer : target_attrs.input_transformer.to_h
            input_transformer do
              input_paths transformer_data[:input_paths] if transformer_data[:input_paths]
              input_template transformer_data[:input_template]
            end
          end
          
          # Retry policy
          if target_attrs.retry_policy
            retry_data = target_attrs.retry_policy.is_a?(Hash) ? target_attrs.retry_policy : target_attrs.retry_policy.to_h
            retry_policy do
              maximum_retry_attempts retry_data[:maximum_retry_attempts] if retry_data[:maximum_retry_attempts]
              maximum_event_age_in_seconds retry_data[:maximum_event_age_in_seconds] if retry_data[:maximum_event_age_in_seconds]
            end
          end

          # Dead letter config
          if target_attrs.dead_letter_config
            dlc_data = target_attrs.dead_letter_config.is_a?(Hash) ? target_attrs.dead_letter_config : target_attrs.dead_letter_config.to_h
            dead_letter_config do
              arn dlc_data[:arn] if dlc_data[:arn]
            end
          end
          
          # HTTP parameters (for API destinations)
          if target_attrs.http_parameters
            http_data = target_attrs.http_parameters.is_a?(Hash) ? target_attrs.http_parameters : target_attrs.http_parameters.to_h
            http_parameters do
              path_parameter_values http_data[:path_parameter_values] if http_data[:path_parameter_values]
              header_parameters http_data[:header_parameters] if http_data[:header_parameters]
              query_string_parameters http_data[:query_string_parameters] if http_data[:query_string_parameters]
            end
          end

          # Kinesis parameters
          if target_attrs.kinesis_parameters
            kinesis_data = target_attrs.kinesis_parameters.is_a?(Hash) ? target_attrs.kinesis_parameters : target_attrs.kinesis_parameters.to_h
            kinesis_parameters do
              partition_key_path kinesis_data[:partition_key_path] if kinesis_data[:partition_key_path]
            end
          end

          # SQS parameters
          if target_attrs.sqs_parameters
            sqs_data = target_attrs.sqs_parameters.is_a?(Hash) ? target_attrs.sqs_parameters : target_attrs.sqs_parameters.to_h
            sqs_parameters do
              message_group_id sqs_data[:message_group_id] if sqs_data[:message_group_id]
            end
          end
          
          # ECS parameters
          if target_attrs.ecs_parameters
            ecs_params = target_attrs.ecs_parameters.is_a?(Hash) ? target_attrs.ecs_parameters : target_attrs.ecs_parameters.to_h
            ecs_parameters do
              task_definition_arn ecs_params[:task_definition_arn]
              task_count ecs_params[:task_count] if ecs_params[:task_count]
              launch_type ecs_params[:launch_type] if ecs_params[:launch_type]
              platform_version ecs_params[:platform_version] if ecs_params[:platform_version]
              group ecs_params[:group] if ecs_params[:group]

              if ecs_params[:network_configuration]
                net_config = ecs_params[:network_configuration]
                network_configuration do
                  if net_config[:awsvpc_configuration]
                    awsvpc_config = net_config[:awsvpc_configuration]
                    awsvpc_configuration do
                      subnets awsvpc_config[:subnets]
                      security_groups awsvpc_config[:security_groups] if awsvpc_config[:security_groups]
                      assign_public_ip awsvpc_config[:assign_public_ip] if awsvpc_config[:assign_public_ip]
                    end
                  end
                end
              end

              if ecs_params[:tags]
                tags do
                  ecs_params[:tags].each { |key, value| public_send(key, value) }
                end
              end
            end
          end

          # Batch parameters
          if target_attrs.batch_parameters
            batch_params = target_attrs.batch_parameters.is_a?(Hash) ? target_attrs.batch_parameters : target_attrs.batch_parameters.to_h
            batch_parameters do
              job_definition batch_params[:job_definition]
              job_name batch_params[:job_name]

              if batch_params[:array_properties]
                array_properties do
                  size batch_params[:array_properties][:size] if batch_params[:array_properties][:size]
                end
              end

              if batch_params[:retry_strategy]
                retry_strategy do
                  attempts batch_params[:retry_strategy][:attempts] if batch_params[:retry_strategy][:attempts]
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_event_target',
          name: name,
          resource_attributes: target_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_event_target.#{name}.id}",
            rule: "${aws_cloudwatch_event_target.#{name}.rule}",
            target_id: "${aws_cloudwatch_event_target.#{name}.target_id}",
            arn: "${aws_cloudwatch_event_target.#{name}.arn}",
            event_bus_name: "${aws_cloudwatch_event_target.#{name}.event_bus_name}"
          },
          computed_properties: {
            target_type: target_attrs.target_type,
            is_lambda_target: target_attrs.is_lambda_target?,
            is_sqs_target: target_attrs.is_sqs_target?,
            is_sns_target: target_attrs.is_sns_target?,
            is_kinesis_target: target_attrs.is_kinesis_target?,
            is_ecs_target: target_attrs.is_ecs_target?,
            is_batch_target: target_attrs.is_batch_target?,
            is_api_gateway_target: target_attrs.is_api_gateway_target?,
            is_fifo_sqs: target_attrs.is_fifo_sqs?,
            has_role: target_attrs.has_role?,
            has_input_transformation: target_attrs.has_input_transformation?,
            has_retry_policy: target_attrs.has_retry_policy?,
            has_dead_letter_queue: target_attrs.has_dead_letter_queue?,
            uses_default_bus: target_attrs.uses_default_bus?,
            uses_custom_bus: target_attrs.uses_custom_bus?,
            max_retry_attempts: target_attrs.max_retry_attempts,
            max_event_age_hours: target_attrs.max_event_age_hours,
            estimated_monthly_cost: target_attrs.estimated_monthly_cost,
            target_service: target_attrs.target_service,
            reliability_features: target_attrs.reliability_features
          }
        )
      end
    end
  end
end
