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
require 'pangea/resources/aws_s3_multi_region_access_point/resource'

RSpec.describe 'aws_s3_multi_region_access_point synthesis' do
  let(:attrs_class) { Pangea::Resources::AWS::S3MultiRegionAccessPoint::S3MultiRegionAccessPointAttributes }

  describe 'type validation' do
    it 'creates valid multi-region access point' do
      attrs = attrs_class.new(
        details: {
          name: 'test-mrap',
          region: [
            { bucket: 'bucket-us', region: 'us-east-1' },
            { bucket: 'bucket-eu', region: 'eu-west-1' }
          ]
        }
      )

      expect(attrs.region_count).to eq(2)
      expect(attrs.bucket_names).to eq(['bucket-us', 'bucket-eu'])
      expect(attrs.access_point_name).to eq('test-mrap')
      expect(attrs.region_names).to eq(['us-east-1', 'eu-west-1'])
    end

    it 'detects cross-account buckets' do
      attrs = attrs_class.new(
        details: {
          name: 'test-mrap',
          region: [
            { bucket: 'bucket-1', region: 'us-east-1', bucket_account_id: '123456789012' },
            { bucket: 'bucket-2', region: 'eu-west-1' }
          ]
        }
      )

      expect(attrs.cross_account_buckets?).to be true
    end

    it 'detects public access block' do
      attrs = attrs_class.new(
        details: {
          name: 'test-mrap',
          public_access_block_configuration: {
            block_public_acls: true,
            block_public_policy: true
          },
          region: [
            { bucket: 'bucket-1', region: 'us-east-1' },
            { bucket: 'bucket-2', region: 'eu-west-1' }
          ]
        }
      )

      expect(attrs.has_public_access_block?).to be true
    end
  end

  describe 'validation' do
    it 'accepts valid multi-region access point configuration' do
      expect {
        attrs_class.new(
          details: {
            name: 'valid-mrap',
            region: [
              { bucket: 'bucket-1', region: 'us-east-1' },
              { bucket: 'bucket-2', region: 'eu-west-1' }
            ]
          }
        )
      }.not_to raise_error
    end

    it 'accepts optional account_id' do
      attrs = attrs_class.new(
        details: {
          name: 'test-mrap',
          region: [
            { bucket: 'bucket-1', region: 'us-east-1' },
            { bucket: 'bucket-2', region: 'eu-west-1' }
          ]
        },
        account_id: '123456789012'
      )

      expect(attrs.account_id).to eq('123456789012')
    end
  end
end
