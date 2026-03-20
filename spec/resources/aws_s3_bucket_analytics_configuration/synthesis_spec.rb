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
require 'pangea/resources/aws_s3_bucket_analytics_configuration/resource'

RSpec.describe 'aws_s3_bucket_analytics_configuration synthesis' do
  let(:attrs_class) { Pangea::Resources::AWS::S3BucketAnalyticsConfiguration::S3BucketAnalyticsConfigurationAttributes }

  describe 'type validation' do
    it 'creates valid analytics config' do
      attrs = attrs_class.new(bucket: 'my-bucket', name: 'my-analytics')

      expect(attrs.has_filter?).to be false
      expect(attrs.has_storage_class_analysis?).to be false
    end

    it 'creates analytics config with storage class analysis' do
      attrs = attrs_class.new(
        bucket: 'my-bucket',
        name: 'export-analytics',
        storage_class_analysis: {
          data_export: {
            output_schema_version: 'V_1',
            destination: {
              s3_bucket_destination: {
                bucket_arn: 'arn:aws:s3:::analytics-dest',
                format: 'CSV'
              }
            }
          }
        }
      )

      expect(attrs.exports_data?).to be true
      expect(attrs.export_bucket_arn).to eq('arn:aws:s3:::analytics-dest')
      expect(attrs.export_bucket_name).to eq('analytics-dest')
    end

    it 'detects cross-account export' do
      attrs = attrs_class.new(
        bucket: 'my-bucket',
        name: 'cross-account',
        storage_class_analysis: {
          data_export: {
            output_schema_version: 'V_1',
            destination: {
              s3_bucket_destination: {
                bucket_arn: 'arn:aws:s3:::analytics-dest',
                bucket_account_id: '123456789012',
                format: 'CSV'
              }
            }
          }
        }
      )

      expect(attrs.cross_account_export?).to be true
    end

    it 'creates analytics config with filter' do
      attrs = attrs_class.new(
        bucket: 'my-bucket',
        name: 'filtered',
        filter: { prefix: 'logs/' }
      )

      expect(attrs.has_filter?).to be true
      expect(attrs.filter_by_prefix?).to be_truthy
    end
  end

  describe 'validation' do
    it 'rejects invalid bucket name format' do
      expect {
        attrs_class.new(bucket: 'INVALID_BUCKET', name: 'analytics')
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid analytics name format' do
      expect {
        attrs_class.new(bucket: 'my-bucket', name: 'invalid name with spaces!')
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
