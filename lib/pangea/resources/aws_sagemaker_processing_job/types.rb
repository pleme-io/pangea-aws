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
    module AWS
      module Types
        # SageMaker Processing Job attributes with data processing validation
        class SageMakerProcessingJobAttributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute? :processing_job_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute? :role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
          )
          attribute? :app_specification, Resources::Types::Hash.schema(
            image_uri: Resources::Types::String,
            container_entrypoint?: Resources::Types::Array.of(Resources::Types::String).optional,
            container_arguments?: Resources::Types::Array.of(Resources::Types::String).optional
          ).lax
          attribute? :processing_resources, Resources::Types::Hash.schema(
            cluster_config: Resources::Types::Hash.schema(
              instance_count: Resources::Types::Integer.constrained(gteq: 1, lteq: 100),
              instance_type: Resources::Types::String.constrained(included_in: ['ml.t3.medium', 'ml.t3.large', 'ml.t3.xlarge', 'ml.t3.2xlarge', 'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge', 'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge', 'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge', 'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge', 'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge', 'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge', 'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.8xlarge', 'ml.r5.12xlarge', 'ml.r5.16xlarge', 'ml.r5.24xlarge']),
              volume_size_in_gb: Resources::Types::Integer.constrained(gteq: 1, lteq: 16384),
              volume_kms_key_id?: Resources::Types::String.optional
            ).lax
          )
          
          # Optional attributes
          attribute? :processing_inputs, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              input_name: Resources::Types::String,
              app_managed?: Resources::Types::Bool.default(false),
              s3_input?: Resources::Types::Hash.schema(
                s3_uri: Resources::Types::String.constrained(format: /\As3:\/\//),
                local_path: Resources::Types::String,
                s3_data_type: Resources::Types::String.constrained(included_in: ['ManifestFile', 'S3Prefix']),
                s3_input_mode: Resources::Types::String.constrained(included_in: ['Pipe', 'File']).default('File'),
                s3_data_distribution_type?: Resources::Types::String.constrained(included_in: ['FullyReplicated', 'ShardedByS3Key']).default('FullyReplicated'),
                s3_compression_type?: Resources::Types::String.constrained(included_in: ['None', 'Gzip']).default('None')
              ).lax.optional,
              dataset_definition?: Resources::Types::Hash.schema(
                athena_dataset_definition?: Resources::Types::Hash.schema(
                  catalog: Resources::Types::String,
                  database: Resources::Types::String,
                  query_string: Resources::Types::String,
                  work_group?: Resources::Types::String.optional,
                  output_s3_uri: Resources::Types::String.constrained(format: /\As3:\/\//),
                  kms_key_id?: Resources::Types::String.optional,
                  output_format: Resources::Types::String.constrained(included_in: ['PARQUET', 'ORC', 'AVRO', 'JSON', 'TEXTFILE']),
                  output_compression?: Resources::Types::String.constrained(included_in: ['GZIP', 'SNAPPY', 'ZLIB']).optional
                ).lax.optional,
                redshift_dataset_definition?: Resources::Types::Hash.schema(
                  cluster_id: Resources::Types::String,
                  database: Resources::Types::String,
                  db_user: Resources::Types::String,
                  query_string: Resources::Types::String,
                  cluster_role_arn: Resources::Types::String,
                  output_s3_uri: Resources::Types::String.constrained(format: /\As3:\/\//),
                  kms_key_id?: Resources::Types::String.optional,
                  output_format: Resources::Types::String.constrained(included_in: ['PARQUET', 'CSV']).default('PARQUET'),
                  output_compression?: Resources::Types::String.constrained(included_in: ['None', 'GZIP', 'BZIP2', 'ZSTD']).optional
                ).lax.optional
              ).optional
            )
          ).optional
          attribute? :processing_output_config, Resources::Types::Hash.schema(
            outputs: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                output_name: Resources::Types::String,
                s3_output: Resources::Types::Hash.schema(
                  s3_uri: Resources::Types::String.constrained(format: /\As3:\/\//),
                  local_path: Resources::Types::String,
                  s3_upload_mode: Resources::Types::String.constrained(included_in: ['Continuous', 'EndOfJob']).default('EndOfJob')
                ),
                feature_store_output?: Resources::Types::Hash.schema(
                  feature_group_name: Resources::Types::String
                ).lax.optional,
                app_managed?: Resources::Types::Bool.default(false)
              )
            ),
            kms_key_id?: Resources::Types::String.optional
          ).optional
          attribute? :stopping_condition, Resources::Types::Hash.schema(
            max_runtime_in_seconds: Resources::Types::Integer.constrained(gteq: 1, lteq: 432000).default(86400)
          ).lax.optional
          attribute :environment, Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).default({}.freeze)
          attribute? :network_config, Resources::Types::Hash.schema(
            enable_inter_container_traffic_encryption?: Resources::Types::Bool.default(false),
            enable_network_isolation?: Resources::Types::Bool.default(false),
            vpc_config?: Resources::Types::Hash.schema(
              security_group_ids: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 5),
              subnets: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 16)
            ).lax.optional
          ).optional
          attribute? :tags, Resources::Types::AwsTags.optional
          
          def estimated_processing_cost
            instance_cost = 0.25 # Simplified hourly rate
            instance_count = processing_resources&.dig(:cluster_config)[:instance_count]
            max_runtime_hours = (stopping_condition&.dig(:max_runtime_in_seconds) || 86400) / 3600.0
            storage_cost = (processing_resources&.dig(:cluster_config)[:volume_size_in_gb] * 0.10) / (24 * 30)
            
            (instance_cost * instance_count + storage_cost) * max_runtime_hours
          end
          
          def is_distributed_processing?
            processing_resources&.dig(:cluster_config)[:instance_count] > 1
          end
          
          def uses_feature_store_output?
            processing_output_config&.dig(:outputs)&.any? { |output| output[:feature_store_output] } || false
          end
        end
      end
    end
  end
end