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
require 'pangea/resources/aws_dynamodb_table_export/resource'

RSpec.describe 'aws_dynamodb_table_export synthesis' do
  let(:attrs_class) { Pangea::Resources::AWS::DynamoDBTableExport::DynamoDBTableExportAttributes }
  let(:table_arn) { 'arn:aws:dynamodb:us-east-1:123456789012:table/my-table' }
  let(:s3_bucket_arn) { 'arn:aws:s3:::export-bucket' }

  describe 'type validation' do
    it 'creates valid export config' do
      attrs = attrs_class.new(table_arn: table_arn, s3_bucket: s3_bucket_arn)

      expect(attrs.table_name).to eq('my-table')
      expect(attrs.bucket_name).to eq('export-bucket')
      expect(attrs.full_export?).to be true
      expect(attrs.incremental_export?).to be false
    end

    it 'supports ION format' do
      attrs = attrs_class.new(
        table_arn: table_arn,
        s3_bucket: s3_bucket_arn,
        export_format: 'ION'
      )

      expect(attrs.export_format).to eq('ION')
    end

    it 'supports incremental export' do
      attrs = attrs_class.new(
        table_arn: table_arn,
        s3_bucket: s3_bucket_arn,
        export_type: 'INCREMENTAL_EXPORT'
      )

      expect(attrs.incremental_export?).to be true
      expect(attrs.full_export?).to be false
    end

    it 'detects KMS encryption' do
      attrs = attrs_class.new(
        table_arn: table_arn,
        s3_bucket: s3_bucket_arn,
        s3_sse_algorithm: 'KMS',
        s3_sse_kms_key_id: 'arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012'
      )

      expect(attrs.uses_kms_encryption?).to be true
      expect(attrs.uses_aes_encryption?).to be false
    end

    it 'detects cross-account bucket' do
      attrs = attrs_class.new(
        table_arn: table_arn,
        s3_bucket: s3_bucket_arn,
        s3_bucket_owner: '987654321098'
      )

      expect(attrs.cross_account_bucket?).to be true
    end
  end

  describe 'validation' do
    it 'rejects invalid table ARN format' do
      expect {
        attrs_class.new(table_arn: 'invalid-arn', s3_bucket: s3_bucket_arn)
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid S3 bucket ARN format' do
      expect {
        attrs_class.new(table_arn: table_arn, s3_bucket: 'invalid-bucket')
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid export format' do
      expect {
        attrs_class.new(
          table_arn: table_arn,
          s3_bucket: s3_bucket_arn,
          export_format: 'INVALID'
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
