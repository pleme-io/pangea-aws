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

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_s3_bucket_replication_configuration/resource'

RSpec.describe 'aws_s3_bucket_replication_configuration synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic replication configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_replication_configuration(:basic, {
          bucket: 'source-bucket',
          role: 'arn:aws:iam::123456789012:role/replication-role',
          rule: [
            {
              id: 'replicate-all',
              status: 'Enabled',
              destination: {
                bucket: 'arn:aws:s3:::dest-bucket'
              }
            }
          ]
        })
      end

      result = synthesizer.synthesis
      repl = result['resource']['aws_s3_bucket_replication_configuration']['basic']

      expect(repl['bucket']).to eq('source-bucket')
      expect(repl['role']).to eq('arn:aws:iam::123456789012:role/replication-role')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_replication_configuration(:test, {
          bucket: 'source-bucket',
          role: 'arn:aws:iam::123456789012:role/replication-role',
          rule: [
            {
              id: 'rule-1',
              status: 'Enabled',
              destination: { bucket: 'arn:aws:s3:::dest-bucket' }
            }
          ]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_replication_configuration.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_replication_configuration.test.bucket}')
      expect(ref.outputs[:role]).to eq('${aws_s3_bucket_replication_configuration.test.role}')
    end
  end

  describe 'validation' do
    it 'validates IAM role ARN format' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketReplicationConfigurationAttributes.new(
          bucket: 'test',
          role: 'invalid-role',
          rule: [
            {
              id: 'rule-1',
              status: 'Enabled',
              destination: { bucket: 'arn:aws:s3:::dest-bucket' }
            }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /valid IAM role ARN/)
    end

    it 'requires unique priorities for multiple rules' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketReplicationConfigurationAttributes.new(
          bucket: 'test',
          role: 'arn:aws:iam::123456789012:role/replication-role',
          rule: [
            {
              id: 'rule-1',
              status: 'Enabled',
              priority: 1,
              destination: { bucket: 'arn:aws:s3:::dest-1' }
            },
            {
              id: 'rule-2',
              status: 'Enabled',
              priority: 1,
              destination: { bucket: 'arn:aws:s3:::dest-2' }
            }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /priorities must be unique/)
    end
  end
end
