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
require 'pangea/resources/aws_s3_bucket_inventory/resource'

RSpec.describe 'aws_s3_bucket_inventory synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic inventory configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_inventory(:basic, {
          bucket: 'source-bucket',
          name: 'weekly-inventory',
          destination: {
            bucket: 'arn:aws:s3:::inventory-dest',
            format: 'CSV'
          }
        })
      end

      result = synthesizer.synthesis
      inv = result['resource']['aws_s3_bucket_inventory']['basic']

      expect(inv['bucket']).to eq('source-bucket')
      expect(inv['name']).to eq('weekly-inventory')
    end

    it 'synthesizes inventory with optional fields' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_inventory(:detailed, {
          bucket: 'source-bucket',
          name: 'detailed-inventory',
          optional_fields: ['Size', 'LastModifiedDate', 'StorageClass'],
          destination: {
            bucket: 'arn:aws:s3:::inventory-dest',
            format: 'CSV'
          }
        })
      end

      result = synthesizer.synthesis
      inv = result['resource']['aws_s3_bucket_inventory']['detailed']

      expect(inv['bucket']).to eq('source-bucket')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_inventory(:test, {
          bucket: 'test-bucket',
          name: 'test-inventory',
          destination: {
            bucket: 'arn:aws:s3:::inventory-dest',
            format: 'CSV'
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_inventory.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_inventory.test.bucket}')
      expect(ref.outputs[:name]).to eq('${aws_s3_bucket_inventory.test.name}')
    end
  end

  describe 'validation' do
    it 'rejects day_of_week for Daily frequency' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketInventoryAttributes.new(
          bucket: 'test',
          name: 'test',
          frequency: 'Daily',
          destination: { bucket: 'arn:aws:s3:::dest', format: 'CSV' },
          schedule: { frequency: 'Daily', day_of_week: 'Monday' }
        )
      }.to raise_error(Dry::Struct::Error, /day_of_week cannot be specified/)
    end

    it 'rejects mismatched schedule and top-level frequency' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketInventoryAttributes.new(
          bucket: 'test',
          name: 'test',
          frequency: 'Daily',
          destination: { bucket: 'arn:aws:s3:::dest', format: 'CSV' },
          schedule: { frequency: 'Weekly' }
        )
      }.to raise_error(Dry::Struct::Error, /Schedule frequency must match/)
    end
  end
end
