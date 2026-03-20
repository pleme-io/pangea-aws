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
require 'pangea/resources/aws_s3_bucket_accelerate_configuration/resource'

RSpec.describe 'aws_s3_bucket_accelerate_configuration synthesis' do
  # NOTE: The resource method references Types:: path which doesn't resolve after
  # full pangea-aws load. Testing type validation directly via correct class path.
  let(:attrs_class) { Pangea::Resources::AWS::S3BucketAccelerateConfiguration::S3BucketAccelerateConfigurationAttributes }

  describe 'type validation' do
    it 'creates valid acceleration enabled config' do
      attrs = attrs_class.new(bucket: 'my-bucket', status: 'Enabled')

      expect(attrs.acceleration_enabled?).to be true
      expect(attrs.acceleration_suspended?).to be false
    end

    it 'creates valid acceleration suspended config' do
      attrs = attrs_class.new(bucket: 'my-bucket', status: 'Suspended')

      expect(attrs.acceleration_enabled?).to be false
      expect(attrs.acceleration_suspended?).to be true
    end

    it 'supports cross-account bucket owner' do
      attrs = attrs_class.new(
        bucket: 'my-bucket',
        status: 'Enabled',
        expected_bucket_owner: '123456789012'
      )

      expect(attrs.cross_account_bucket?).to be true
    end

    it 'detects non-cross-account bucket' do
      attrs = attrs_class.new(bucket: 'my-bucket', status: 'Enabled')

      expect(attrs.cross_account_bucket?).to be false
    end
  end

  describe 'validation' do
    it 'rejects invalid status' do
      expect {
        attrs_class.new(bucket: 'my-bucket', status: 'Invalid')
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid bucket name format' do
      expect {
        attrs_class.new(bucket: 'INVALID_BUCKET', status: 'Enabled')
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid expected_bucket_owner format' do
      expect {
        attrs_class.new(
          bucket: 'my-bucket',
          status: 'Enabled',
          expected_bucket_owner: 'not-an-account-id'
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
