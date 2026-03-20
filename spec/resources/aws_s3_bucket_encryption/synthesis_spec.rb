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
require 'pangea/resources/aws_s3_bucket_encryption/resource'

RSpec.describe 'aws_s3_bucket_encryption synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes AES256 encryption' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_encryption(:basic, {
          bucket: 'my-bucket',
          server_side_encryption_configuration: {
            rule: [
              {
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'AES256'
                }
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      enc = result['resource']['aws_s3_bucket_server_side_encryption_configuration']['basic']

      expect(enc['bucket']).to eq('my-bucket')
    end

    it 'synthesizes KMS encryption with key' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_encryption(:kms, {
          bucket: 'kms-bucket',
          server_side_encryption_configuration: {
            rule: [
              {
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'aws:kms',
                  kms_master_key_id: 'arn:aws:kms:us-east-1:123456789012:key/test'
                },
                bucket_key_enabled: true
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      enc = result['resource']['aws_s3_bucket_server_side_encryption_configuration']['kms']

      expect(enc['bucket']).to eq('kms-bucket')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_encryption(:test, {
          bucket: 'test-bucket',
          server_side_encryption_configuration: {
            rule: [
              {
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'AES256'
                }
              }
            ]
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_server_side_encryption_configuration.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_server_side_encryption_configuration.test.bucket}')
    end
  end

  describe 'validation' do
    it 'requires at least one encryption rule' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketEncryptionAttributes.new(
          bucket: 'test',
          server_side_encryption_configuration: { rule: [] }
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'requires kms_master_key_id when using aws:kms' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketEncryptionAttributes.new(
          bucket: 'test',
          server_side_encryption_configuration: {
            rule: [
              {
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'aws:kms'
                }
              }
            ]
          }
        )
      }.to raise_error(Dry::Struct::Error, /kms_master_key_id is required/)
    end

    it 'rejects kms_master_key_id with AES256' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketEncryptionAttributes.new(
          bucket: 'test',
          server_side_encryption_configuration: {
            rule: [
              {
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'AES256',
                  kms_master_key_id: 'arn:aws:kms:us-east-1:123456789012:key/test'
                }
              }
            ]
          }
        )
      }.to raise_error(Dry::Struct::Error, /kms_master_key_id should not be specified/)
    end

    it 'rejects invalid sse_algorithm' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketEncryptionAttributes.new(
          bucket: 'test',
          server_side_encryption_configuration: {
            rule: [
              {
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'INVALID'
                }
              }
            ]
          }
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
