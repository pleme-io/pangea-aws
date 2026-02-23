# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        SageMakerTrainingDataSource = Resources::Types::Hash.schema(
          s3_data_source: Resources::Types::Hash.schema(s3_data_type: Resources::Types::String.constrained(included_in: ['ManifestFile', 'S3Prefix', 'AugmentedManifestFile']),
                                       s3_uri: Resources::Types::String.constrained(format: /\As3:\/\//),
                                       s3_data_distribution_type?: Resources::Types::String.constrained(included_in: ['FullyReplicated', 'ShardedByS3Key']).default('FullyReplicated'),
                                       attribute_names?: Resources::Types::Array.of(Resources::Types::String).lax.optional)
        )

        SageMakerTrainingInputDataConfig = Resources::Types::Hash.schema(
          channel_name: Resources::Types::String.constrained(min_size: 1, max_size: 64, format: /\A[a-zA-Z0-9\-]+\z/),
          data_source: SageMakerTrainingDataSource, content_type?: SageMakerTrainingContentType.optional,
          compression_type?: SageMakerTrainingCompressionType.default('None'), record_wrapper_type?: Resources::Types::String.constrained(included_in: ['None', 'RecordIO']).default('None'),
          input_mode?: SageMakerTrainingInputMode.default('File'), shuffle_config?: Resources::Types::Hash.schema(seed: Resources::Types::Integer.constrained(gteq: 0, lteq: 4_294_967_295).lax).optional
        )

        SageMakerTrainingOutputDataConfig = Resources::Types::Hash.schema(kms_key_id?: Resources::Types::String.optional, s3_output_path: Resources::Types::String.constrained(format: /\As3:\/\//).lax)
        SageMakerTrainingResourceConfig = Resources::Types::Hash.schema(instance_count: Resources::Types::Integer.constrained(gteq: 1, lteq: 100), instance_type: SageMakerTrainingInstanceType,
                                                       volume_size_in_gb: Resources::Types::Integer.constrained(gteq: 1, lteq: 16_384), volume_kms_key_id?: Resources::Types::String.optional).lax
        SageMakerTrainingStoppingCondition = Resources::Types::Hash.schema(max_runtime_in_seconds?: Resources::Types::Integer.constrained(gteq: 1, lteq: 432_000).lax.default(86_400))
        SageMakerTrainingVpcConfig = Resources::Types::Hash.schema(security_group_ids: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 5),
                                                  subnets: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 16)).lax
        SageMakerTrainingCheckpointConfig = Resources::Types::Hash.schema(s3_uri: Resources::Types::String.constrained(format: /\As3:\/\//).lax, local_path?: Resources::Types::String.default('/opt/ml/checkpoints'))
        SageMakerTrainingDebugHookConfig = Resources::Types::Hash.schema(local_path?: Resources::Types::String.default('/opt/ml/output/tensors'), s3_output_path: Resources::Types::String.constrained(format: /\As3:\/\//),
                                                        hook_parameters?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).lax.optional, collection_configurations?: Resources::Types::Array.of(Resources::Types::Hash).optional)
        SageMakerTrainingProfilerConfig = Resources::Types::Hash.schema(s3_output_path?: Resources::Types::String.constrained(format: /\As3:\/\//).optional,
                                                       profiling_interval_in_milliseconds?: Resources::Types::Integer.constrained(gteq: 100, lteq: 3_600_000).default(500),
                                                       profiling_parameters?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).lax.optional)
      end
    end
  end
end
