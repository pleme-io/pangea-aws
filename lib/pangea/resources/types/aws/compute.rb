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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # EC2 instance types
      Ec2InstanceType = Resources::Types::String.constrained(included_in: ['t3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge',
        't3a.nano', 't3a.micro', 't3a.small', 't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge',
        'm5.large', 'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge', 'm5.24xlarge',
        'm5a.large', 'm5a.xlarge', 'm5a.2xlarge', 'm5a.4xlarge', 'm5a.8xlarge', 'm5a.12xlarge', 'm5a.16xlarge', 'm5a.24xlarge',
        'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
        'c5n.large', 'c5n.xlarge', 'c5n.2xlarge', 'c5n.4xlarge', 'c5n.9xlarge', 'c5n.18xlarge',
        'r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge', 'r5.16xlarge', 'r5.24xlarge',
        'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge'])

      # Lambda runtimes
      LambdaRuntime = Resources::Types::String.constrained(included_in: ['python3.12', 'python3.11', 'python3.10', 'python3.9', 'python3.8',
        'nodejs20.x', 'nodejs18.x', 'nodejs16.x',
        'java21', 'java17', 'java11', 'java8.al2', 'java8',
        'dotnet8', 'dotnet6',
        'go1.x',
        'ruby3.2', 'ruby2.7',
        'provided.al2023', 'provided.al2', 'provided'])

      LambdaArchitecture = Resources::Types::String.constrained(included_in: ['x86_64', 'arm64'])
      LambdaPackageType = Resources::Types::String.constrained(included_in: ['Zip', 'Image'])
      LambdaTracingMode = Resources::Types::String.constrained(included_in: ['Active', 'PassThrough'])

      # Lambda memory validation (128MB to 10240MB)
      LambdaMemory = Integer.constrained(gteq: 128, lteq: 10240).constructor { |value|
        unless value >= 512 || value % 64 == 0
          raise Dry::Types::ConstraintError, "Lambda memory must be in 64MB increments between 128-512MB, or 1MB increments above 512MB"
        end
        value
      }

      LambdaTimeout = Integer.constrained(gteq: 1, lteq: 900)
      LambdaReservedConcurrency = Integer.constrained(gteq: 0, lteq: 1000)
      LambdaProvisionedConcurrency = Integer.constrained(gteq: 1, lteq: 1000)
      LambdaEventSourcePosition = Resources::Types::String.constrained(included_in: ['TRIM_HORIZON', 'LATEST', 'AT_TIMESTAMP'])

      LambdaDeadLetterConfig = Hash.schema(target_arn: String.constrained(format: /\Aarn:aws:(sqs|sns):/)).lax

      LambdaVpcConfig = Hash.schema(
        subnet_ids: Array.of(String).constrained(min_size: 1),
        security_group_ids: Array.of(String).constrained(min_size: 1)
      ).lax

      LambdaEnvironmentVariables = Hash.map(String.constrained(format: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/), String)

      LambdaFileSystemConfig = Hash.schema(
        arn: String.constrained(format: /\Aarn:aws:elasticfilesystem:/),
        local_mount_path: String.constrained(format: /\A\/mnt\/[a-zA-Z0-9_-]+\z/)
      ).lax

      LambdaEphemeralStorage = Hash.schema(size: Integer.constrained(gteq: 512, lteq: 10240).lax)
      LambdaSnapStart = Hash.schema(apply_on: String.default('None').lax.enum('PublishedVersions', 'None'))

      LambdaImageConfig = Hash.schema(
        entry_point?: Array.of(String).optional,
        command?: Array.of(String).optional,
        working_directory?: String.optional
      ).lax

      LambdaPermissionAction = Resources::Types::String.constrained(included_in: ['lambda:InvokeFunction', 'lambda:GetFunction', 'lambda:GetFunctionConfiguration',
        'lambda:UpdateFunctionConfiguration', 'lambda:UpdateFunctionCode', 'lambda:DeleteFunction',
        'lambda:PublishVersion', 'lambda:CreateAlias', 'lambda:UpdateAlias', 'lambda:DeleteAlias',
        'lambda:GetAlias', 'lambda:ListVersionsByFunction', 'lambda:GetPolicy',
        'lambda:PutFunctionConcurrency', 'lambda:DeleteFunctionConcurrency',
        'lambda:GetFunctionConcurrency', 'lambda:ListTags', 'lambda:TagResource', 'lambda:UntagResource',
        'lambda:*'])

      LambdaEventSourceType = Resources::Types::String.constrained(included_in: ['kinesis', 'dynamodb', 'sqs', 'msk', 'self-managed-kafka', 'rabbitmq'])
      LambdaDestinationOnFailure = Hash.schema(destination: String.constrained(format: /\Aarn:aws:(sqs|sns|lambda|events):/)).lax
      LambdaSelfManagedEventSource = Hash.schema(endpoints: Hash.map(Resources::Types::String.constrained(included_in: ['KAFKA_BOOTSTRAP_SERVERS']).lax, Array.of(String)))

      LambdaSourceAccessConfiguration = Hash.schema(
        type: Resources::Types::String.constrained(included_in: ['BASIC_AUTH', 'VPC_SUBNET', 'VPC_SECURITY_GROUP', 'SASL_SCRAM_256_AUTH', 'SASL_SCRAM_512_AUTH']),
        uri: String
      ).lax
    end
  end
end
