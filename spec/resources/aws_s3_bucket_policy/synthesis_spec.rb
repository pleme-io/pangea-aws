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
require 'pangea/resources/aws_s3_bucket_policy/resource'

RSpec.describe 'aws_s3_bucket_policy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:valid_policy) do
    {
      Version: '2012-10-17',
      Statement: [
        {
          Effect: 'Allow',
          Principal: { AWS: 'arn:aws:iam::123456789012:root' },
          Action: ['s3:GetObject'],
          Resource: 'arn:aws:s3:::my-bucket/*'
        }
      ]
    }.to_json
  end

  describe 'terraform synthesis' do
    it 'synthesizes bucket policy' do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_policy(:basic, {
          bucket: 'my-bucket',
          policy: policy
        })
      end

      result = synthesizer.synthesis
      bp = result['resource']['aws_s3_bucket_policy']['basic']

      expect(bp['bucket']).to eq('my-bucket')
      expect(bp['policy']).to eq(policy)
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_policy(:test, {
          bucket: 'test-bucket',
          policy: policy
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_policy.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_policy.test.bucket}')
      expect(ref.outputs[:policy]).to eq('${aws_s3_bucket_policy.test.policy}')
    end
  end

  describe 'validation' do
    it 'rejects invalid JSON policy' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketPolicyAttributes.new(
          bucket: 'test',
          policy: 'not-json'
        )
      }.to raise_error(Dry::Struct::Error, /policy must be valid JSON/)
    end

    it 'rejects policy without Version and Statement' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketPolicyAttributes.new(
          bucket: 'test',
          policy: '{"foo": "bar"}'
        )
      }.to raise_error(Dry::Struct::Error, /valid IAM policy document/)
    end

    it 'rejects statements without Effect' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketPolicyAttributes.new(
          bucket: 'test',
          policy: '{"Version":"2012-10-17","Statement":[{"Action":"s3:*"}]}'
        )
      }.to raise_error(Dry::Struct::Error, /Effect/)
    end
  end
end
