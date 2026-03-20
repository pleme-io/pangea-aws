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
require 'pangea/resources/aws_s3_bucket_public_access_block/resource'

RSpec.describe 'aws_s3_bucket_public_access_block synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes fully blocked public access' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_public_access_block(:secure, {
          bucket: 'my-bucket',
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        })
      end

      result = synthesizer.synthesis
      pab = result['resource']['aws_s3_bucket_public_access_block']['secure']

      expect(pab['bucket']).to eq('my-bucket')
      expect(pab['block_public_acls']).to be true
      expect(pab['block_public_policy']).to be true
      expect(pab['ignore_public_acls']).to be true
      expect(pab['restrict_public_buckets']).to be true
    end

    it 'synthesizes partial public access block' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_public_access_block(:partial, {
          bucket: 'my-bucket',
          block_public_acls: true,
          block_public_policy: true
        })
      end

      result = synthesizer.synthesis
      pab = result['resource']['aws_s3_bucket_public_access_block']['partial']

      expect(pab['bucket']).to eq('my-bucket')
      expect(pab['block_public_acls']).to be true
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_public_access_block(:test, {
          bucket: 'test-bucket',
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_public_access_block.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_public_access_block.test.bucket}')
    end
  end

  describe 'computed properties' do
    it 'reports fully blocked when all settings true' do
      attrs = Pangea::Resources::AWS::Types::S3BucketPublicAccessBlockAttributes.new(
        bucket: 'test',
        block_public_acls: true,
        block_public_policy: true,
        ignore_public_acls: true,
        restrict_public_buckets: true
      )

      expect(attrs.fully_blocked?).to be true
      expect(attrs.security_level).to eq('secure')
      expect(attrs.blocked_settings_count).to eq(4)
    end

    it 'reports open when no settings enabled' do
      attrs = Pangea::Resources::AWS::Types::S3BucketPublicAccessBlockAttributes.new(
        bucket: 'test'
      )

      expect(attrs.allows_public_access?).to be true
      expect(attrs.security_level).to eq('open')
      expect(attrs.blocked_settings_count).to eq(0)
    end
  end
end
