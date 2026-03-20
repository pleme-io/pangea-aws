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
require 'pangea/resources/aws_s3_access_point/resource'

RSpec.describe 'aws_s3_access_point synthesis' do
  let(:attrs_class) { Pangea::Resources::AWS::S3AccessPoint::S3AccessPointAttributes }

  describe 'type validation' do
    it 'creates valid internet access point' do
      attrs = attrs_class.new(
        account_id: '123456789012',
        bucket: 'my-bucket',
        name: 'my-access-point'
      )

      expect(attrs.internet_access_point?).to be true
      expect(attrs.vpc_access_point?).to be false
    end

    it 'detects cross-account access' do
      attrs = attrs_class.new(
        account_id: '123456789012',
        bucket: 'my-bucket',
        name: 'my-ap',
        bucket_account_id: '987654321098'
      )

      expect(attrs.cross_account_access?).to be true
    end

    it 'detects public access block configuration' do
      attrs = attrs_class.new(
        account_id: '123456789012',
        bucket: 'my-bucket',
        name: 'my-ap',
        public_access_block_configuration: {
          block_public_acls: true,
          block_public_policy: true
        }
      )

      expect(attrs.has_public_access_block?).to be true
    end
  end

  describe 'validation' do
    it 'rejects invalid account_id format' do
      expect {
        attrs_class.new(
          account_id: 'invalid',
          bucket: 'my-bucket',
          name: 'my-ap'
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid access point name format' do
      expect {
        attrs_class.new(
          account_id: '123456789012',
          bucket: 'my-bucket',
          name: 'INVALID_NAME'
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
