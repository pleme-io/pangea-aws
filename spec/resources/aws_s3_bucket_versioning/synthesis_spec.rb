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
require 'pangea/resources/aws_s3_bucket_versioning/resource'

RSpec.describe 'aws_s3_bucket_versioning synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes versioning enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_versioning(:enabled, {
          bucket: 'my-bucket',
          versioning_configuration: { status: 'Enabled' }
        })
      end

      result = synthesizer.synthesis
      ver = result['resource']['aws_s3_bucket_versioning']['enabled']

      expect(ver['bucket']).to eq('my-bucket')
    end

    it 'synthesizes versioning suspended' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_versioning(:suspended, {
          bucket: 'my-bucket',
          versioning_configuration: { status: 'Suspended' }
        })
      end

      result = synthesizer.synthesis
      ver = result['resource']['aws_s3_bucket_versioning']['suspended']

      expect(ver['bucket']).to eq('my-bucket')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_versioning(:test, {
          bucket: 'test-bucket',
          versioning_configuration: { status: 'Enabled' }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_versioning.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_versioning.test.bucket}')
    end
  end

  describe 'validation' do
    it 'requires versioning_configuration' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketVersioningAttributes.new(
          bucket: 'test'
        )
      }.to raise_error(Dry::Struct::Error, /versioning_configuration is required/)
    end

    it 'provides correct computed properties' do
      attrs = Pangea::Resources::AWS::Types::S3BucketVersioningAttributes.new(
        bucket: 'test',
        versioning_configuration: { status: 'Enabled' }
      )

      expect(attrs.versioning_enabled?).to be true
      expect(attrs.versioning_suspended?).to be false
      expect(attrs.status).to eq('Enabled')
    end
  end
end
