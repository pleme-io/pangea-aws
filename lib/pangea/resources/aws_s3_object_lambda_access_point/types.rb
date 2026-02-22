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

module Pangea
  module Resources
    module AWS
      module S3ObjectLambdaAccessPoint
        # Common types for S3 Object Lambda Access Point configurations
        module Types
          # S3 Object Lambda Access Point Name constraint  
          ObjectLambdaAccessPointName = Resources::Types::String.constrained(
            min_size: 3,
            max_size: 45,
            format: /\A[a-z0-9\-]+\z/
          )
          
          # Lambda Function ARN constraint
          LambdaFunctionArn = Resources::Types::String.constrained(
            format: /\Aarn:aws:lambda:[a-z0-9\-]*:[0-9]{12}:function:[a-zA-Z0-9\-_]+\z/
          )
          
          # S3 Access Point ARN constraint
          unless const_defined?(:AccessPointArn)
          AccessPointArn = Resources::Types::String.constrained(
            format: /\Aarn:aws:s3:[a-z0-9\-]*:[0-9]{12}:accesspoint\/[a-z0-9\-]+\z/
          )
          end
          
          # Object Lambda supported actions
          SupportedAction = Resources::Types::String.constrained(included_in: ['GetObject', 
            'HeadObject', 
            'ListObjects', 
            'ListObjectsV2'])
          
          # Transformation Configuration
          TransformationConfiguration = Resources::Types::Hash.schema({
            actions: Resources::Types::Array.of(SupportedAction),
            content_transformation: Resources::Types::Hash.schema({
              aws_lambda: Resources::Types::Hash.schema({
                function_arn: LambdaFunctionArn,
                function_payload?: Resources::Types::String.optional
              })
            })
          })
        end

        # S3 Object Lambda Access Point attributes with comprehensive validation
        class S3ObjectLambdaAccessPointAttributes < Dry::Struct
          # Required attributes
          attribute :configuration, Resources::Types::Hash.schema({
            supporting_access_point: Types::AccessPointArn,
            transformation_configuration: Resources::Types::Array.of(Types::TransformationConfiguration).constrained(min_size: 1)
          })
          attribute :name, Types::ObjectLambdaAccessPointName
          
          # Optional attributes
          attribute? :account_id, Resources::Types::String.constrained(format: /\A\d{12}\z/).optional
          
          # Computed properties
          def supporting_access_point
            configuration[:supporting_access_point]
          end
          
          def transformations
            configuration[:transformation_configuration]
          end
          
          def transformation_count
            transformations.length
          end
          
          def lambda_functions
            transformations.map { |t| t[:content_transformation][:aws_lambda][:function_arn] }
          end
          
          def supported_actions
            transformations.flat_map { |t| t[:actions] }.uniq
          end
          
          def has_payload?
            transformations.any? { |t| t[:content_transformation][:aws_lambda][:function_payload] }
          end
        end
      end
    end
  end
end