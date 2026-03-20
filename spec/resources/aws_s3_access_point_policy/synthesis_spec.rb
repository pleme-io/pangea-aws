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
require 'pangea/resources/aws_s3_access_point_policy/resource'

RSpec.describe 'aws_s3_access_point_policy synthesis' do
  let(:attrs_class) { Pangea::Resources::AWS::S3AccessPointPolicy::S3AccessPointPolicyAttributes }
  let(:valid_arn) { 'arn:aws:s3:us-east-1:123456789012:accesspoint/my-ap' }
  let(:valid_policy) do
    {
      Version: '2012-10-17',
      Statement: [
        {
          Effect: 'Allow',
          Principal: { AWS: 'arn:aws:iam::123456789012:root' },
          Action: 's3:GetObject',
          Resource: "#{valid_arn}/object/*"
        }
      ]
    }.to_json
  end

  describe 'type validation' do
    it 'creates valid access point policy' do
      attrs = attrs_class.new(
        access_point_arn: valid_arn,
        policy: valid_policy
      )

      expect(attrs.has_valid_json?).to be true
      expect(attrs.access_point_name).to eq('my-ap')
      expect(attrs.account_id).to eq('123456789012')
      expect(attrs.region).to eq('us-east-1')
    end

    it 'parses policy document' do
      attrs = attrs_class.new(
        access_point_arn: valid_arn,
        policy: valid_policy
      )

      expect(attrs.policy_document).to be_a(Hash)
      expect(attrs.policy_document['Version']).to eq('2012-10-17')
    end
  end

  describe 'validation' do
    it 'rejects invalid access point ARN format' do
      expect {
        attrs_class.new(
          access_point_arn: 'invalid-arn',
          policy: valid_policy
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
